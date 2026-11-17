# 01 · Foundations (Beginner, ~3h)

> **Guided version:** run `bash lab.sh 01` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** be comfortable in a Linux shell, Git and HTTP before touching any tooling. Everything is done against the small sample app in [app/](../app) (a Node API with SQLite behind an nginx-served web page).

**You are done when** you can explain what a process, port and environment variable are, what common HTTP status codes mean, and how to undo a bad commit.

## Setup
```bash
bash doctor.sh        # checks your machine
```

## Lab 1 · Look inside the running app (~30 min)

**Goal:** see how the app runs inside its container. Run each command in Git Bash, **one at a time**, and read the answer.

**Before you start**, check the app is running:
```bash
curl localhost:8080/healthz
```
You should see `{"ok":true}`. If not, start it from the repo root:
```bash
docker compose -f 03-compose/docker-compose.yml --env-file .env up -d
```

### Step 1 · Who is the app running as?
```bash
docker exec devlab-api-1 id
```
You will see `uid=1000(node)`.
**Meaning:** the app runs as a normal user, not an administrator. If it is hacked, the attacker has less power.

### Step 2 · What is the first process?
```bash
docker exec devlab-api-1 sh -c 'cat /proc/1/cmdline | tr "\0" " "; echo'
```
You will see `/sbin/docker-init -- docker-entrypoint.sh node server.js`.
**Meaning:** a tiny helper program starts first (`init: true` in the compose file) and then runs the app.

### Step 3 · Where do the settings come from?
```bash
docker exec devlab-api-1 sh -c 'env | grep -E "DATA_DIR|NODE_ENV"'
```
You will see `DATA_DIR=/data` and `NODE_ENV=production`.
**Meaning:** apps read settings from environment variables, so the same code runs on any machine (the "12-factor app" rule).

### Step 4 · Where is the data stored?
```bash
docker exec devlab-api-1 ls -la /data
```
You will see a file called `database.sqlite`, owned by `node`.
**Meaning:** this is the app's database. It sits on a separate volume, so it survives restarts.

### Step 5 · How much disk space is there?
```bash
docker exec devlab-api-1 df -h /data
```
**Meaning:** shows the size and usage of that data volume.

### Step 6 · Can the app install software?
```bash
docker exec devlab-api-1 apt-get install -y curl
```
You will see an error mentioning `dpkg frontend lock ... are you root?`.
**Meaning:** the failure is on purpose. A normal user cannot install programs, so neither can an attacker.

### Check yourself
Answer in your own words:
1. Why is it safer that the app is not an administrator?
2. Why does the data survive when the app restarts?

> Optional interactive shell: on Windows Git Bash use `winpty docker exec -it devlab-api-1 sh` (or PowerShell). Type `exit` to leave. The image is minimal, so `ps` is not installed; read `/proc` instead.

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
echo hello > practice.txt && git add practice.txt     # a revert needs a real change to undo
git commit -m "feat: practice commit"                 # Conventional Commits: feat / fix / docs / chore
git revert --no-edit HEAD                             # safe undo, history preserved
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
