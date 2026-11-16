# 16 · Postgres (Specialist, ~2h)

> **Guided version:** run `bash lab.sh 16` from the repo root. It explains each step, runs it for you, and checks your hands-on tasks. This page is the reference.

**Goal:** replace the SQLite file with a real database server, and see why that lets the API run as many copies.

| File | What it is |
|---|---|
| [compose.postgres.yml](compose.postgres.yml) | adds Postgres and sets `DATABASE_URL` on the API |

The API ([app/api/server.js](../app/api/server.js)) has one small data interface with two backends: **SQLite** (default) or **Postgres** (when `DATABASE_URL` is set). It also exposes two probes:
- `/healthz` (**liveness**): the process is alive.
- `/readyz` (**readiness**): the database is reachable and the instance can serve traffic. It reports `store` (sqlite or postgres) and `instance` (which copy answered).

## Try it (from the repo root)
```bash
DCP="docker compose -f 03-compose/docker-compose.yml -f 16-postgres/compose.postgres.yml --env-file .env"
$DCP up -d --build
curl -s localhost:8080/readyz                                   # "store":"postgres"
$DCP up -d --scale api=3 --no-recreate                          # three API copies, ONE database
$DCP exec -T postgres psql -U devlab -d devlab -c "select count(*) from leads"
$DCP exec -T postgres pg_dump -U devlab -d devlab --clean --if-exists > backups/pg.sql     # backup
$DCP down; $DC up -d                                            # back to SQLite
```

## Concepts
- **Stateless app + stateful database**: state lives in one place, so app copies are interchangeable. That is what lets you scale, replace and roll out freely (compare with the SQLite scaling mistake in module 06).
- **Startup resilience:** the API retries the database connection for about 30 s instead of crashing if Postgres is still starting.
- **Backups:** `pg_dump` for logical backups; for production use continuous archiving (WAL) and **test restores**.
- **Migrations:** schema changes should be versioned (Flyway, Liquibase, Prisma, node-pg-migrate). This lab creates the table at startup for simplicity.

## Break it
1. Stop `postgres` while the API runs: what does `/readyz` return (503), what does `/healthz` return (still 200), and why does that matter for Kubernetes?
2. Wrong password in `DATABASE_URL`: read the API's startup error.
3. Scale to 3 copies and hit the rate-limited login endpoint: the limiter is per instance. How would you fix that? (Shared store such as Redis.)

## Industry notes
- Prefer a **managed** database (RDS, Cloud SQL, Azure Database) with automated backups and failover. Run your own only when you must.
- Keep credentials in a secret manager; the compose default password is lab-only.
- Use `readinessProbe` → `/readyz` and `livenessProbe` → `/healthz` in Kubernetes (module 06) so a database outage stops traffic without restarting healthy pods.

**Next:** [17 · Real cloud (AWS)](../17-aws/README.md)
