# Module 12 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Is that port really in use?" "Interviewer: 'A developer insists nothing listens on port 8080. Prove them wrong from INSIDE the web container: list the listening TCP ports and save the output into playground/listen.txt.'" "docker exec devlab-web-1 netstat -tln   lists listening TCP ports inside the container." <<'X'
dc up -d >/dev/null 2>&1; sleep 12; rm -f playground/listen.txt
---
grep -q 8080 playground/listen.txt && grep -q LISTEN playground/listen.txt
---
docker exec devlab-web-1 netstat -tln > playground/listen.txt
X

interview "Certificates expire" "Interviewer: 'Create a self-signed certificate for the name example.test that is valid for only 3 days. Put it at playground/tls2/cert.pem (and its key at playground/tls2/key.pem). I will read the subject and the expiry date.'" "docker run --rm -v \"\$PWD/playground/tls2:/out\" alpine/openssl req -x509 -newkey rsa:2048 -nodes -keyout /out/key.pem -out /out/cert.pem -days 3 -subj \"/CN=example.test\"" <<'X'
rm -rf playground/tls2; mkdir -p playground/tls2
---
docker run --rm -v "$PWD/playground/tls2:/c" alpine/openssl x509 -in /c/cert.pem -noout -subject 2>/dev/null | grep -q example.test && docker run --rm -v "$PWD/playground/tls2:/c" alpine/openssl x509 -in /c/cert.pem -noout -checkend 0 >/dev/null 2>&1 && ! docker run --rm -v "$PWD/playground/tls2:/c" alpine/openssl x509 -in /c/cert.pem -noout -checkend 345600 >/dev/null 2>&1
---
docker run --rm -v "$PWD/playground/tls2:/out" alpine/openssl req -x509 -newkey rsa:2048 -nodes -keyout /out/key.pem -out /out/cert.pem -days 3 -subj "/CN=example.test" >/dev/null 2>&1
X

part "PART · MODULE FINAL"

final "DNS between containers" "Exam 1 of 3. A container named exam-db is running on the network exam-net. From a throwaway busybox container on that SAME network, look up the name exam-db and save its IP address (only the address) into playground/dbip.txt." "docker run --rm --network exam-net busybox nslookup exam-db   prints the address; keep the last Address line." <<'X'
docker rm -f exam-db >/dev/null 2>&1; docker network rm exam-net >/dev/null 2>&1; docker network create exam-net >/dev/null 2>&1; docker run -d --name exam-db --network exam-net nginx:alpine >/dev/null 2>&1; sleep 3; rm -f playground/dbip.txt
---
[ "$(tr -d '[:space:]' < playground/dbip.txt)" = "$(docker inspect -f '{{(index .NetworkSettings.Networks "exam-net").IPAddress}}' exam-db)" ]
---
docker run --rm --network exam-net busybox nslookup exam-db 2>/dev/null | grep -E '^Address' | tail -1 | awk '{print $NF}' > playground/dbip.txt
---
docker rm -f exam-db >/dev/null 2>&1; docker network rm exam-net >/dev/null 2>&1
X

final "Two servers, one machine" "Exam 2 of 3. A web server named exam-a already owns host port 8085. Start a SECOND nginx container named exam-b that is reachable on host port 8086 (container port 80). Both must answer." "docker run -d --name exam-b -p 8086:80 nginx:alpine   (a host port can only belong to one program)" <<'X'
docker rm -f exam-a exam-b >/dev/null 2>&1; docker run -d --name exam-a -p 8085:80 nginx:alpine >/dev/null 2>&1; sleep 3
---
curl -s localhost:8085 | grep -qi nginx && curl -s localhost:8086 | grep -qi nginx
---
docker run -d --name exam-b -p 8086:80 nginx:alpine >/dev/null 2>&1; sleep 3
---
docker rm -f exam-a exam-b >/dev/null 2>&1
X

final "Survive a backend failure" "Exam 3 of 3. A load balancer (port 8090) spreads traffic over two backends, lab-a and lab-b. One backend dies: STOP lab-a. The site must keep answering through the balancer." "docker stop lab-a   then  curl localhost:8090  should still work, served by lab-b." <<'X'
docker rm -f lab-a lab-b lab-lb >/dev/null 2>&1; docker network rm lab-net >/dev/null 2>&1; docker network create lab-net >/dev/null 2>&1; docker run -d --name lab-a --network lab-net traefik/whoami >/dev/null 2>&1; docker run -d --name lab-b --network lab-net traefik/whoami >/dev/null 2>&1; sleep 2; docker run -d --name lab-lb --network lab-net -p 8090:80 -v "$PWD/12-networking/lb.conf:/etc/nginx/conf.d/default.conf:ro" nginx:alpine >/dev/null 2>&1; sleep 3
---
[ "$(docker inspect -f '{{.State.Running}}' lab-a)" = "false" ] && curl -s localhost:8090 | grep -q Hostname
---
docker stop lab-a >/dev/null 2>&1
---
docker rm -f lab-a lab-b lab-lb >/dev/null 2>&1; docker network rm lab-net >/dev/null 2>&1
X
