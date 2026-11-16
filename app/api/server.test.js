'use strict';
// Run: npm test   (uses Node's built-in test runner; no extra dependencies)
process.env.DATA_DIR = require('node:fs').mkdtempSync(require('node:path').join(require('node:os').tmpdir(), 'lab-'));
process.env.JWT_SECRET = 'test-secret-test-secret-test-secret-123';
process.env.ADMIN_PASSWORD = 'test-admin-password';

const test = require('node:test');
const assert = require('node:assert/strict');
const app = require('./server');

let server, base;
test.before(async () => {
  await app.ready;
  await new Promise((resolve) => { server = app.listen(0, () => { base = `http://127.0.0.1:${server.address().port}`; resolve(); }); });
});
test.after(() => server.close());

const post = (p, body, headers = {}) => fetch(base + p, { method: 'POST', headers: { 'content-type': 'application/json', ...headers }, body: JSON.stringify(body) });

test('health endpoint', async () => {
  const r = await fetch(base + '/healthz');
  assert.equal(r.status, 200);
  assert.deepEqual(await r.json(), { ok: true });
});

test('readiness endpoint reports the data store', async () => {
  const r = await fetch(base + '/readyz');
  assert.equal(r.status, 200);
  const body = await r.json();
  assert.equal(body.ready, true);
  assert.ok(['sqlite', 'postgres'].includes(body.store));
});

test('admin routes reject anonymous requests', async () => {
  assert.equal((await fetch(base + '/api/auth/me')).status, 401);
  assert.equal((await fetch(base + '/api/inquiries')).status, 401);
});

test('login, then read leads created by the public form', async () => {
  assert.equal((await post('/api/auth/login', { username: 'admin', password: 'wrong' })).status, 401);
  const { token } = await (await post('/api/auth/login', { username: 'admin', password: 'test-admin-password' })).json();
  assert.ok(token);

  assert.equal((await post('/api/inquiries', { name: 'Asha', email: 'not-an-email' })).status, 400);
  assert.equal((await post('/api/inquiries', { name: 'Asha', email: 'asha@example.com', message: 'hi' })).status, 201);

  const leads = await (await fetch(base + '/api/inquiries', { headers: { authorization: `Bearer ${token}` } })).json();
  assert.equal(leads[0].email, 'asha@example.com');
});

test('login is rate limited', async () => {
  let last;
  for (let i = 0; i < 12; i++) last = (await post('/api/auth/login', {})).status;
  assert.equal(last, 429);
});
