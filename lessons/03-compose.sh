# Compose: run a multi-container stack (about 2h)
title "Module 03 · Compose"
mission "The app is now three pieces: a web server, an API and a database file. Starting them one by one with long commands is slow and error-prone. Your mission: describe the whole stack in ONE file and start, stop and rebuild it with a single command."
explain "Real apps are several containers working together. Docker Compose describes them in ONE file. Here: a web server (nginx) in front, and the API behind it, plus a disk volume for the data."

part "PART A · The stack"
learn "Why Docker Compose?" "Real apps are several containers. A compose file describes the services, networks and volumes in one place, so docker compose up creates the whole stack and down removes it. The same file works on every machine, which ends the 'works on my machine' problem."
say "Why use Docker Compose?" "Real applications are several containers. Compose describes the whole stack in one file, with services, networks, volumes, environment and health checks, and I start everything with one command. It is reproducible and reviewable, so a new teammate gets the same environment. It is great for local development and tests; for production at scale I would use Kubernetes."
art "One file, whole stack" <<'ART'
   docker-compose.yml
        |
        v                    browser  ->  web (nginx) -> api (Node) -> data volume
   docker compose up         all three started, wired and named together
ART
mcq "Which command starts every service in a compose file?" "docker compose up|docker run|docker compose list|docker start all" 1 "docker compose up -d builds if needed and starts the whole stack in the background."
why "dc::the lab shortcut for docker compose|up -d::create and start the services in the background|--build::rebuild the images first" "One command starts the whole stack, instead of several long docker run commands. Compose reads the file and brings up the web server and the API together, in the right order."
step "Start (or refresh) the stack" "Both containers Started / Healthy." <<'CMD'
dc up --build -d 2>&1 | tail -4
CMD
why "dc ps::list the services of this stack|--format table ...::choose the columns: name, status, ports" "This shows what is running and whether it is healthy. In Compose a service waits for its dependencies, so the order of start is handled for you."
step "See the containers" "devlab-api-1 healthy and devlab-web-1 running. Only the web container publishes a port (8080)." <<'CMD'
sleep 10; dc ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'
CMD
why "grep -nE::search with line numbers|depends_on, volumes, read_only, cap_drop, limits::the settings that matter most" "The file is where the stack is defined. depends_on controls start order, volumes keep data, and the hardening settings (read_only, cap_drop, limits) make the containers safer."
step "Read the important settings in the compose file" "healthcheck/depends_on (start order), volumes (data), read_only and cap_drop (hardening)." <<'CMD'
grep -nE "depends_on|condition|volumes:|read_only|cap_drop|no-new-privileges|limits|init:" 03-compose/docker-compose.yml
CMD
why "dc logs api::show the logs of the api service|--tail 5::only the last 5 lines" "Compose gathers the logs of a service in one place. Reading them is how you check that the app started and answered requests."
step "Read the API logs" "Lines like 'API listening on :5000'. Logs go to stdout; Docker collects them." <<'CMD'
dc logs api --tail 5
CMD
quiz "The API container publishes no port to your computer. Why is that good?" "internal|private|attack|expos|only|proxy|secur|reach" "Only the web proxy is reachable from outside. The API can be reached only through it, so there is less to attack."

part "PART B · Data survives restarts (volumes)"
learn "Volumes keep data" "A container's own filesystem is disposable. A volume is storage managed by Docker OUTSIDE the container, so it survives when the container is deleted. docker compose down removes the containers but keeps volumes; down -v also deletes the volumes, and the data is gone for good."
say "How do containers persist data?" "A container's own filesystem is disposable: it disappears when the container is removed. A volume is storage managed outside the container, so the data survives restarts and replacement. Databases and uploads should always use volumes. I also back them up, because a volume protects against losing the container, not against deletion or corruption."
art "Container filesystem vs volume" <<'ART'
   container deleted  ->  its own files are GONE
   volume             ->  lives outside the container, data SURVIVES
   [ container ] ---mounts---> [ volume: /data ]
ART
predict "You delete the API container but keep its volume, then start a new container with the same volume. Is the data still there?" "Yes, the volume still holds it|No, everything is lost|Only half of it|Only after a restart" 1 "A volume has its own life, separate from any container. That is why databases always use volumes."
why "curl -X POST::send data to the API|-H::tell it the data is JSON|-d::the data: a name and an email" "You save a real record through the website API. In the next steps you will see what happens to this data when the containers are removed."
step "Create a lead (a record in the database)" 'A reply like {"id":1}' <<'CMD'
curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"Compose Test\",\"email\":\"c@example.com\"}"; echo
CMD
why "dc exec -T api::run a command inside the api service (no terminal needed)|node -e ...::a tiny script that counts the rows in the database" "Instead of trusting the API, we ask the database itself how many leads it holds. Checking the source of truth is a good habit."
step "Count the leads in the database" "leads in database: 1 (or more)" <<'CMD'
dc exec -T api node -e "const {DatabaseSync}=require('node:sqlite');console.log('leads in database:',new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads').get().c)"
CMD
why "dc down::stop and remove the containers and the network" "The containers are gone, but we did NOT ask to remove the volume, so the data is still stored. This is the difference between disposable containers and persistent data."
step "Remove the containers completely" "Containers and network removed. The volume is NOT removed." <<'CMD'
dc down 2>&1 | tail -3
CMD
why "dc up -d::start new containers|count again::ask the database once more" "The count is the same as before: new containers, same data. The volume kept it. This is why databases always use volumes."
step "Start fresh containers and count again" "The same number as before. The data lives in the volume, not in the container." <<'CMD'
dc up -d 2>&1 | tail -1; sleep 12; dc exec -T api node -e "const {DatabaseSync}=require('node:sqlite');console.log('leads in database:',new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads').get().c)"
CMD
why "dc down -v::remove the containers AND the volumes|count again::ask the database" "Now the data really is gone, and the count starts again from zero. -v is dangerous in production, so always think before you use it. It also shows why backups matter."
step "Now delete the VOLUME too (down -v) and count again" "leads in database: 0. 'down -v' deletes data forever. Know the difference between 'down' and 'down -v'." <<'CMD'
dc down -v 2>&1 | tail -2; dc up -d 2>&1 | tail -1; sleep 12; dc exec -T api node -e "const {DatabaseSync}=require('node:sqlite');console.log('leads in database:',new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads').get().c)"
CMD
quiz "What is the difference between 'docker compose down' and 'docker compose down -v'?" "volume|data|delet|remov|keep" "'down' removes containers but keeps volumes (your data). 'down -v' also deletes the volumes, so the data is gone."

part "PART C · Hands-on: change the config without editing the original file"
learn "Override files" "You can pass -f several times. Later files override earlier ones. Keep the shared base file clean and put environment-specific changes in small override files, so nobody edits the base by accident."
say "How do you manage different environments with Compose?" "I keep a base compose file and add override files with -f. Later files override earlier ones, so a monitoring or production override contains only the differences. That avoids copying a big file per environment and keeps the shared parts in one place."
art "Layering compose files" <<'ART'
   docker-compose.yml          (base: shared by everyone)
        + monitoring.yml       (adds Prometheus and Grafana)
        + postgres.yml         (swaps the database)
        = the final stack      later files override earlier ones  (-f a.yml -f b.yml)
ART
task "Add an environment variable using an override file" "Create playground/override.yml that adds LOG_LEVEL=debug to the api service. Then start the stack with BOTH files: docker compose -f 03-compose/docker-compose.yml -f playground/override.yml --env-file .env up -d   (wait about 15 seconds). Check with: docker exec devlab-api-1 printenv LOG_LEVEL" "The file is YAML: services: -> api: -> environment: -> LOG_LEVEL: debug (indent with spaces)." <<'X'
docker exec devlab-api-1 printenv LOG_LEVEL | grep -q debug
---
printf 'services:\n  api:\n    environment:\n      LOG_LEVEL: debug\n' > playground/override.yml && docker compose -f 03-compose/docker-compose.yml -f playground/override.yml --env-file .env up -d && sleep 15
X
why "dc up -d::start the stack with the normal file|curl /healthz::check it is healthy" "We return to the standard setup and prove it works, so the next module starts from a known good state."
step "Go back to the normal configuration" "api recreated without LOG_LEVEL. Overrides let you layer settings per environment." <<'CMD'
dc up -d 2>&1 | tail -2; sleep 12; curl -s localhost:8080/healthz
CMD

deeper "Flask + database with Compose: two-tier-flask-app (Shubham Londhe)|https://github.com/LondheShubham153/two-tier-flask-app" "Django notes app (Shubham Londhe)|https://github.com/LondheShubham153/django-notes-app"
explain "Done! Next: bash lab.sh 04"
