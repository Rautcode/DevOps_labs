# Compose: run a multi-container stack (about 2h)
title "Module 03 · Compose"
explain "Real apps are several containers working together. Docker Compose describes them in ONE file. Here: a web server (nginx) in front, and the API behind it, plus a disk volume for the data."

part "PART A · The stack"
step "Start (or refresh) the stack" "Both containers Started / Healthy." <<'CMD'
$DC up --build -d 2>&1 | tail -4
CMD
step "See the containers" "devlab-api-1 healthy and devlab-web-1 running. Only the web container publishes a port (8080)." <<'CMD'
sleep 10; $DC ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'
CMD
step "Read the important settings in the compose file" "healthcheck/depends_on (start order), volumes (data), read_only and cap_drop (hardening)." <<'CMD'
grep -nE "depends_on|condition|volumes:|read_only|cap_drop|no-new-privileges|limits|init:" 03-compose/docker-compose.yml
CMD
step "Read the API logs" "Lines like 'API listening on :5000'. Logs go to stdout; Docker collects them." <<'CMD'
$DC logs api --tail 5
CMD
quiz "The API container publishes no port to your computer. Why is that good?" "internal|private|attack|expos|only|proxy|secur|reach" "Only the web proxy is reachable from outside. The API can be reached only through it, so there is less to attack."

part "PART B · Data survives restarts (volumes)"
step "Create a lead (a record in the database)" 'A reply like {"id":1}' <<'CMD'
curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"Compose Test\",\"email\":\"c@example.com\"}"; echo
CMD
step "Count the leads in the database" "leads in database: 1 (or more)" <<'CMD'
$DC exec -T api node -e "const {DatabaseSync}=require('node:sqlite');console.log('leads in database:',new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads').get().c)"
CMD
step "Remove the containers completely" "Containers and network removed. The volume is NOT removed." <<'CMD'
$DC down 2>&1 | tail -3
CMD
step "Start fresh containers and count again" "The same number as before. The data lives in the volume, not in the container." <<'CMD'
$DC up -d 2>&1 | tail -1; sleep 12; $DC exec -T api node -e "const {DatabaseSync}=require('node:sqlite');console.log('leads in database:',new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads').get().c)"
CMD
step "Now delete the VOLUME too (down -v) and count again" "leads in database: 0. 'down -v' deletes data forever. Know the difference between 'down' and 'down -v'." <<'CMD'
$DC down -v 2>&1 | tail -2; $DC up -d 2>&1 | tail -1; sleep 12; $DC exec -T api node -e "const {DatabaseSync}=require('node:sqlite');console.log('leads in database:',new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads').get().c)"
CMD
quiz "What is the difference between 'docker compose down' and 'docker compose down -v'?" "volume|data|delet|remov|keep" "'down' removes containers but keeps volumes (your data). 'down -v' also deletes the volumes, so the data is gone."

part "PART C · Hands-on: change the config without editing the original file"
task "Add an environment variable using an override file" "Create playground/override.yml that adds LOG_LEVEL=debug to the api service. Then start the stack with BOTH files: docker compose -f 03-compose/docker-compose.yml -f playground/override.yml --env-file .env up -d   (wait about 15 seconds). Check with: docker exec devlab-api-1 printenv LOG_LEVEL" "The file is YAML: services: -> api: -> environment: -> LOG_LEVEL: debug (indent with spaces)." <<'X'
docker exec devlab-api-1 printenv LOG_LEVEL | grep -q debug
---
printf 'services:\n  api:\n    environment:\n      LOG_LEVEL: debug\n' > playground/override.yml && docker compose -f 03-compose/docker-compose.yml -f playground/override.yml --env-file .env up -d && sleep 15
X
step "Go back to the normal configuration" "api recreated without LOG_LEVEL. Overrides let you layer settings per environment." <<'CMD'
$DC up -d 2>&1 | tail -2; sleep 12; curl -s localhost:8080/healthz
CMD

explain "Done! Next: bash lab.sh 04"
