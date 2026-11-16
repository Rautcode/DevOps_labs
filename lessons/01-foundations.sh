# Foundations: Linux, HTTP, Git, shell (about 1.5h)
title "Module 01 · Foundations"
explain "You will look inside a running app, talk to it over HTTP, use Git safely, and write a small script. Everything runs on a practice app on your own computer. Read each step, press Enter to run it, and read the output. Nothing here can harm your computer."

part "PART A · Start the practice app"
step "Start the app (first time takes about a minute)" "Containers show Started / Healthy" <<'CMD'
$DC up --build -d 2>&1 | tail -4
CMD
step "Check it is alive" '{"ok":true}' <<'CMD'
sleep 10; curl -s localhost:8080/healthz
CMD

part "PART B · Linux: look inside the container"
explain "A container is a tiny, isolated Linux system. We use 'docker exec' to run one command inside it. WINDOWS TIP: in your own Git Bash terminal run   export MSYS_NO_PATHCONV=1   (once per terminal). Without it Git Bash rewrites paths like /data into C:/Program Files/Git/data and Docker commands fail."
step "1. Who is the app running as?" "uid=1000(node). A normal user, NOT root. If hacked, the attacker has less power." <<'CMD'
docker exec devlab-api-1 id
CMD
step "2. What is the very first process?" "docker-init ... node server.js. A tiny helper starts first, then the app." <<'CMD'
docker exec devlab-api-1 cat /proc/1/cmdline | tr '\0' ' '; echo
CMD
step "3. Where do the settings come from?" "DATA_DIR=/data and NODE_ENV=production. Apps read settings from environment variables." <<'CMD'
docker exec devlab-api-1 sh -c 'env | grep -E "DATA_DIR|NODE_ENV"'
CMD
step "4. Where is the data stored?" "database.sqlite owned by node. It lives on a separate volume, so it survives restarts." <<'CMD'
docker exec devlab-api-1 ls -la /data
CMD
step "5. How much disk space is there?" "Size and usage of the data volume." <<'CMD'
docker exec devlab-api-1 df -h /data
CMD
step "6. Can the app install software?" "An error about 'are you root?'. It fails ON PURPOSE: a normal user cannot install tools, and neither can an attacker." fail <<'CMD'
docker exec devlab-api-1 apt-get install -y curl
CMD
quiz "Why is it safer that the app is not an administrator?" "attack|hack|power|privile|root|damage|limit" "If the app is compromised, the attacker only gets a normal user's powers and cannot install tools or change the system."
quiz "Why does the data survive when the app restarts?" "volume|disk|outside|separate|mount|persist" "The database lives on a volume that is separate from the container, so replacing the container keeps the data."

part "PART C · HTTP: talk to the API"
explain "HTTP is how browsers and apps talk. Every answer starts with a status code: 200 = OK, 401 = who are you?, 429 = slow down, 502 = the server behind the proxy is down."
step "7. Read a full HTTP response" "First line 'HTTP/1.1 200 OK', then headers, then the body." <<'CMD'
curl -i -s localhost:8080/healthz
CMD
step "8. Just the status code and speed" "status=200 and a time in seconds" <<'CMD'
curl -s -w '\nstatus=%{http_code} time=%{time_total}s\n' localhost:8080/ | tail -1
CMD
step "9. Ask for a protected page without logging in" "401. 'Unauthorized' means: not logged in." <<'CMD'
curl -s -w '\nstatus=%{http_code}\n' localhost:8080/api/auth/me | tail -1
CMD
step "10. Send data: create a lead" 'A reply like {"id":1}. You just wrote to the database.' <<'CMD'
curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"Asha\",\"email\":\"asha@example.com\",\"message\":\"hello\"}"; echo
CMD
step "11. Send bad data" "400 and an error message. Good APIs reject bad input." <<'CMD'
curl -s -i -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"\",\"email\":\"nope\"}" | head -1
CMD
step "12. Rate limiting: send 12 login attempts fast" "A row of 401 then 429. After 10 tries in a minute the server says 'too many requests'. This stops password guessing." <<'CMD'
for i in $(seq 1 12); do curl -s -w ' <%{http_code}>' -X POST localhost:8080/api/auth/login -H "content-type: application/json" -d "{}" | grep -o '<[0-9]*>' | tr -d '\n'; done; echo
CMD
quiz "What is the difference between 401 and 403?" "401.*(login|auth|who)|(not|no).*(logged|auth)|403.*(forbid|not allowed|permission)" "401 = I do not know who you are (log in). 403 = I know who you are, but you are not allowed."

part "PART D · Git: work safely"
explain "Git records every change so you can undo mistakes. We practise on a throwaway branch."
task "Make a branch, commit, and undo it safely" "In ANOTHER terminal (Git Bash) go to D:/devops-cloud-lab and run these 5 commands one by one: git switch -c lab/practice ; echo hello > practice.txt ; git add practice.txt ; git commit -m 'feat: practice' ; git revert --no-edit HEAD . Then come back here." "You need to be on branch lab/practice and the latest commit message must start with Revert." <<'X'
[ "$(git branch --show-current)" = "lab/practice" ] && git log -1 --pretty=%s | grep -q '^Revert'
---
git switch -c lab/practice && echo hello > practice.txt && git add practice.txt && git commit -q -m 'feat: practice' && git revert --no-edit HEAD
X
step "See your history (revert keeps history, it does not erase it)" "A 'Revert' commit on top of 'feat: practice'. The file is gone again, but the history remembers." <<'CMD'
git log --oneline -3
CMD
step "git reflog: the safety net" "Every move you made is listed. Almost nothing in Git is truly lost." <<'CMD'
git reflog -5
CMD
step "Clean up the practice branch" "You are back on main." <<'CMD'
git switch main && git branch -D lab/practice
CMD

part "PART E · Shell scripting"
explain "A script is a saved list of commands. Good scripts stop on errors and tell you what happened."
task "Write a health-wait script" "Create the file playground/healthwait.sh. It must: poll http://localhost:8080/healthz every 2 seconds, exit 0 as soon as it answers, and exit 1 after 60 seconds. Hints: 'set -euo pipefail', a for loop, 'curl -fsS', 'sleep 2'." "Use: for i in \$(seq 1 30); do curl -fsS URL >/dev/null 2>&1 && exit 0; sleep 2; done; exit 1" <<'X'
[ -f playground/healthwait.sh ] && bash playground/healthwait.sh
---
printf '%s\n' '#!/usr/bin/env bash' 'for i in $(seq 1 30); do' '  curl -fsS http://localhost:8080/healthz >/dev/null 2>&1 && exit 0' '  sleep 2' 'done' 'exit 1' > playground/healthwait.sh
X

part "PART F · Break it, then fix it"
explain "Operating skill comes from failures. Stop the API and see how it looks from the outside."
step "Stop the API" "The container stops." <<'CMD'
docker stop devlab-api-1
CMD
step "Ask the site for its health" "502 Bad Gateway: the proxy (web) is alive but the thing behind it (api) is down. You can now tell WHICH layer failed." <<'CMD'
curl -s -i localhost:8080/healthz | head -1
CMD
step "Start the API again and wait until it is healthy" '{"ok":true}' <<'CMD'
docker start devlab-api-1 >/dev/null; sleep 12; curl -s localhost:8080/healthz
CMD
quiz "In one sentence: what does a 502 tell you?" "proxy|gateway|backend|behind|upstream|api.*down|down" "The front door (proxy) works but the service behind it is down or unreachable."

explain "Done! Next: bash lab.sh 02"
