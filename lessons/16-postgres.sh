# Postgres: a real database, and why it lets the API scale (about 2h)
title "Module 16 · Postgres"
mission "The app keeps its data in one file, so you can only ever run ONE copy of it. Your mission: move the data into a real database server, run several copies of the API, and learn to back the database up properly."
explain "Until now the API kept its data in a SQLite file, so you could run only ONE copy of it. A real database server (Postgres) holds the data separately. Then the API itself has no state and you can run many copies. This is the single biggest step from 'works on my machine' to 'production-shaped'."

part "PART A · Switch the API to Postgres"
learn "Stateless apps and a shared database" "SQLite keeps data in a file next to one process. A database server such as Postgres holds the data separately and many programs can use it at once. When the data lives in one shared place, the API itself keeps no state, so you can run, replace and scale copies freely."
say "What is a stateless application, and why does it matter?" "A stateless service keeps no important data in its own memory or disk; state lives in a shared database or cache. Then any copy can serve any request, so I can run many copies, replace them freely and scale horizontally. My API originally used a local SQLite file, which limited it to one copy, so I moved the data into Postgres."
art "Why shared state matters" <<'ART'
   one API with a file:   [ api + sqlite file ]          only ONE copy possible
   many APIs, one DB:     [ api ] [ api ] [ api ]  -->  [ postgres ]   any copy can answer
ART
why "dcp::dc plus the Postgres file|DATABASE_URL::the setting that tells the API where the database is" "The API used to keep data in a local file. Now the data lives in a separate database server, so the API itself keeps nothing important."
step "Start the stack with Postgres added (the API gets a DATABASE_URL)" "postgres Started and Healthy, then the api and web restart." <<'CMD'
dcp up -d --build 2>&1 | tail -6
CMD
why "curl /readyz::the readiness page|sleep 15::wait for the database to be ready" "A readiness page reports which database the API is connected to. Here it should say postgres."
step "Ask the API which store it is using" '"store":"postgres" and "ready":true. /readyz checks the database; /healthz only checks the process.' ok '"store":"postgres"' <<'CMD'
sleep 15; curl -s localhost:8080/readyz
CMD
why "curl -X POST::save a record through the API" "We create data, so we can look for it in the database in the next step."
step "Create a lead through the API" 'A reply like {"id":1}' ok '"id":[0-9]+' <<'CMD'
curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"Postgres Test\",\"email\":\"pg@example.com\",\"message\":\"stored in postgres\"}"; echo
CMD
why "psql::the Postgres command-line client|-c select ...::run one SQL query" "You see the same record in the real database. When in doubt, check the source of truth."
step "Look at the row directly inside the database" "Your lead as a row in the leads table. You are talking to Postgres with psql, the database's own command line." ok 'pg@example.com' <<'CMD'
dcp exec -T postgres psql -U devlab -d devlab -c "select id, name, email, created_at from leads order by id"
CMD
quiz "What is the difference between /healthz and /readyz?" "database|dependen|ready|serve|traffic|process|alive|up" "/healthz = the process is alive (liveness). /readyz = it can actually serve traffic, because its database is reachable (readiness). Orchestrators use them for different decisions."

part "PART B · Scale the API: many copies, one database"
learn "Scaling out" "Horizontal scaling means more copies instead of a bigger machine. It only works when every copy sees the same data, which is why the shared database matters. The proxy spreads requests between the copies."
say "What is horizontal scaling, and what does it need?" "Horizontal scaling means adding more copies instead of a bigger machine. It needs stateless instances, a load balancer in front and shared state in a database. It improves capacity and availability, but the database can become the bottleneck, so then I look at caching, read replicas and eventually sharding."
art "Scaling with a shared database" <<'ART'
   SQLite file:   [ api ] --file-->   only ONE copy can own it
   Postgres:      [ api 1 ] \
                  [ api 2 ] --> [ database ]   add copies freely
                  [ api 3 ] /
ART
mcq "Why does moving to Postgres let you run more API copies?" "The state lives in one shared database, so each API copy is stateless|Postgres is faster|It removes the need for a load balancer|It encrypts the API" 1 "Stateless app + shared state = easy horizontal scaling."
why "--scale api=2::start two containers of the api service|--no-recreate::leave the others alone" "Because the state is in Postgres, any copy of the API can serve any request. That is what stateless means, and it is the key to scaling."
step "Run TWO copies of the API" "Two api containers. The web proxy spreads requests between them." <<'CMD'
dcp up -d --scale api=2 --no-recreate 2>&1 | tail -3; sleep 12; dcp ps api --format 'table {{.Name}}\t{{.Status}}'
CMD
why "readyz shows instance::which copy answered|sort and uniq -c::count per copy" "Both copies answer, so the load is shared. If one died, the other would keep serving."
step "Send 12 requests and see which copy answered each" "Two different instance ids, so BOTH copies serve traffic." ok 'copies that answered: [2-9]' <<'CMD'
sleep 11; for i in $(seq 1 12); do curl -s localhost:8080/readyz | grep -o '"instance":"[^"]*"'; sleep 1; done | sort | uniq -c | awk '{print} END {print "copies that answered: " NR}'
CMD
why "curl -X POST::three more records|psql count::count rows in the database" "It does not matter which copy took each request: all the leads end up in the same database. Shared state is what makes copies interchangeable."
step "Create 3 more leads (they land on either copy), then count them" "A count of 4 or more. Both copies read and write the SAME database, so nothing is lost or split. With SQLite each copy would have had its own file." ok 'leads in postgres: ([4-9]|[1-9][0-9])' <<'CMD'
for n in A B C; do curl -s -o /dev/null -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"Lead $n\",\"email\":\"$n@example.com\"}"; done; dcp exec -T postgres psql -U devlab -d devlab -tAc "select 'leads in postgres: ' || count(*) from leads"
CMD
task "Scale the API to 3 copies" "Run: docker compose -f 03-compose/docker-compose.yml -f 16-postgres/compose.postgres.yml --env-file .env up -d --scale api=3 --no-recreate   Then check that 3 api containers are running." "The check passes when exactly 3 api containers are running." <<'X'
[ "$(dcp ps -q api | wc -l | tr -d ' ')" = "3" ]
---
dcp up -d --scale api=3 --no-recreate && sleep 10
X
quiz "Why could the API be scaled to 3 copies now but not when it used SQLite?" "state|shared|database|separate|file|own|single|same" "The data now lives in one shared database server, so every API copy sees the same data. With SQLite each copy had its own file, so leads would be split."

part "PART C · Back up and restore Postgres"
learn "Logical backups" "pg_dump writes the database as SQL commands you can replay. It is simple and portable. For production you also want continuous archiving so you can restore to any moment, and you must test restores regularly."
say "How do you back up a PostgreSQL database?" "pg_dump produces a logical backup, the database as SQL that I can replay with psql, which is simple and portable. For large systems I add continuous archiving or managed snapshots for point-in-time recovery. Either way I store backups off the server and test restores regularly, because an untested backup is not a backup."
art "pg_dump and restore" <<'ART'
   database --pg_dump--> backup.sql (plain SQL text) --psql--> a new, restored database
   store the file OFF the server, and test the restore regularly
ART
why "pg_dump::write the database as SQL commands|--clean --if-exists::include commands that clear old tables first|> backups/pg-lab.sql::save to a file" "A logical backup is a text file of SQL you can replay anywhere. Store backups outside the database server, and test the restore."
step "BACKUP with pg_dump" "A backup file of a few KB in backups/." ok 'pg-lab.sql' <<'CMD'
mkdir -p backups; dcp exec -T postgres pg_dump -U devlab -d devlab --clean --if-exists > backups/pg-lab.sql; ls -l backups/pg-lab.sql
CMD
why "delete from leads::remove every row|select count::count what is left" "We cause the loss on purpose, so the restore means something. Zero rows now."
step "DISASTER: delete all the leads" "leads in postgres: 0" ok 'leads in postgres: 0' <<'CMD'
dcp exec -T postgres psql -U devlab -d devlab -c "delete from leads" >/dev/null; dcp exec -T postgres psql -U devlab -d devlab -tAc "select 'leads in postgres: ' || count(*) from leads"
CMD
why "psql < pg-lab.sql::replay the backup into the database|select count::count again" "The count is back to what it was. A backup you have restored is a real backup."
step "RESTORE from the backup file" "leads in postgres: back to the earlier number." ok 'leads in postgres: ([4-9]|[1-9][0-9])' <<'CMD'
dcp exec -T postgres psql -U devlab -d devlab -q < backups/pg-lab.sql >/dev/null 2>&1; dcp exec -T postgres psql -U devlab -d devlab -tAc "select 'leads in postgres: ' || count(*) from leads"
CMD

part "PART D · Go back to SQLite"
why "dcp down::stop the Postgres version of the stack|dc up -d::start the normal stack again" "Return to the standard setup so the next modules start from a known state."
step "Remove Postgres and the extra API copies" "Only api and web remain, and /readyz says sqlite again." ok '"store":"sqlite"' <<'CMD'
dcp down 2>&1 | tail -1; dc up -d 2>&1 | tail -2; sleep 14; curl -s localhost:8080/readyz
CMD
why "docker volume rm devlab_pg-data::delete the stored database files" "The volume held the real data, so it survives dcp down. Removing it is the final, irreversible clean-up. Be careful with this in real life."
step "Remove the Postgres data volume too" "The pg-data volume is deleted. (Volumes survive 'down' until you remove them on purpose.)" <<'CMD'
docker volume rm devlab_pg-data 2>&1 | tail -1
CMD

explain "Done! Next: bash lab.sh 17"
