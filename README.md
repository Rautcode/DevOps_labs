# DevOps and Cloud Lab

A personal, hands-on path from **zero to production-grade** DevOps and cloud skills. You ship, break, fix and operate one small but realistic application (a Node API with SQLite behind an nginx web page). Everything runs **locally and free** with Docker. Real-cloud steps are optional and clearly marked.

> Learn by doing: each module has a goal, exact commands, a **Check** that proves it worked, a **Break it** section, and industry notes. The findings and fixes in the READMEs came from actually running this lab (see [what was verified](#what-was-verified)).

## Learning path

| Level | # | Module | You learn | Time |
|---|---|---|---|---|
| **Beginner** | [01](01-foundations/README.md) | Foundations | Linux, HTTP, Git, shell | 3h |
| | [02](02-containers/README.md) | Containers | secure images, nginx reverse proxy | 4h |
| | [03](03-compose/README.md) | Compose | multi-service stack, volumes, health, hardening | 3h |
| **Intermediate** | [04](04-ci-cd/README.md) | CI/CD | GitHub Actions, scanning, signed releases | 4h |
| | [05](05-terraform/README.md) | Infrastructure as Code | Terraform modules, tests, AWS APIs (free emulator) | 5h |
| | [06](06-kubernetes/README.md) | Kubernetes | probes, limits, HPA, StatefulSet, NetworkPolicy | 8h |
| **Advanced** | [07](07-gitops/README.md) | GitOps | Argo CD, drift, rollback by revert | 4h |
| | [08](08-observability/README.md) | Observability | Prometheus, Grafana, SLO burn-rate alerts | 4h |
| | [09](09-security/README.md) | DevSecOps | shift-left scanning, admission policy, supply chain | 4h |
| | [10](10-sre/README.md) | SRE | SLOs, runbooks, game days, postmortems | 4h |
| **Expert** | [11](11-capstone/README.md) | Capstone | DR drill, release end to end, DORA, readiness review | 10h+ |

Follow it in order. Do not skip **Break it**: operating skill comes from failures. Tick modules off as you finish them and keep notes on what broke.

## Quick start (10 minutes)
```bash
bash doctor.sh                           # checks Docker, kubectl, memory; creates .env
C="docker compose -f 03-compose/docker-compose.yml --env-file .env"
$C up --build -d                         # builds both images and starts the site
curl localhost:8080/healthz              # {"ok":true}   (site: http://localhost:8080)
$C down                                  # stop (data volume is kept)
```
Requires Docker Desktop (give it 6GB+ RAM), `kubectl`, Git, Node 24+. Terraform, kind and helm are **optional**: wrapper scripts run them in Docker.

## Map
```
app/api/   sample API: Express + SQLite, health, auth, rate limit, tests   (npm test)
app/web/   sample static site with a form that calls the API
01-foundations/ 02-containers/ 03-compose/ 04-ci-cd/ 05-terraform/ 06-kubernetes/
07-gitops/ 08-observability/ 09-security/ 10-sre/ 11-capstone/
doctor.sh  .env.example  RESOURCES.md
```
Change the app freely (add endpoints, break it, swap SQLite for Postgres): it exists to be operated.

## Rules of the lab
1. **Predict, then run.** Write what you expect before each command.
2. **Break something every module** and fix it from logs, not from the answer.
3. **Never reuse lab secrets** (`.env.example`, the dev overlay). They are public on purpose.
4. **Read every plan / diff** before applying.
5. Clean up: `docker compose ... down -v`, `bash 06-kubernetes/cluster.sh down`, `docker system prune`.

## Troubleshooting
| Symptom | Fix |
|---|---|
| `docker: failed to connect to the docker API` | start Docker Desktop, wait for "Engine running" |
| `required variable JWT_SECRET is missing` | `cp .env.example .env` (or run `doctor.sh`) |
| Port 8080/9090/3000/30080 in use | stop the other process or change the host port |
| `/data` permission errors | volume created by an older image: `docker compose ... down -v` |
| Git Bash mangles `/paths` in `docker run` | prefix with `MSYS_NO_PATHCONV=1` (scripts already do) |
| Containers crash after sleep / low RAM | raise Docker memory, `docker compose ... up -d` |

## What was verified
Run on Docker Desktop (Windows) while building this repo: API tests, compose stack, nginx proxy, Prometheus probes + 7 alert rules (`promtool`), Grafana provisioning, Terraform fmt/validate/**2 tests** and a real apply/destroy on LocalStack, Kustomize rendering + schema validation + **deployment to a real k3s cluster** (pods, PVC, NodePort, NetworkPolicy block, zero-downtime rollout), both GitHub workflows (`actionlint`), hadolint, Trivy, Checkov, gitleaks, and a **backup → destroy → restore** drill.
**Not run:** the GitHub Actions workflows on GitHub itself, Argo CD install/sync, Kyverno install, and anything on a real cloud account.

See [RESOURCES.md](RESOURCES.md) for the research behind this curriculum and where to go next.
