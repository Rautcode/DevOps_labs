# 11 · Capstone: production readiness (Expert, ~10h+)

> **Guided version:** run `bash lab.sh 11` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** combine everything into one defensible, production-grade delivery, then prove it.

## Part A · Disaster recovery drill (verified)
SQLite holds your leads. Backups that were never restored are not backups.
```bash
bash 11-capstone/backup.sh                                   # online, consistent (VACUUM INTO), safe while serving
bash 11-capstone/restore.sh backups/<file>.sqlite        # stop api -> replace db -> start api
```
The drill: create data → back up → destroy the data → restore → confirm the data is back (this exact sequence passed during lab development). Record **RPO** (how much data you can lose = time since last backup) and **RTO** (how long recovery took).

Industry upgrades: schedule backups (cron / Kubernetes `CronJob`), ship them off-host (S3 with versioning: reuse module 05), encrypt them, alert if the newest backup is older than N hours, and consider **Litestream** for continuous replication.

## Part B · Ship a release end to end
1. Make a real change: add a `GET /version` endpoint to `app/api/server.js` with a test, and make sure `scan.sh` still passes ([09](../09-security/README.md)).
2. Merge via PR with all CI checks green ([04](../04-ci-cd/README.md)).
3. Tag `v1.0.0`: images are built, signed and pushed.
4. Point the prod overlay at the new tag, merge: Argo CD deploys ([07](../07-gitops/README.md)).
5. Watch the SLO dashboard during the rollout ([08](../08-observability/README.md)). Roll back with `git revert`.

## Part C · Production readiness review: score yourself
| Area | Question | Where |
|---|---|---|
| Build | Reproducible, minimal, non-root images? | 02 |
| Delivery | Every change reviewed, tested, scanned, signed? | 04, 09 |
| Infra | All cloud resources in code, with tests and drift detection? | 05 |
| Runtime | Probes, limits, PDB, HPA, NetworkPolicy, PSA? | 06 |
| Deploy | Pull-based GitOps, rollback by revert? | 07 |
| Monitor | SLOs, burn-rate alerts, runbook per alert? | 08, 10 |
| Security | Secrets managed, CVE gate, least privilege? | 09 |
| Data | Backups restored in a drill, RPO/RTO known? | 11 |
| People | On-call, postmortems, game days? | 10 |

## Part D · DORA metrics: measure delivery performance
| Metric | How to compute from this repo |
|---|---|
| Deployment frequency | releases (tags) per week: `git tag --sort=-creatordate` |
| Lead time for changes | PR merged → running in prod |
| Change failure rate | releases needing rollback / total |
| Time to restore | from your game-day postmortems |

## Stretch goals (pick one per week)
- Progressive delivery: Argo Rollouts canary with automatic rollback on SLO burn.
- Real cloud: deploy to a managed cluster (EKS / AKS / GKE) with Terraform; set budgets and alarms *before* anything else.
- Postgres (RDS / CloudNativePG) replacing SQLite so the API can scale horizontally.
- Secrets: External Secrets Operator + a cloud secret manager.
- Platform engineering: a Backstage portal or a golden-path template repo others can copy.
- FinOps: tag-based cost reports and a monthly cost review.
- Chaos engineering: automate [game day](../10-sre/gameday.md) scenarios with Chaos Mesh / Litmus.

You have finished when you can **explain every line of this lab and defend each trade-off**.

**Next:** the specialist tracks, starting with [12 · Networking](../12-networking/README.md) (`bash lab.sh 12`).
