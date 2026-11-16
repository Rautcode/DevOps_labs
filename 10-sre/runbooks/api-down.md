# Runbook: EndpointDown / ErrorBudgetFastBurn

**Impact:** visitors cannot load pages or submit leads. **Severity:** page.

## 1. Triage (2 min)
```bash
curl -i localhost:8080/healthz
docker compose -f 03-compose/docker-compose.yml --env-file .env ps
```
| Symptom | Meaning | Go to |
|---|---|---|
| `502` from the proxy | web is up, **api** is down | step 2 |
| connection refused | **web** is down | `docker compose ... up -d web` |
| `200` but slow | saturation | step 4 |

## 2. API down
```bash
docker compose -f 03-compose/docker-compose.yml --env-file .env logs api --tail 50
```
- `FATAL: JWT_SECRET must be set` → bad config. Fix `.env`, then `up -d api`.
- `unable to open database file` → volume permissions (`/data` must be owned by uid 1000).
- Database corrupt or data missing → **restore**: `bash 11-capstone/restore.sh backups/<latest>`.
- OOMKilled (`docker inspect devlab-api-1 --format '{{.State.OOMKilled}}'`) → raise the memory limit.

## 3. Kubernetes variant
```bash
kubectl -n devlab-dev get pods
kubectl -n devlab-dev describe pod devlab-api-0
kubectl -n devlab-dev logs devlab-api-0 --prdevlabus
```
`Pending` → PVC or node capacity. `CrashLoopBackOff` → read the `--prdevlabus` logs. `ImagePullBackOff` → tag or registry.

## 4. Slow
Check CPU and memory throttling, and 429s from the rate limiter. Scale `devlab-web` (stateless) but **never** `devlab-api` (SQLite is a single writer).

## 5. After
Post a status update, then write a postmortem within 48h ([template](../postmortem-template.md)).
