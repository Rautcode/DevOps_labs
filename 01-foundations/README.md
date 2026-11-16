# 01 · Foundations (Beginner, ~3h)

**Goal:** be comfortable in a Linux shell, Git and HTTP before touching any tooling. Everything is done against the small sample app in [app/](../app) (a Node API with SQLite behind an nginx-served web page).

**You are done when** you can explain what a process, port and environment variable are, what common HTTP status codes mean, and how to undo a bad commit.

## Setup
```bash
bash doctor.sh        # checks your machine
```

## Lab 1 · Linux and processes (inside a container)
Start the stack from module 03 first, then:
```bash
docker exec -it devlab-api-1 bash
ps aux                              # which process is PID 1? (node: we used `init: true`, see module 03)
id                                  # you are NOT root. Why does that matter?
env | grep -E 'DATA_DIR|NODE_ENV'   # config lives in environment variables (12-factor app)
ls -la /data ; df -h /data          # who owns the database? how full is the disk?
```
**Check yourself:** why can't you `apt install` anything in there? (Non-root user. By design.)

## Lab 2 · HTTP and the API
```bash
curl -i localhost:8080/healthz                                   # status line, headers, body
curl -s -o /dev/null -w '%{http_code} %{time_total}s\n' localhost:8080/
curl -i localhost:8080/api/auth/me                               # 401. How is it different from 403?
for i in $(seq 1 12); do curl -s -o /dev/null -w '%{http_code} ' -X POST localhost:8080/api/auth/login -H 'content-type: application/json' -d '{}'; done
```
The last loop shows **rate limiting** (you will see 429s). Behind a proxy the server needs `TRUST_PROXY` to see real client IPs: that variable exists for exactly this reason.

## Lab 3 · Git like a professional
```bash
git switch -c practice
git log --oneline --graph -10
git commit --allow-empty -m "feat: practice commit"   # Conventional Commits: feat / fix / docs / chore
git revert HEAD                                       # safe undo, history preserved
git reflog                                            # the safety net: almost nothing is truly lost
git switch main && git branch -D practice
```
Industry rules: small PRs, branch from `main`, never force-push shared branches, never commit secrets (module 09 enforces this with gitleaks).

## Lab 4 · Shell scripting essentials
Read [doctor.sh](../doctor.sh) line by line. Then write `healthwait.sh`: poll `/healthz` every 2s, exit 0 when healthy, exit 1 after 60s. Use `set -euo pipefail`, `until`, `curl -fsS`.

## Break it
Run `docker stop devlab-api-1`, then `curl -i localhost:8080/healthz`. Which layer failed: DNS, TCP, proxy or app? (`502` means the proxy is up and the backend is down.)

## Industry notes
- Config comes from environment variables; secrets are never baked into images or git.
- Anything you do by hand twice should become a script, then a pipeline.
- Learn to read logs first: `docker logs`, later `kubectl logs`.

**Next:** [02 · Containers](../02-containers/README.md)
