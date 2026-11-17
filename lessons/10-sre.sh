# SRE: SLOs, incidents, runbooks and postmortems (about 2h)
title "Module 10 · SRE and incident response"
explain "Site Reliability Engineering treats reliability as a number you can measure and budget. You will read the SLO, cause a real incident, handle it with a runbook, and write a blameless postmortem."

part "PART A · The SLO and the error budget"
learn "SLI, SLO and error budget" "An SLI is a number you measure (the share of successful health checks). An SLO is the target for it (99.5% over 30 days). The error budget is the failure you are ALLOWED: 100% minus the SLO. While budget remains you can ship features; when it is gone you fix reliability first."
step "Read the service level objective" "99.5% availability over 30 days." <<'CMD'
sed -n 1,12p 10-sre/slo.md
CMD
step "Do the math: how much downtime does 99.5% allow in 30 days?" "216 minutes (3.6 hours). That is your ERROR BUDGET: the downtime you can 'spend' before breaking the promise." <<'CMD'
awk 'BEGIN{printf "%.0f minutes (%.1f hours)\n", 30*24*60*0.005, 30*24*0.005}'
CMD
quiz "If the SLO were 99.9% instead, roughly how many minutes per 30 days? (hint: 0.1%)" "43|44|0\.7" "30 x 24 x 60 x 0.001 = about 43 minutes. Each extra nine costs much more to deliver."

part "PART B · Game day: cause an incident"
learn "Game days" "A game day is a planned practice failure in a safe place. You measure how long detection takes, follow the runbook, and then fix whatever was unclear. Teams that practise fail less badly when the real incident comes."
step "Start the monitoring tools" "prometheus, grafana, blackbox running." <<'CMD'
dco up -d 2>&1 | tail -3; sleep 30
CMD
step "INJECT the failure: stop the API" "The container stops. You are now 'on call'." <<'CMD'
docker stop devlab-api-1
CMD
step "Wait for the alert (up to 3 minutes)" "ALERT is pending or firing. In real life this would page you." <<'CMD'
for i in $(seq 1 36); do curl -s localhost:9090/api/v1/alerts | grep -q EndpointDown && { echo "ALERT: EndpointDown is active"; break; }; sleep 5; done
CMD
step "Follow the RUNBOOK, step 1: triage" "502 from the proxy = web is up and api is down (runbook step 2)." <<'CMD'
curl -s -i localhost:8080/healthz | head -1; docker inspect devlab-api-1 --format 'api state: {{.State.Status}}'
CMD
step "Runbook step 2: read the API logs" "Last log lines of the stopped container. For a crash these would show the reason." <<'CMD'
dc logs api --tail 3
CMD
step "MITIGATE: start the API" '{"ok":true}' <<'CMD'
docker start devlab-api-1 >/dev/null; sleep 12; curl -s localhost:8080/healthz
CMD
quiz "In the runbook, a 502 from the proxy means what?" "api|backend|down|behind|upstream" "The proxy (web) is alive but the API behind it is down, so go to the 'API down' steps."

part "PART C · Hands-on: write the postmortem"
learn "Blameless postmortems" "After an incident you write what happened: summary, impact, timeline, root cause and action items with owners. Blameless means you look for the weakness in the system or process, not for a person to blame. People who fear blame hide problems."
task "Write a blameless postmortem for your game day" "Create playground/postmortem.md with these five headings (use # for each): Summary, Impact, Timeline, Root cause, Action items. Under each, write a sentence or two about what you just did (for example: Root cause: the API container was stopped on purpose for a game day). Use the template in 10-sre/postmortem-template.md." "The check looks for all five headings in the file." <<'X'
f=playground/postmortem.md; [ -f $f ] && for h in Summary Impact Timeline "Root cause" "Action items"; do grep -qi "^#.*$h" $f || exit 1; done
---
printf '# Summary\nGame day: API stopped on purpose.\n# Impact\nSite returned 502 for about 3 minutes.\n# Timeline\nStopped API, alert fired, started API.\n# Root cause\nThe API container was stopped intentionally.\n# Action items\nShorten alert time; add a second runbook check.\n' > playground/postmortem.md
X
quiz "In a BLAMELESS postmortem, who do we blame?" "no one|nobody|noone|system|process|not a person|nothing" "No person. People acted sensibly with the information they had; we fix the system, process or alert that allowed the problem."

step "Tidy up: stop the monitoring tools" "Stopped." <<'CMD'
dco rm -sf prometheus grafana blackbox 2>&1 | tail -3
CMD

explain "Done! Next: bash lab.sh 11"
