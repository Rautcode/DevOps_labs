# Module 23 · interview and final (sourced by lab.sh): the mock interview
part "PART · LIVE TROUBLESHOOTING (hands-on)"

interview "Live debugging: the site is down" "Interviewer: 'It is 3 a.m. and the on-call phone rings: the website at http://localhost:8080 is not answering. Debug it live. When it is back, write one sentence into playground/rca.txt that says what was wrong (it must name the part that failed).'" "Is something else already using port 8080? Look at docker ps. Only one program can own a port. Stop the squatter, then start the stack with dc up -d." <<'X'
dc down >/dev/null 2>&1; docker rm -f port-squatter >/dev/null 2>&1; docker run -d --name port-squatter -p 8080:80 nginx:alpine >/dev/null 2>&1; sleep 2; rm -f playground/rca.txt
---
curl -s localhost:8080/healthz | grep -q '"ok":true' && ! docker ps -a --format '{{.Names}}' | grep -q port-squatter && grep -qiE 'port|8080|squat|nginx|conflict|already' playground/rca.txt
---
docker rm -f port-squatter >/dev/null 2>&1; dc up -d >/dev/null 2>&1; sleep 16; echo "Port 8080 was already taken by another container (nginx), so the web container could not start." > playground/rca.txt
X

interview "Live debugging: it keeps restarting" "Interviewer: 'A deploy went out and now the API container keeps restarting. Find the reason in the logs, fix it, and prove the site is healthy. Save the exact log line that explains the failure into playground/why.txt.'" "dc logs api shows a FATAL line. The bad setting came from the override file playground/bad.yml. Start the stack again without it." <<'X'
dc up -d >/dev/null 2>&1; sleep 10; printf 'services:\n  api:\n    environment:\n      JWT_SECRET: short\n' > playground/bad.yml; docker compose -f 03-compose/docker-compose.yml -f playground/bad.yml --env-file .env up -d >/dev/null 2>&1; sleep 14; rm -f playground/why.txt
---
grep -q FATAL playground/why.txt && curl -s localhost:8080/healthz | grep -q '"ok":true'
---
dc logs api --tail 10 --no-log-prefix 2>&1 | grep FATAL | head -1 > playground/why.txt; dc up -d >/dev/null 2>&1; sleep 18
---
rm -f playground/bad.yml
X

part "PART · MODULE FINAL"

final "Design on paper: monitoring and incident response" "Exam 1 of 3. Interviewer: 'Our service has no monitoring. Design how we detect and handle problems.' Write playground/design-sre.md. It must cover at least five of: an SLO or SLI, alerts (symptom based), a dashboard, an on-call rota, a runbook, a postmortem, and the error budget." "Think: what do users feel (SLI), what target (SLO), who gets paged, what do they read (runbook), what do we learn afterwards (postmortem)." <<'X'
rm -f playground/design-sre.md
---
f=playground/design-sre.md; [ -f $f ] || exit 1; n=0; for p in 'slo|sli' 'alert' 'dashboard' 'on-call|on call|rota' 'runbook' 'postmortem' 'error budget'; do grep -qiE "$p" $f && n=$((n+1)); done; [ $n -ge 5 ]
---
printf '# Monitoring and incident response\nDefine an SLI (the share of successful health checks) and an SLO of 99.5%% over 30 days.\nAlert on symptoms using burn-rate alerts so we only page when users are affected.\nShow a Grafana dashboard with availability and latency.\nKeep an on-call rota with a primary and a backup.\nEvery alert links a runbook with triage steps.\nAfter every incident we write a blameless postmortem with action items.\nWe track the error budget: when it is spent we pause feature work.\n' > playground/design-sre.md
X

final "Your incident story" "Exam 2 of 3. Interviewer: 'Tell me about a time something went wrong and what you did.' Write playground/story.md using Situation, Task, Action and Result headings with at least 60 words in total. Use a real moment from this lab, for example the crash loop you just debugged." "Say what YOU did step by step in Action, and give a number in Result (minutes, percent)." <<'X'
rm -f playground/story.md
---
f=playground/story.md; [ -f $f ] && for h in Situation Task Action Result; do grep -qi "^#.*$h\|^\*\*$h\|^$h" $f || exit 1; done; [ "$(wc -w < $f | tr -d ' ')" -ge 60 ]
---
printf '# Situation\nAn API container kept restarting right after a deployment, and the website returned errors.\n# Task\nAs the engineer on call I had to find the root cause and restore service.\n# Action\nI read the container logs, found a FATAL message saying the secret was too short, saw it came from a bad override file, started the stack again without it, and checked the health endpoint.\n# Result\nService was back in about five minutes. I then added a configuration check to the pipeline so the same mistake is caught before deployment.\n' > playground/story.md
X

# ---- the spoken round: 10 questions, you need 8 ----
qa "Explain what idempotent means for a deployment or configuration tool." 'same|again|twice|repeat|no change|safe|nothing' "Running it once or many times gives the same final state. If the system is already correct, nothing changes, so you can re-run it safely."
qa "What is a reverse proxy and why use one?" 'front|forward|route|tls|load|hide|single|entry' "A server in front of your applications that receives requests and forwards them to the right backend. It gives one entry point for TLS, routing, caching, load balancing and hides the internal servers."
qa "How do you roll back a bad release in a GitOps setup?" 'revert|git|previous|commit|argo|sync' "Revert the commit (or merge a fix) in git. The GitOps controller sees the change and syncs the cluster back. Git history is the audit trail."
qa "Why alert on symptoms such as error rate instead of causes such as CPU?" 'user|symptom|noise|fatigue|impact|matter|cause' "Symptom alerts fire when users are affected, so every page matters. Cause alerts (CPU high) fire often with no user impact and create alert fatigue."
qa "What is the difference between a Docker volume and a bind mount?" 'managed|docker|host|path|portable|directory|persist' "A volume is storage managed by Docker (independent of the host layout, portable, preferred for data). A bind mount maps a specific host path into the container."
qa "How would you debug a 502 Bad Gateway from a reverse proxy?" 'upstream|backend|app|logs|down|health|connect|proxy' "A 502 means the proxy is up but the upstream is not answering correctly. Check that the backend is running and healthy, its logs, the upstream address or DNS, and the network path between them."
qa "Explain RPO and RTO." 'data|loss|time|restore|recover|how (much|long)' "RPO (recovery point objective) is how much data you can afford to lose, measured as time since the last backup. RTO (recovery time objective) is how long it may take to be running again."
qa "What does a Kubernetes NetworkPolicy do?" 'traffic|allow|deny|pod|ingress|egress|firewall|isolat' "It controls which pods may talk to which, like a firewall inside the cluster. With default-deny plus explicit allow rules a compromised pod cannot reach everything else."
qa "When would you rebase and when would you merge?" 'private|local|unpublished|history|linear|shared|rewrite|public' "Rebase your own unpublished branch to get a clean linear history. Merge when the branch is shared or public, because rebasing rewrites commits and would break other people's copies."
qa "You start on call next week. What do you prepare in your first days?" 'runbook|alert|access|dashboard|escalat|shadow|practice|learn|contact' "Get access to systems, read the runbooks and recent postmortems, learn the dashboards and alerts, know who to escalate to, shadow an experienced on-call engineer, and practise the common fixes."
qa_need 8
