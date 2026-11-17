# Module 10 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Do the error-budget math" "Interviewer: 'Our availability promise (SLO) is 99.9% over 30 days. How many minutes of downtime does that allow per month? Work it out with a command and save the number, rounded to a whole number of minutes, into playground/budget.txt.'" "30 days x 24 hours x 60 minutes x 0.001 . A calculator is fine:  awk 'BEGIN{printf \"%.0f\", 30*24*60*0.001}'" <<'X'
rm -f playground/budget.txt
---
grep -qE '^(43|44)$' playground/budget.txt
---
awk 'BEGIN{printf "%.0f\n", 30*24*60*0.001}' > playground/budget.txt
X

interview "Debug a crash loop" "Interviewer: 'Production is down: the API container keeps restarting after somebody changed its configuration. Find the ROOT CAUSE in the logs and save the log line that explains it into playground/cause.txt. Then fix the problem so the site is healthy again.'" "dc logs api --tail 10  shows why it exits (look for FATAL). The bad change is an override file in playground/bad-env.yml. Bring the stack back WITHOUT it:  dc up -d" <<'X'
dc up -d >/dev/null 2>&1; sleep 10; printf 'services:\n  api:\n    environment:\n      JWT_SECRET: short\n' > playground/bad-env.yml; docker compose -f 03-compose/docker-compose.yml -f playground/bad-env.yml --env-file .env up -d >/dev/null 2>&1; sleep 15; rm -f playground/cause.txt
---
grep -q 'JWT_SECRET' playground/cause.txt && curl -s localhost:8080/healthz | grep -q '"ok":true'
---
dc logs api --tail 10 --no-log-prefix 2>&1 | grep FATAL | head -1 > playground/cause.txt; dc up -d >/dev/null 2>&1; sleep 18
---
rm -f playground/bad-env.yml
X

part "PART · MODULE FINAL"

final "Write a postmortem with action items" "Exam 1 of 3. Write playground/pm-exam.md, a blameless postmortem for the crash-loop incident. It needs these headings: Summary, Impact, Timeline, Root cause, Action items. Under Action items write at least one bullet that starts with '- ' and names an owner." "Use the template in 10-sre/postmortem-template.md. A bullet looks like:  - Add a startup config check (owner: platform team)" <<'X'
rm -f playground/pm-exam.md
---
f=playground/pm-exam.md; [ -f $f ] && for h in Summary Impact Timeline "Root cause" "Action items"; do grep -qi "^#.*$h" $f || exit 1; done; grep -q '^- ' $f
---
printf '# Summary\nThe API crash-looped after a bad configuration change.\n# Impact\nThe site was down for about 5 minutes.\n# Timeline\nBad config applied, API restarted repeatedly, config reverted.\n# Root cause\nJWT_SECRET was shorter than 32 characters so the app refused to start.\n# Action items\n- Validate configuration in CI (owner: platform team)\n' > playground/pm-exam.md
X

final "Write the runbook" "Exam 2 of 3. Write playground/runbook-exam.md, a runbook for the alert EndpointDown. It must have the headings Impact, Triage and Mitigation, and the Triage part must contain at least one real docker command (the word docker)." "Look at 10-sre/runbooks/api-down.md for a model." <<'X'
rm -f playground/runbook-exam.md
---
f=playground/runbook-exam.md; [ -f $f ] && for h in Impact Triage Mitigation; do grep -qi "^#.*$h" $f || exit 1; done; grep -q docker $f
---
printf '# Impact\nVisitors cannot load pages.\n# Triage\nRun docker ps and docker logs devlab-api-1 to see which container failed.\n# Mitigation\nFix the cause, then docker start devlab-api-1.\n' > playground/runbook-exam.md
X

final "How much budget is left?" "Exam 3 of 3. The 99.5% SLO allows 216 minutes of downtime per 30 days. We already used 100 minutes. What PERCENT of the error budget is left? Work it out and save the whole number into playground/remaining.txt." "(216 - 100) / 216 x 100, rounded." <<'X'
rm -f playground/remaining.txt
---
grep -qE '^5[34]$' playground/remaining.txt
---
awk 'BEGIN{printf "%.0f\n", (216-100)/216*100}' > playground/remaining.txt
X
