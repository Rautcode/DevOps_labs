# Module 03 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Change config without touching the base file" "Interviewer: 'I need the API to get an extra environment variable EXAM_FLAG=on, but nobody may edit 03-compose/docker-compose.yml. How do you do it? Show me. Use an override file called playground/exam-override.yml and restart the stack with it.'" "An override file only needs  services: / api: / environment: / EXAM_FLAG: \"on\"  . Start with both files:  docker compose -f 03-compose/docker-compose.yml -f playground/exam-override.yml --env-file .env up -d" <<'X'
dc up -d >/dev/null 2>&1; sleep 10; rm -f playground/exam-override.yml
---
docker exec devlab-api-1 printenv EXAM_FLAG | grep -q on
---
printf 'services:\n  api:\n    environment:\n      EXAM_FLAG: "on"\n' > playground/exam-override.yml && docker compose -f 03-compose/docker-compose.yml -f playground/exam-override.yml --env-file .env up -d >/dev/null 2>&1; sleep 14
---
dc up -d >/dev/null 2>&1; sleep 14
X

interview "Does the data survive?" "Interviewer: 'I just saved a lead (persist@example.com) in the database. Show me that the DATA survives when the containers themselves are deleted and recreated. I will check that the containers are new AND the lead is still there.'" "docker compose down removes containers but keeps volumes. Then bring it back up and wait about 15 seconds." <<'X'
dc up -d >/dev/null 2>&1; sleep 12; curl -s -X POST localhost:8080/api/inquiries -H "content-type: application/json" -d '{"name":"Persist","email":"persist@example.com"}' >/dev/null; docker inspect -f '{{.Id}}' devlab-api-1 > playground/.cid
---
[ "$(docker inspect -f '{{.Id}}' devlab-api-1 2>/dev/null)" != "$(cat playground/.cid)" ] && [ "$(leadsfor persist@example.com)" -ge 1 ]
---
dc down >/dev/null 2>&1; dc up -d >/dev/null 2>&1; sleep 16
X

part "PART · MODULE FINAL"

final "Destroy the data on purpose" "Exam 1 of 3. Now do the opposite: remove the stack AND its data volume, bring the stack back, and prove the lead persist@example.com is gone." "The flag that also deletes volumes is -v (be careful with it in real life)." <<'X'
true
---
curl -s localhost:8080/healthz | grep -q '"ok":true' && [ "$(leadsfor persist@example.com)" = 0 ]
---
dc down -v >/dev/null 2>&1; dc up -d >/dev/null 2>&1; sleep 16
X

final "What is exposed?" "Exam 2 of 3. Security wants to know what the stack exposes to the outside. Save the running containers and their ports into playground/ports.txt. The website port 8080 must be published; the API port must NOT be published to your computer." "docker ps --format '{{.Names}} {{.Ports}}'  shows ports. A published port looks like 0.0.0.0:8080->8080/tcp." <<'X'
rm -f playground/ports.txt
---
grep -q '0.0.0.0:8080->' playground/ports.txt && ! grep -q -- '->5000' playground/ports.txt
---
docker ps --format '{{.Names}} {{.Ports}}' | grep devlab > playground/ports.txt
X

final "Limit the API's memory" "Exam 3 of 3. Limit the API container to 256 MB of memory WITHOUT editing the base compose file (use an override file such as playground/exam-mem.yml), restart, and I will inspect the real container." "Under  services: api: deploy: resources: limits:  set  memory: 256M  . Start with both -f files." <<'X'
rm -f playground/exam-mem.yml
---
[ "$(docker inspect -f '{{.HostConfig.Memory}}' devlab-api-1 2>/dev/null)" = "268435456" ]
---
printf 'services:\n  api:\n    deploy:\n      resources:\n        limits:\n          memory: 256M\n' > playground/exam-mem.yml && docker compose -f 03-compose/docker-compose.yml -f playground/exam-mem.yml --env-file .env up -d >/dev/null 2>&1; sleep 15
---
dc up -d >/dev/null 2>&1; sleep 14
X
