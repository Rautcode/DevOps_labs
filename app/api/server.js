'use strict';
// Tiny sample API used as the practice target for the lab.
// It deliberately has the traits that make real services interesting to operate:
// config from env, fail-fast validation, health + readiness endpoints, state (SQLite by default,
// Postgres when DATABASE_URL is set), rate limiting, auth, and graceful shutdown.
const express = require('express');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const PORT = process.env.PORT || 5000;
const DATA_DIR = process.env.DATA_DIR || __dirname;
const JWT_SECRET = process.env.JWT_SECRET || '';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';

// Fail fast: a service that starts with a weak secret is worse than one that refuses to start.
if (process.env.NODE_ENV === 'production' && JWT_SECRET.length < 32) {
  console.error('FATAL: JWT_SECRET must be set (32+ chars) in production.');
  process.exit(1);
}

// ---- data layer: one small interface, two backends ----
function makeStore() {
  if (process.env.DATABASE_URL) {
    const { Pool } = require('pg');
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    return {
      kind: 'postgres',
      init: async () => {
        // The database may still be starting: retry for up to ~30s instead of crashing (resilience).
        for (let i = 0; ; i++) {
          try {
            await pool.query(`CREATE TABLE IF NOT EXISTS leads (
              id SERIAL PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL, message TEXT,
              created_at TIMESTAMPTZ DEFAULT now())`);
            return;
          } catch (e) { if (i >= 15) throw e; await new Promise((r) => setTimeout(r, 2000)); }
        }
      },
      add: async (name, email, message) =>
        (await pool.query('INSERT INTO leads (name, email, message) VALUES ($1, $2, $3) RETURNING id', [name, email, message])).rows[0].id,
      list: async () => (await pool.query('SELECT * FROM leads ORDER BY id DESC LIMIT 100')).rows,
      ping: () => pool.query('SELECT 1'),
      close: () => pool.end(),
    };
  }
  const { DatabaseSync } = require('node:sqlite');
  fs.mkdirSync(DATA_DIR, { recursive: true });
  const db = new DatabaseSync(path.join(DATA_DIR, 'database.sqlite'));
  db.exec(`PRAGMA journal_mode = WAL;
    CREATE TABLE IF NOT EXISTS leads (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL, email TEXT NOT NULL, message TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP)`);
  return {
    kind: 'sqlite',
    init: async () => {},
    add: async (name, email, message) =>
      Number(db.prepare('INSERT INTO leads (name, email, message) VALUES (?, ?, ?)').run(name, email, message).lastInsertRowid),
    list: async () => db.prepare('SELECT * FROM leads ORDER BY id DESC LIMIT 100').all(),
    ping: async () => db.prepare('SELECT 1').get(),
    close: async () => db.close(),
  };
}
const store = makeStore();

const sign = (payload) => {
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const mac = crypto.createHmac('sha256', JWT_SECRET).update(body).digest('base64url');
  return `${body}.${mac}`;
};
const verify = (token = '') => {
  const [body, mac] = token.split('.');
  if (!body || !mac) return null;
  const good = crypto.createHmac('sha256', JWT_SECRET).update(body).digest('base64url');
  const a = Buffer.from(mac), b = Buffer.from(good);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  const data = JSON.parse(Buffer.from(body, 'base64url').toString());
  return data.exp > Date.now() ? data : null;
};

// Minimal in-memory rate limiter (per client IP). ponytail: per instance only; use Redis when scaling out.
const hits = new Map();
const limit = (max, windowMs) => (req, res, next) => {
  const key = `${req.path}:${req.ip}`, now = Date.now();
  const recent = (hits.get(key) || []).filter((t) => now - t < windowMs);
  recent.push(now);
  hits.set(key, recent);
  if (recent.length > max) return res.status(429).json({ error: 'too many requests' });
  next();
};

const requireAdmin = (req, res, next) => {
  const token = (req.get('authorization') || '').replace(/^Bearer /, '');
  const who = JWT_SECRET && verify(token);
  if (!who) return res.status(401).json({ error: 'unauthorized' });
  req.admin = who;
  next();
};

const app = express();
// Behind a proxy the client IP is in X-Forwarded-For; trust exactly N hops, never blindly.
if (process.env.TRUST_PROXY) app.set('trust proxy', Number(process.env.TRUST_PROXY));
app.disable('x-powered-by');
app.use(express.json({ limit: '10kb' }));
// Structured access log: one JSON line per request, so a log system (module 15) can search and count them.
// Probes hit /healthz every few seconds, so they are left out to keep the logs readable.
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    if (req.path !== '/healthz') console.log(JSON.stringify({ level: 'info', method: req.method, path: req.path, status: res.statusCode, ms: Date.now() - start }));
  });
  next();
});

// Liveness: "the process is up". Readiness: "I can serve traffic" (database reachable).
app.get('/healthz', (req, res) => res.json({ ok: true }));
app.get('/readyz', async (req, res) => {
  try { await store.ping(); res.json({ ready: true, store: store.kind, instance: process.env.HOSTNAME || 'local' }); }
  catch { res.status(503).json({ ready: false, store: store.kind }); }
});
app.get('/api/form-token', (req, res) => res.json({ token: crypto.randomBytes(16).toString('hex') }));

app.post('/api/auth/login', limit(10, 60_000), (req, res) => {
  const { username, password } = req.body || {};
  const a = Buffer.from(String(password || '')), b = Buffer.from(ADMIN_PASSWORD);
  const ok = username === 'admin' && ADMIN_PASSWORD && a.length === b.length && crypto.timingSafeEqual(a, b);
  if (!ok) return res.status(401).json({ error: 'invalid credentials' });
  res.json({ token: sign({ username: 'admin', exp: Date.now() + 8 * 3600_000 }) });
});
app.get('/api/auth/me', requireAdmin, (req, res) => res.json({ username: req.admin.username }));

app.post('/api/inquiries', limit(20, 60_000), async (req, res) => {
  const { name, email, message = '' } = req.body || {};
  if (!name || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email || '')) return res.status(400).json({ error: 'name and valid email required' });
  const id = await store.add(String(name).slice(0, 200), email, String(message).slice(0, 2000));
  res.status(201).json({ id });
});
app.get('/api/inquiries', requireAdmin, async (req, res) => res.json(await store.list()));

// Last resort: log the error as JSON and return a generic message (never leak internals to clients).
app.use((err, req, res, next) => { // eslint-disable-line no-unused-vars
  console.error(JSON.stringify({ level: 'error', msg: err.message, path: req.path }));
  res.status(500).json({ error: 'internal error' });
});

module.exports = app;
app.ready = store.init();

if (require.main === module) {
  app.ready.then(() => {
    const server = app.listen(PORT, () => console.log(JSON.stringify({ level: 'info', msg: `API listening on :${PORT}`, store: store.kind })));
    // Graceful shutdown: finish in-flight requests, close the DB, then exit (what Kubernetes sends on SIGTERM).
    for (const sig of ['SIGTERM', 'SIGINT']) {
      process.on(sig, () => server.close(async () => { await store.close(); process.exit(0); }));
    }
  }).catch((e) => { console.error(JSON.stringify({ level: 'fatal', msg: e.message })); process.exit(1); });
}
