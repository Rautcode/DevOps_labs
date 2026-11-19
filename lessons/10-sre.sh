# SRE: SLOs, incidents, runbooks and postmortems (about 2h)
title "Module 10 · SRE and incident response"
mission "It is 3am and the site is down. A good team has a number for reliability (the SLO), a runbook that tells the on-call person what to do, and a calm, blameless review afterwards. Your mission: cause a real incident and handle it properly."
explain "Site Reliability Engineering treats reliability as a number you can measure and budget. You will read the SLO, cause a real incident, handle it with a runbook, and write a blameless postmortem."

part "PART A · The SLO and the error budget"
learn "SLI, SLO and error budget" "An SLI is a number you measure (the share of successful health checks). An SLO is the target for it (99.5% over 30 days). The error budget is the failure you are ALLOWED: 100% minus the SLO. While budget remains you can ship features; when it is gone you fix reliability first."
say "Explain SLI, SLO and error budget." "An SLI is a measured number, like the percentage of successful requests. An SLO is the target I promise, like 99.9 percent over thirty days. The error budget is what is left over, the allowed failure, here about 43 minutes a month. If the budget is healthy we ship features; if it is burning, we slow down and fix reliability."
art "SLO and error budget" <<'ART'
   SLI = what you measure         e.g. 99.95% of requests succeed
   SLO = the promise              e.g. 99.9% over 30 days
   error budget = 100% - SLO      0.1% of requests may fail
   budget left   -> ship features
   budget gone   -> freeze changes, fix reliability
ART
mcq "If the SLO is 99.9%, what is the error budget?" "0.1%|99.9%|1%|10%" 1 "100% minus 99.9% = 0.1% of requests (about 43 minutes a month) are allowed to fail."
why "sed -n 1,12p::print lines 1 to 12 of the file" "The SLO is the promise to users, written as a number. Reading it first tells you what reliability the team agreed to, and so how much failure is acceptable."
step "Read the service level objective" "99.5% availability over 30 days." <<'CMD'
sed -n 1,12p 10-sre/slo.md
CMD
why "awk::a tiny calculator|30*24*60*0.005::30 days in minutes, times the 0.5 percent allowed failure" "Turning a percentage into minutes makes it real. That allowed downtime is the error budget: you can spend it on risky changes, and when it is gone you must slow down."
step "Do the math: how much downtime does 99.5% allow in 30 days?" "216 minutes (3.6 hours). That is your ERROR BUDGET: the downtime you can 'spend' before breaking the promise." <<'CMD'
awk 'BEGIN{printf "%.0f minutes (%.1f hours)\n", 30*24*60*0.005, 30*24*0.005}'
CMD
quiz "If the SLO were 99.9% instead, roughly how many minutes per 30 days? (hint: 0.1%)" "43|44|0\.7" "30 x 24 x 60 x 0.001 = about 43 minutes. Each extra nine costs much more to deliver."

part "PART B · Game day: cause an incident"
learn "Game days" "A game day is a planned practice failure in a safe place. You measure how long detection takes, follow the runbook, and then fix whatever was unclear. Teams that practise fail less badly when the real incident comes."
say "What is a game day?" "A planned failure exercise in a safe environment. I break something on purpose, like stopping a service, and measure how quickly we detect it, whether the alerts and the runbook work, and how long recovery takes. It finds gaps in monitoring and documentation before a real incident does, and the findings turn into improvements."
art "The game day loop" <<'ART'
   plan --> inject a failure --> measure: detect? alert? runbook? recover?
     ^                                              |
     +----- fix the gaps, update the runbook <------+
ART
why "dco up -d::start the app with Prometheus and Grafana|sleep 30::let them collect the first data" "You need monitoring running so the alert can fire during the exercise, as it would in real life."
step "Start the monitoring tools" "prometheus, grafana, blackbox running." <<'CMD'
dco up -d 2>&1 | tail -3; sleep 30
CMD
why "docker stop devlab-api-1::stop the API container" "We cause an incident on purpose, in a safe place. A game day is how a team practises before a real outage happens at 3am."
step "INJECT the failure: stop the API" "The container stops. You are now 'on call'." <<'CMD'
docker stop devlab-api-1
CMD
why "for ...; do ...; done::check the alerts every 5 seconds|grep -q EndpointDown::look for that alert" "Alerts do not fire instantly: they wait to avoid false alarms. The time between the failure and the alert is something you measure and improve."
step "Wait for the alert (up to 3 minutes)" "ALERT is pending or firing. In real life this would page you." <<'CMD'
for i in $(seq 1 36); do curl -s localhost:9090/api/v1/alerts | grep -q EndpointDown && { echo "ALERT: EndpointDown is active"; break; }; sleep 5; done
CMD
why "curl -i ... head -1::what does the site say|docker inspect::what state is the API in" "A runbook is a checklist for the person on call, so they do not have to think hard at 3am. Triage means: how bad is it, and which part is broken?"
step "Follow the RUNBOOK, step 1: triage" "502 from the proxy = web is up and api is down (runbook step 2)." <<'CMD'
curl -s -i localhost:8080/healthz | head -1; docker inspect devlab-api-1 --format 'api state: {{.State.Status}}'
CMD
why "dc logs api --tail 3::the last 3 log lines of the API" "Logs usually tell you why something stopped. Here there is nothing alarming: the API was stopped on purpose."
step "Runbook step 2: read the API logs" "Last log lines of the stopped container. For a crash these would show the reason." <<'CMD'
dc logs api --tail 3
CMD
why "docker start::bring the container back|curl /healthz::confirm it answers" "Mitigate means stop the pain first (restore service), find the deep cause later. Then verify the fix worked."
step "MITIGATE: start the API" '{"ok":true}' <<'CMD'
docker start devlab-api-1 >/dev/null; sleep 12; curl -s localhost:8080/healthz
CMD
quiz "In the runbook, a 502 from the proxy means what?" "api|backend|down|behind|upstream" "The proxy (web) is alive but the API behind it is down, so go to the 'API down' steps."

part "PART C · Hands-on: write the postmortem"
learn "Blameless postmortems" "After an incident you write what happened: summary, impact, timeline, root cause and action items with owners. Blameless means you look for the weakness in the system or process, not for a person to blame. People who fear blame hide problems."
say "How do you run a postmortem?" "Blameless and written down: a summary, the impact, a timeline, the root cause and contributing factors, what went well, what went badly, and action items with owners and dates. The focus is on the system and the process, not on who made a mistake, so people report problems honestly. Follow-up actions are tracked until they are done."
art "Shape of a postmortem" <<'ART'
   Summary -> Impact -> Timeline -> Root cause + contributing factors
        -> What went well / badly -> Action items (owner + date)
   ask "how did the system allow this?", never "who did this?"
ART
task "Write a blameless postmortem for your game day" "Create playground/postmortem.md with these five headings (use # for each): Summary, Impact, Timeline, Root cause, Action items. Under each, write a sentence or two about what you just did (for example: Root cause: the API container was stopped on purpose for a game day). Use the template in 10-sre/postmortem-template.md." "The check looks for all five headings in the file." <<'X'
f=playground/postmortem.md; [ -f $f ] && for h in Summary Impact Timeline "Root cause" "Action items"; do grep -qi "^#.*$h" $f || exit 1; done
---
printf '# Summary\nGame day: API stopped on purpose.\n# Impact\nSite returned 502 for about 3 minutes.\n# Timeline\nStopped API, alert fired, started API.\n# Root cause\nThe API container was stopped intentionally.\n# Action items\nShorten alert time; add a second runbook check.\n' > playground/postmortem.md
X
quiz "In a BLAMELESS postmortem, who do we blame?" "no one|nobody|noone|system|process|not a person|nothing" "No person. People acted sensibly with the information they had; we fix the system, process or alert that allowed the problem."

why "dco rm -sf prometheus grafana blackbox::stop and remove those services" "Free the memory. Next you write the postmortem about what you just did."
step "Tidy up: stop the monitoring tools" "Stopped." <<'CMD'
dco rm -sf prometheus grafana blackbox 2>&1 | tail -3
CMD

explain "Done! Next: bash lab.sh 11"
