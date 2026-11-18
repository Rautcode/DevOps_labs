# DevOps and Cloud Lab

![CI](https://github.com/Rautcode/DevOps_labs/actions/workflows/ci.yml/badge.svg)
![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?logo=grafana&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?logo=argo&logoColor=white)
![Level](https://img.shields.io/badge/level-beginner%20to%20expert-brightgreen)

A personal, hands-on path from **zero to production-grade** DevOps and cloud skills. You ship, break, fix and operate one small but realistic application (a Node API with SQLite behind an nginx web page). Everything runs **locally and free** with Docker. Real-cloud steps are optional and clearly marked.

> Learn by doing: each module has a goal, exact commands, a **Check** that proves it worked, a **Break it** section, and industry notes. The findings and fixes in the READMEs came from actually running this lab (see [what was verified](#what-was-verified)).

## What you will operate
```mermaid
flowchart LR
  U([You / browser]) -->|:8080| W["web: nginx<br/>static page + reverse proxy"]
  W -->|/api, /healthz, /readyz| A["api: Node + Express<br/>auth, rate limit, JSON logs"]
  A --> D[("SQLite on a volume<br/>or Postgres (module 16)")]
  P["Prometheus + Grafana<br/>probes and SLO alerts"] -.->|checks| W
```

## Your journey
```mermaid
flowchart LR
  subgraph Beginner
    G0[00 Git from zero] --> F[01 Foundations] --> C[02 Containers] --> M[03 Compose]
  end
  subgraph Intermediate
    CI[04 CI/CD] --> T[05 Terraform] --> K[06 Kubernetes]
  end
  subgraph Advanced
    G[07 GitOps] --> O[08 Observability] --> S[09 Security] --> R[10 SRE]
  end
  subgraph Expert
    X[11 Capstone]
  end
  subgraph Specialist["Specialist tracks"]
    N[12 Networking] --> AN[13 Ansible] --> H[14 Helm and RBAC] --> L[15 Logging and tracing] --> PG[16 Postgres] --> AW[17 Real cloud: AWS]
  end
  subgraph Extra["Job-ready extras"]
    LX[18 Linux admin] --- GC[19 Git collaboration] --- SE[20 Secrets] --- KA[21 Kubernetes advanced] --- SH[22 Ship it for real] --- IV[23 Interview prep]
  end
  M --> CI
  K --> G
  R --> X
  X --> N
  F --> LX
  G0 --> GC
  X --> SH
```

## Learning path

| Level | # | Module | You learn | Time |
|---|---|---|---|---|
| **Beginner** | [00](00-git/README.md) | **Git from zero (start here)** | save, undo, branch, merge, .gitignore, GitHub, in tiny steps | 1.5h |
| | [01](01-foundations/README.md) | Foundations | Linux, HTTP, shell, debugging by layers *(after 00)* | 3h |
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
| **Specialist** | [12](12-networking/README.md) | Networking | IP addressing and CIDR, DNS, ports, TLS certificates, load balancing and failover | 2h |
| | [13](13-ansible/README.md) | Ansible | configuration management, idempotence, drift repair | 2h |
| | [14](14-helm/README.md) | Helm and RBAC | chart install/upgrade/rollback, least-privilege access | 2.5h |
| | [15](15-logging/README.md) | Logging and tracing | Loki + Alloy, LogQL, Jaeger traces | 2h |
| | [16](16-postgres/README.md) | Postgres | real database, scaling the API, pg_dump backup | 2h |
| | [17](17-aws/README.md) | Real cloud (AWS) | budget alarms, cloud security scanning, safe real-account apply | 2h |
| **Job-ready extras** | [18](18-linux/README.md) | Linux administration | users, permissions, processes, disk, cron, systemd, SSH keys *(unlocks after 01)* | 3h |
| | [19](19-git/README.md) | Git collaboration | conflicts, rebase, reflog recovery, bisect, code review *(after 00)* | 2.5h |
| | [20](20-secrets/README.md) | Secrets management | HashiCorp Vault, policies, rotation, revocation *(after 03)* | 2h |
| | [21](21-k8s-advanced/README.md) | Kubernetes advanced | Jobs, ConfigMaps, OOMKilled, autoscaling, ingress, troubleshooting ImagePullBackOff and Pending pods *(after 06)* | 3h |
| | [22](22-ship/README.md) | Ship it for real | a LIVE GitHub pipeline, PRs, releases, real cloud deploy code *(after 11)* | 3h |
| | [23](23-interview/README.md) | Interview prep | spoken rounds, system design, STAR story, mock interview *(after 11)* | 3h |

Follow it in order; the lab moves on to the next lesson automatically. Start with module **00** (Git from zero). The core path is 00-11, the **specialist tracks** 12-17 go deeper, and the **job-ready extras** 18-23 add what employers ask about most (some unlock early: see the table). Finish with [JOB-READY.md](JOB-READY.md). Do not skip **Break it**: operating skill comes from failures. Tick modules off as you finish them and keep notes on what broke.

## Start here: guided mode (easiest)
**Windows: just double-click `lab.cmd`.** It checks Docker and opens the lab in its own Git Bash window.

The lab teaches you **inside your terminal**. It explains each step, has you type the commands yourself, gives you hands-on tasks and **checks your work**.
```bash
export MSYS_NO_PATHCONV=1     # Windows Git Bash only, once per terminal
bash doctor.sh                # checks your machine (Docker, kubectl, memory)
bash lab.sh                   # menu: pick a lesson number (start with 00)
bash lab.sh 00                # or start module 00 directly (it continues by itself)
bash lab.sh map               # your roadmap and XP
```
Every module opens with a **mission** (the story: why you are learning this) and follows the same path. **The next module stays locked until you pass this one**:
```mermaid
flowchart LR
  L["LEARN a little<br/>(short note)"] --> D["DO it<br/>(you type)"] --> L2["LEARN<br/>next idea"] --> D2["DO it"] --> I["INTERVIEW<br/>hands-on questions"] --> F["MODULE FINAL<br/>exam, no step-by-step"] --> U(["Next module unlocks"])
```
- **LEARN**: a short teaching note (plain words, a few sentences). Read it, press Enter.
- **STEP** (do): the lab shows a command, **you type it** at the `▸` prompt. It runs it, shows the output, and tells you what to look for. A different command still runs (explore!) but only the right one completes the step. `?` = hint, `run` = let the lab type it for you, `skip`, `shortcuts`, `quit`.
- **YOUR TURN** (do): a hands-on task at a `lab ▸` prompt right in the lab (no second window): type commands, `edit FILE` opens nano, then `check`.
- **QUIZ**: a question in your own words, then the model answer.
- **QUICK CHECK / PREDICT**: a one-key multiple-choice question. Guess what a command will do *before* you run it, then see if you were right (+5 XP).
- **GO DEEPER**: at the end of most modules, optional links to public learning repos (Abhishek Veeramalla, Shubham Londhe, StackSimplify) for the same skill on a different project. See [STUDY-GUIDE.md](STUDY-GUIDE.md) for exactly what to read where, and [RESOURCES.md](RESOURCES.md).
- **DIAGRAMS**: framed pictures (images and containers, the GitOps loop, TLS, RBAC, scaling...) so you see the idea before you type.
- **INTERVIEW**: after the lessons the lab becomes an interviewer. It sets up a real situation (a broken site, a bad commit, a crash loop) and asks you to **show** the fix. No step-by-step help, hints only.
- **MODULE FINAL**: an exam of 3 hands-on challenges for the whole module. You get the objective, not the commands. Every item is checked against the real result, and all must pass to unlock the next module.

**XP and levels:** every step, task and correct answer earns XP (150 XP per level), and a trophy appears when you finish a module. `bash lab.sh map` shows your whole roadmap at a glance.

Menu symbols: `✔` module complete, `◐` lessons done but interview/final pending, `🔒` locked until the previous module is passed.
Failed an exam item? Retake only the exam with `bash lab.sh final 05` (change 05 to the module number).

Prefer to just watch? `LAB_MODE=watch bash lab.sh 01` runs the commands for you (press Enter at each step).

What it looks like in your terminal:
```text
 STEP 3/22  Build the API image
  Type this command (type it or copy it, then press Enter):
    ❯ docker build -f 02-containers/Dockerfile.api -t devlab-api:lab app/api
  ▸ docker build -f 02-containers/Dockerfile.api -t devlab-api:lab app/api
  │ ... Successfully built ...
   ✔ DONE
  ➜ Look for: The last lines say the image was built.

 YOUR TURN 9/22  Build an image from your own Dockerfile
  Type your commands right here. Type  check  when you are done.
  lab ▸ edit playground/Dockerfile.hello
  lab ▸ check
   ✔ PASS

  Overall  ████████░░░░░░░░░░░░░░░░  4/24 modules   Rank: DevOps Engineer   XP 640 (level 5)
```
You earn a rank as you go: Newcomer, Junior Operator, DevOps Engineer, Platform Engineer, Senior Engineer, SRE Legend.

Other commands: `bash lab.sh status` (your progress), `bash lab.sh final NN` (retake a module exam), `bash lab.sh next` (resume), `bash lab.sh down` (stop everything the labs started), `bash lab.sh reset`.
Your own files go in `playground/` (git-ignored). The written guides in each module folder have the same content plus background reading.

Requires Docker Desktop (give it 6GB+ RAM), `kubectl`, Git, Node 24+. Terraform, kind and helm are **optional**: wrapper scripts run them in Docker.

## Quick start without the guide (10 minutes)
```bash
C="docker compose -f 03-compose/docker-compose.yml --env-file .env"
$C up --build -d                         # builds both images and starts the site
curl localhost:8080/healthz              # {"ok":true}   (site: http://localhost:8080)
$C down                                  # stop (data volume is kept)
```

## Map
```
lab.sh  lessons/   guided runner and one lesson script per module (bash lab.sh 01 ...)
playground/        your own files from the hands-on tasks (git-ignored)
app/api/   sample API: Express, SQLite or Postgres, health + readiness, auth, rate limit, JSON logs, tests   (npm test)
app/web/   sample static site with a form that calls the API
00-git/ 01-foundations/ 02-containers/ 03-compose/ 04-ci-cd/ 05-terraform/ 06-kubernetes/
07-gitops/ 08-observability/ 09-security/ 10-sre/ 11-capstone/
12-networking/ 13-ansible/ 14-helm/ 15-logging/ 16-postgres/ 17-aws/      (specialist tracks)
18-linux/ 19-git/ 20-secrets/ 21-k8s-advanced/ 22-ship/ 23-interview/      (job-ready extras)
finals/NN.sh       the interview + module final of each module
.github/           the LIVE CI pipeline, Dependabot, feedback template
JOB-READY.md  STUDY-GUIDE.md
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

## Known simplifications: what production would do differently
This is a learning lab, so some choices are deliberately simple. Knowing them is part of the lesson: say them out loud in an interview.
| In the lab | In production |
|---|---|
| One tiny app with SQLite (modules 01-15) | a managed database and several copies of the API (module 16 shows the step) |
| The API's token is a small HMAC-signed value, not a standard JWT | a vetted library (for example `jose`), real JWT claims, key rotation |
| Secrets in `.env.example`, the dev overlay and Helm values (public on purpose) | a secret manager (module 20) and External Secrets or Sealed Secrets |
| A Deployment has `replicas:` and an HPA | when an HPA owns the count, leave `replicas` out of the manifest, otherwise each apply resets it |
| NetworkPolicies restrict **ingress** only | add **egress** policies (and allow DNS) so a compromised pod cannot call out anywhere |
| Base images use moving tags (`node:24-slim`, `nginx stable-alpine`) | pin by digest and rebuild on a schedule with Dependabot |
| Grafana runs with anonymous admin; Prometheus and Alloy are exposed on your computer | authentication, TLS, private networks; Alloy mounts the Docker socket, which is powerful |
| Vault in dev mode with a known root token | real storage, unsealing, TLS, auth methods, audit logs |
| LocalStack pinned to 4.12 (the last tokenless image) | a real account, or a maintained emulator |
| No TLS on the Kubernetes ingress | cert-manager with automatically renewed certificates |
| One environment on one computer | separate accounts per environment, approval gates, staged rollouts |

A review of this lab also found and fixed real bugs: the home page was missing its security headers because of how nginx handles `add_header`, the rate limiter never forgot old clients, pods mounted a service-account token they did not need, the CI pipeline pinned actions by tag while lesson 22 taught SHAs, and a third-party action tag vanished. Reviews catch what tests do not.

## What was verified
Run on Docker Desktop (Windows) while building this repo, **every lesson was executed end to end in an automatic mode that performs each hands-on task and checks the result**. The interviews and finals (5 items per module, 115 in total) were run the same way: the lab sets up the scenario (it breaks things on purpose), applies a reference solution, and the real check must pass.
- **01-03:** API tests, compose stack, nginx proxy, persistence, overrides, Git exercise.
- **04-05:** workflows pass `actionlint`; Terraform fmt/validate/**2 tests**; real apply, drift heal and destroy on LocalStack.
- **06-07:** Kustomize + schema validation; a **real k3s cluster** (self-healing with data kept, rolling restart, NetworkPolicy block, the SQLite scaling mistake).
- **08-11:** Prometheus probes and alert rules, a real alert firing, five security scanners, a game day, a **backup, destroy, restore** drill.
- **12-17:** DNS, TLS 1.3, a load balancer with failover; Ansible idempotence and drift repair; Helm install/upgrade/rollback and RBAC; Loki logs and a Jaeger trace; Postgres with 3 API copies and a `pg_dump` restore; AWS Terraform validate and Checkov.
- **18 Linux administration:** a real Debian server: permissions, processes, disk, cron, systemd units, SSH keys, sudo.
- **19 Git collaboration:** conflicts, rebase, reflog recovery, `git bisect run`, a review exercise.
- **20 Secrets:** a real Vault server: policies, tokens, rotation, deploying the API with secrets from Vault, revocation.
- **21 Kubernetes advanced:** a cluster with metrics-server and Traefik: Jobs, CronJobs, ConfigMaps, a real OOMKill, a real autoscale-up, an Ingress route.
- **22 Ship it for real:** the **CI pipeline runs on GitHub for every push and all four jobs pass** (its first run failed on a real, now-fixed problem). The cloud-deploy Terraform passes validate and Checkov (32 checks).
- **23 Interview prep:** 31 scored questions, a system-design document, a STAR story and a live-troubleshooting mock interview.

**Not run by the lab author (needs you):** applying to a real AWS account (modules 17 and 22 are validated and scanned, and the apply steps are optional with safety rules), the optional pull-request and release tasks on your own repository, Argo CD and Kyverno installs, and testing with real learners. Tell us how it goes: `bash lab.sh feedback`.

See [RESOURCES.md](RESOURCES.md) for the research behind this curriculum, and [JOB-READY.md](JOB-READY.md) for turning the lab into interviews.

## License
MIT: see [LICENSE](LICENSE). Use it, copy it, teach with it. Third-party tools and images used by the lab keep their own licenses.
