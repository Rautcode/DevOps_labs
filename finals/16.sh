# Module 16 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Which database is it using?" "Interviewer: 'The API now runs with a Postgres database behind it. Prove which data store the API is using right now by asking its readiness endpoint, and save the full answer into playground/store.txt.'" "curl -s localhost:8080/readyz > playground/store.txt" <<'X'
dcp up -d --build >/dev/null 2>&1; sleep 25; rm -f playground/store.txt
---
grep -q postgres playground/store.txt
---
curl -s localhost:8080/readyz > playground/store.txt
X

interview "Is it really in Postgres?" "Interviewer: 'Create a lead with the email pg-exam@example.com through the API. Then show me the row exists in the POSTGRES database itself, not in SQLite. I will query the database.'" "Create it with curl POST /api/inquiries. Look inside with:  dcp exec -T postgres psql -U devlab -d devlab -c \"select * from leads\"" <<'X'
true
---
[ "$(dcp exec -T postgres psql -U devlab -d devlab -tAc "select count(*) from leads where email='pg-exam@example.com'" | tr -d '\r\n ')" -ge 1 ]
---
curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"PG Exam","email":"pg-exam@example.com"}' >/dev/null
X

part "PART · MODULE FINAL"

final "Run many copies" "Exam 1 of 3. Because the data now lives in one shared database, run TWO copies of the API behind the web proxy. I will count the running api containers." "dcp up -d --scale api=2 --no-recreate" <<'X'
true
---
[ "$(dcp ps -q api | wc -l | tr -d ' ')" = "2" ]
---
dcp up -d --scale api=2 --no-recreate >/dev/null 2>&1; sleep 12
X

final "Back up Postgres" "Exam 2 of 3. Make a logical backup of the Postgres database with pg_dump into playground/pg-exam.sql. It must contain the lead pg-exam@example.com." "dcp exec -T postgres pg_dump -U devlab -d devlab --clean --if-exists > playground/pg-exam.sql" <<'X'
rm -f playground/pg-exam.sql
---
grep -q 'pg-exam@example.com' playground/pg-exam.sql
---
dcp exec -T postgres pg_dump -U devlab -d devlab --clean --if-exists > playground/pg-exam.sql
X

final "Restore it" "Exam 3 of 3. DISASTER: somebody deleted every lead in Postgres. Restore the database from YOUR backup file playground/pg-exam.sql and prove the lead pg-exam@example.com is back." "dcp exec -T postgres psql -U devlab -d devlab -q < playground/pg-exam.sql" <<'X'
dcp exec -T postgres psql -U devlab -d devlab -c "delete from leads" >/dev/null 2>&1
---
[ "$(dcp exec -T postgres psql -U devlab -d devlab -tAc "select count(*) from leads where email='pg-exam@example.com'" | tr -d '\r\n ')" -ge 1 ]
---
dcp exec -T postgres psql -U devlab -d devlab -q < playground/pg-exam.sql >/dev/null 2>&1
---
dcp down >/dev/null 2>&1; dc up -d >/dev/null 2>&1; docker volume rm devlab_pg-data >/dev/null 2>&1; sleep 12
X
