# Module 11 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Know your recovery numbers" "Interviewer: 'Backups run every night at 02:00. A disk dies at 17:00 the same day, and you restore the last backup. How much data can you lose in the worst case? That is your RPO. Write the number of hours into the file playground/rpo.txt (just the number).'" "RPO = time between the last backup and the failure. From 02:00 to 17:00 is how many hours?" <<'X'
rm -f playground/rpo.txt
---
[ "$(tr -d '[:space:]' < playground/rpo.txt)" = "15" ]
---
echo 15 > playground/rpo.txt
X

interview "Take a backup" "Interviewer: 'Take a backup of the live database right now, without stopping the app. I will look for a new, non-empty backup file in the backups folder.'" "bash 11-capstone/backup.sh" <<'X'
rm -rf backups; dc up -d >/dev/null 2>&1; sleep 12
---
f=$(ls -t backups/*.sqlite 2>/dev/null | head -1); [ -n "$f" ] && [ -s "$f" ]
---
bash 11-capstone/backup.sh >/dev/null 2>&1
X

part "PART · MODULE FINAL"

final "Recover from the disaster" "Exam 1 of 3. A lead (capstone@example.com) was saved and backed up. Then somebody deleted ALL the leads. Restore the data from the newest backup and prove that lead is back." "bash 11-capstone/restore.sh <file>   with the newest file from the backups folder (ls -t backups/*.sqlite | head -1)." <<'X'
dc up -d >/dev/null 2>&1; sleep 12; curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"Capstone","email":"capstone@example.com"}' >/dev/null; bash 11-capstone/backup.sh >/dev/null 2>&1; dc exec -T api node -e "const {DatabaseSync}=require('node:sqlite');new DatabaseSync('/data/database.sqlite').exec('DELETE FROM leads')" >/dev/null 2>&1
---
curl -s localhost:8080/healthz | grep -q '"ok":true' && [ "$(leadsfor capstone@example.com)" -ge 1 ]
---
bash 11-capstone/restore.sh "$(ls -t backups/*.sqlite | head -1)" >/dev/null 2>&1; sleep 16
X

final "Write down RPO and RTO" "Exam 2 of 3. Create playground/dr-final.md with two lines for this drill: one starting with RPO: and one starting with RTO: (describe them in your own words with a number or a time)." "Example:  RPO: the data since the last backup (minutes)   and   RTO: about 20 seconds." <<'X'
rm -f playground/dr-final.md
---
grep -q '^RPO:' playground/dr-final.md && grep -q '^RTO:' playground/dr-final.md
---
printf 'RPO: the time since the last backup\nRTO: about 20 seconds for this drill\n' > playground/dr-final.md
X

final "Production readiness review" "Exam 3 of 3. Write playground/readiness.md scoring the system in these eight areas, one line each starting with the area name: Build, Delivery, Infra, Runtime, Deploy, Monitor, Data, People. Give each a word: done, partly or not yet." "One line per area, for example:  Build: done" <<'X'
rm -f playground/readiness.md
---
f=playground/readiness.md; [ -f $f ] && for a in Build Delivery Infra Runtime Deploy Monitor Data People; do grep -q "^$a" $f || exit 1; done
---
printf 'Build: done\nDelivery: done\nInfra: partly\nRuntime: done\nDeploy: partly\nMonitor: done\nData: done\nPeople: partly\n' > playground/readiness.md
X
