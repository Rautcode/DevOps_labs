# Module 01 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Triage a broken site" "Interviewer: 'Customers say the website is broken. Before you restart anything, tell me what the health endpoint (http://localhost:8080/healthz) returns RIGHT NOW. Save only the HTTP status code, nothing else, into the file playground/code.txt. From that number, which layer is at fault?'" "curl can print just the status code with  -w '%{http_code}'  . A 502 means the web proxy is fine but the service behind it is not." <<'X'
dc up -d >/dev/null 2>&1; sleep 12; docker stop devlab-api-1 >/dev/null 2>&1; rm -f playground/code.txt
---
[ "$(tr -d '[:space:]' < playground/code.txt 2>/dev/null)" = "502" ]
---
curl -s -w '\n%{http_code}' localhost:8080/healthz | tail -1 > playground/code.txt
X

interview "Restore the service" "Interviewer: 'Good: a 502 means the API behind the proxy is down. Now bring the service back and prove it is healthy again.'" "The API container was stopped. Find it with  docker ps -a  and start it." <<'X'
true
---
curl -s localhost:8080/healthz | grep -q '"ok":true'
---
docker start devlab-api-1 >/dev/null 2>&1; sleep 14
X

interview "Undo a bad commit safely" "Interviewer: 'A teammate committed a bad change on the branch lab/exam (you are already on it). Undo it WITHOUT rewriting history, so everyone who already pulled it is safe. The file exam-bad.txt must disappear but the history must remember it.'" "git revert creates a new commit that undoes an old one. Use  git revert --no-edit HEAD  ." <<'X'
git switch -q -c lab/exam >/dev/null 2>&1; echo bad > exam-bad.txt; git add exam-bad.txt; git commit -q -m "oops: bad change"
---
[ "$(git branch --show-current)" = "lab/exam" ] && git log -1 --pretty=%s | grep -q '^Revert' && [ ! -e exam-bad.txt ]
---
git revert --no-edit HEAD >/dev/null 2>&1
---
git switch -q main >/dev/null 2>&1; git branch -q -D lab/exam >/dev/null 2>&1; rm -f exam-bad.txt
X

part "PART · MODULE FINAL"

final "Cold start" "Exam 1 of 3. The whole stack has been shut down (docker compose down). Bring the practice app back up from nothing and prove the site answers on http://localhost:8080/healthz." "Remember the shortcut  dc  = docker compose for this lab. Wait about 15 seconds for the containers to become healthy." <<'X'
dc down >/dev/null 2>&1
---
curl -s localhost:8080/healthz | grep -q '"ok":true'
---
dc up -d >/dev/null 2>&1; sleep 16
X

final "Write data through the API" "Exam 2 of 3. Create a lead (a record) through the public API with the email final@example.com. The check looks directly inside the database." "POST to /api/inquiries with JSON containing name and email. Example from lesson 01, step 10." <<'X'
true
---
[ "$(leadsfor final@example.com)" -ge 1 ]
---
curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"Final Exam","email":"final@example.com"}' >/dev/null
X

final "A script that tells the truth" "Exam 3 of 3. Write playground/check-site.sh. It must exit 0 when http://localhost:8080/healthz is healthy and exit NON-zero when it is not. The check runs it twice: once with the site up, once with the API stopped." "curl -f makes curl fail (non-zero exit) on an HTTP error. Remember  curl -fsS URL >/dev/null 2>&1  and that the last command's exit code becomes the script's." <<'X'
rm -f playground/check-site.sh
---
[ -f playground/check-site.sh ] && bash playground/check-site.sh >/dev/null 2>&1 && { docker stop devlab-api-1 >/dev/null 2>&1; sleep 2; ! bash playground/check-site.sh >/dev/null 2>&1; r=$?; docker start devlab-api-1 >/dev/null 2>&1; sleep 14; exit $r; }
---
printf '%s\n' '#!/usr/bin/env bash' 'curl -fsS http://localhost:8080/healthz >/dev/null 2>&1' > playground/check-site.sh
X
