# Capstone: disaster recovery and production readiness (about 2h)
title "Module 11 · Capstone"
explain "Backups that were never restored are not backups. In this capstone you run a real disaster-recovery drill: lose data on purpose, then bring it back. Then you review the whole system like a production-readiness reviewer."
COUNT='$DC exec -T api node -e "const {DatabaseSync}=require(\"node:sqlite\");console.log(\"leads in database:\",new DatabaseSync(\"/data/database.sqlite\").prepare(\"select count(*) c from leads\").get().c)"'
export COUNT

part "PART A · The disaster-recovery drill"
step "Make sure the app is running" '{"ok":true}' <<'CMD'
$DC up -d 2>&1 | tail -1; sleep 12; curl -s localhost:8080/healthz
CMD
step "Create 2 leads (the data we must not lose)" 'Two replies like {"id":N}' <<'CMD'
for n in Asha Ravi; do curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"$n\",\"email\":\"$n@example.com\"}"; echo; done
CMD
step "Count them" "leads in database: 2 (or more if you added some earlier)" <<'CMD'
eval "$COUNT"
CMD
step "BACKUP (online and consistent, the app keeps running)" "backup written: backups/devlab-<time>.sqlite" <<'CMD'
bash 11-capstone/backup.sh | tail -1
CMD
step "DISASTER: delete all the data" "The count is now 0." <<'CMD'
$DC exec -T api node -e "const {DatabaseSync}=require('node:sqlite');new DatabaseSync('/data/database.sqlite').exec('DELETE FROM leads')"; eval "$COUNT"
CMD
step "RESTORE from the newest backup" "restored from backups/devlab-...sqlite" <<'CMD'
START=$(date +%s); bash 11-capstone/restore.sh "$(ls -t backups/*.sqlite | head -1)" | tail -1; sleep 12; echo "recovery took about $(( $(date +%s) - START )) seconds"
CMD
step "Count again" "The original number is back. You recovered from a disaster." <<'CMD'
eval "$COUNT"
CMD
task "Record your RPO and RTO" "RPO = how much data you could lose (the time since your last backup). RTO = how long recovery took. Create playground/dr-notes.md and write two lines: one starting with RPO: and one starting with RTO: (use the numbers from this drill)." "The file must contain the words RPO and RTO." <<'X'
grep -q "RPO" playground/dr-notes.md && grep -q "RTO" playground/dr-notes.md
---
printf 'RPO: up to the time since the last backup (manual backups: could be hours).\nRTO: about 20 seconds for this drill.\n' > playground/dr-notes.md
X
quiz "What is the difference between RPO and RTO?" "data|loss|lose|time|recover|how long|how much" "RPO = how much data you can lose (time since last backup). RTO = how long it takes to be running again."
quiz "Name one way to improve your RPO." "frequent|schedule|cron|continuous|litestream|replicat|automat|more often" "Back up more often (scheduled jobs) or replicate continuously (for example Litestream). Also copy backups off the machine."

part "PART B · Production-readiness review"
explain "A reviewer asks: could this system run in production? Score yourself honestly (done / partly / not yet):"
explain "  BUILD    small, non-root, scanned images                         (module 02, 09)"
explain "  DELIVERY every change tested, scanned and signed by a pipeline  (module 04)"
explain "  INFRA    cloud resources in code with tests                     (module 05)"
explain "  RUNTIME  probes, limits, autoscaling, network policy            (module 06)"
explain "  DEPLOY   git is the source of truth, rollback = revert          (module 07)"
explain "  MONITOR  SLOs, burn-rate alerts, a runbook per alert            (module 08, 10)"
explain "  DATA     backups restored in a drill, RPO and RTO known         (this module)"
explain "  PEOPLE   postmortems and game days                              (module 10)"
quiz "Which area is your weakest right now, and what is one thing you would do next?" "." "There is no wrong answer. Pick one and turn it into a small task: for example, schedule the backup script, or push this repo and enable the CI workflow."

part "PART C · Core path complete: what next?"
explain "You finished the core path (lessons 01-11). The SPECIALIST modules go deeper and continue automatically: 12 Networking, 13 Ansible, 14 Helm and RBAC, 15 Logging and tracing, 16 Postgres, 17 Real cloud (AWS). Press Enter at the next prompt to start 12, or stop here and run:  bash lab.sh down"
