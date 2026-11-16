# Postgres: a real database, and why it lets the API scale (about 2h)
title "Module 16 · Postgres"
explain "Until now the API kept its data in a SQLite file, so you could run only ONE copy of it. A real database server (Postgres) holds the data separately. Then the API itself has no state and you can run many copies. This is the single biggest step from 'works on my machine' to 'production-shaped'."

part "PART A · Switch the API to Postgres"
step "Start the stack with Postgres added (the API gets a DATABASE_URL)" "postgres Started and Healthy, then the api and web restart." <<'CMD'
$DCP up -d --build 2>&1 | tail -6
CMD
step "Ask the API which store it is using" '"store":"postgres" and "ready":true. /readyz checks the database; /healthz only checks the process.' ok '"store":"postgres"' <<'CMD'
sleep 15; curl -s localhost:8080/readyz
CMD
step "Create a lead through the API" 'A reply like {"id":1}' ok '"id":[0-9]+' <<'CMD'
curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"Postgres Test\",\"email\":\"pg@example.com\",\"message\":\"stored in postgres\"}"; echo
CMD
step "Look at the row directly inside the database" "Your lead as a row in the leads table. You are talking to Postgres with psql, the database's own command line." ok 'pg@example.com' <<'CMD'
$DCP exec -T postgres psql -U devlab -d devlab -c "select id, name, email, created_at from leads order by id"
CMD
quiz "What is the difference between /healthz and /readyz?" "database|dependen|ready|serve|traffic|process|alive|up" "/healthz = the process is alive (liveness). /readyz = it can actually serve traffic, because its database is reachable (readiness). Orchestrators use them for different decisions."

part "PART B · Scale the API: many copies, one database"
step "Run TWO copies of the API" "Two api containers. The web proxy spreads requests between them." <<'CMD'
$DCP up -d --scale api=2 --no-recreate 2>&1 | tail -3; sleep 12; $DCP ps api --format 'table {{.Name}}\t{{.Status}}'
CMD
step "Send 12 requests and see which copy answered each" "Two different instance ids, so BOTH copies serve traffic." ok 'copies that answered: [2-9]' <<'CMD'
sleep 11; for i in $(seq 1 12); do curl -s localhost:8080/readyz | grep -o '"instance":"[^"]*"'; sleep 1; done | sort | uniq -c | awk '{print} END {print "copies that answered: " NR}'
CMD
step "Create 3 more leads (they land on either copy), then count them" "A count of 4 or more. Both copies read and write the SAME database, so nothing is lost or split. With SQLite each copy would have had its own file." ok 'leads in postgres: ([4-9]|[1-9][0-9])' <<'CMD'
for n in A B C; do curl -s -o /dev/null -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"Lead $n\",\"email\":\"$n@example.com\"}"; done; $DCP exec -T postgres psql -U devlab -d devlab -tAc "select 'leads in postgres: ' || count(*) from leads"
CMD
task "Scale the API to 3 copies" "Run: docker compose -f 03-compose/docker-compose.yml -f 16-postgres/compose.postgres.yml --env-file .env up -d --scale api=3 --no-recreate   Then check that 3 api containers are running." "The check passes when exactly 3 api containers are running." <<'X'
[ "$($DCP ps -q api | wc -l | tr -d ' ')" = "3" ]
---
$DCP up -d --scale api=3 --no-recreate && sleep 10
X
quiz "Why could the API be scaled to 3 copies now but not when it used SQLite?" "state|shared|database|separate|file|own|single|same" "The data now lives in one shared database server, so every API copy sees the same data. With SQLite each copy had its own file, so leads would be split."

part "PART C · Back up and restore Postgres"
step "BACKUP with pg_dump" "A backup file of a few KB in backups/." ok 'pg-lab.sql' <<'CMD'
mkdir -p backups; $DCP exec -T postgres pg_dump -U devlab -d devlab --clean --if-exists > backups/pg-lab.sql; ls -l backups/pg-lab.sql
CMD
step "DISASTER: delete all the leads" "leads in postgres: 0" ok 'leads in postgres: 0' <<'CMD'
$DCP exec -T postgres psql -U devlab -d devlab -c "delete from leads" >/dev/null; $DCP exec -T postgres psql -U devlab -d devlab -tAc "select 'leads in postgres: ' || count(*) from leads"
CMD
step "RESTORE from the backup file" "leads in postgres: back to the earlier number." ok 'leads in postgres: ([4-9]|[1-9][0-9])' <<'CMD'
$DCP exec -T postgres psql -U devlab -d devlab -q < backups/pg-lab.sql >/dev/null 2>&1; $DCP exec -T postgres psql -U devlab -d devlab -tAc "select 'leads in postgres: ' || count(*) from leads"
CMD

part "PART D · Go back to SQLite"
step "Remove Postgres and the extra API copies" "Only api and web remain, and /readyz says sqlite again." ok '"store":"sqlite"' <<'CMD'
$DCP down 2>&1 | tail -1; $DC up -d 2>&1 | tail -2; sleep 14; curl -s localhost:8080/readyz
CMD
step "Remove the Postgres data volume too" "The pg-data volume is deleted. (Volumes survive 'down' until you remove them on purpose.)" <<'CMD'
docker volume rm devlab_pg-data 2>&1 | tail -1
CMD

explain "Done! Next: bash lab.sh 17"
