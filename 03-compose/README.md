# 03 · Multi-container stack with Compose (Beginner, ~3h)

> **Guided version:** run `bash lab.sh 03` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** run web + API together, with persistence, health-gated startup and a hardened runtime.

## Do it (from the repo root)
```bash
cp .env.example .env                                  # lab-only secrets (git-ignored)
C="docker compose -f 03-compose/docker-compose.yml --env-file .env"
$C up --build -d
$C ps                                                         # both healthy
curl localhost:8080/healthz                                      # then browse http://localhost:8080
$C logs -f api                                                # Ctrl-C to stop following
```
**Check:** the site loads at http://localhost:8080 and `/healthz` returns `{"ok":true}` through the proxy.

## Read the compose file: every line is a lesson
| Setting | Why |
|---|---|
| `${JWT_SECRET:?...}` | refuse to start without a secret instead of running insecurely |
| `depends_on: condition: service_healthy` | web starts only after the API is *ready*, not just started |
| `volumes: api-data:/data` | database and uploads survive container deletion |
| `init: true` | correct PID 1: signals forwarded, zombies reaped |
| `read_only: true` + `tmpfs` | web container cannot be tampered with on disk |
| `cap_drop: [ALL]`, `no-new-privileges` | least privilege |
| `deploy.resources.limits` | one runaway container cannot starve the host |
| `networks: backend` | api is **not** published to the host; only web is reachable |

## Persistence experiment
```bash
$C down            # containers removed ...
$C up -d           # ... data is still there (volume)
$C down -v         # -v deletes the volume: NOW the data is gone. Know the difference.
```

## Break it
- Delete `.env` and run `up`. Read the error message you wrote.
- `docker stop devlab-api-1` and refresh the site: what do you see? Then `docker start devlab-api-1`: recovery without touching web (runtime DNS resolution).
- Add `ports: ["5000:5000"]` to api. You just exposed an internal service: why is that bad?

## Industry notes
- Compose is for dev/test and small single-host setups. Production on multiple hosts means an orchestrator (module 06).
- Keep one compose file per concern and layer them with `-f` (module 08 adds monitoring this way).

**Next:** [04 · CI/CD](../04-ci-cd/README.md)
