# Module 02 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Write a Dockerfile from scratch" "Interviewer: 'Write a Dockerfile at playground/exam/Dockerfile for a tiny image that prints the name of its Linux distribution when it runs (the file /etc/os-release has it). Build it as exam-img. I will run it.'" "Two lines are enough:  FROM alpine:3.20  and  CMD [\"cat\", \"/etc/os-release\"]  . Build:  docker build -t exam-img playground/exam" <<'X'
mkdir -p playground/exam; rm -f playground/exam/Dockerfile; docker rmi -f exam-img >/dev/null 2>&1
---
docker build -q -t exam-img playground/exam >/dev/null 2>&1 && docker run --rm exam-img | grep -qiE "pretty_name|alpine|debian"
---
printf 'FROM alpine:3.20\nCMD ["cat", "/etc/os-release"]\n' > playground/exam/Dockerfile
---
docker rmi -f exam-img >/dev/null 2>&1
X

interview "Prove it is not root" "Interviewer: 'Security asks: does our API image run as root? Prove it. Save the numeric user id the container runs as into playground/uid.txt.'" "docker run --entrypoint id devlab-api:lab -u   runs the id command inside the image and prints the numeric user id." <<'X'
docker image inspect devlab-api:lab >/dev/null 2>&1 || docker build -q -f 02-containers/Dockerfile.api -t devlab-api:lab app/api >/dev/null 2>&1; rm -f playground/uid.txt
---
[ "$(tr -d '[:space:]' < playground/uid.txt 2>/dev/null)" = "1000" ]
---
docker run --rm --entrypoint id devlab-api:lab -u > playground/uid.txt
X

part "PART · MODULE FINAL"

final "Build the release image" "Exam 1 of 3. Build the API image from app/api using 02-containers/Dockerfile.api and tag it devlab-api:exam." "docker build -f <Dockerfile> -t <name:tag> <folder>   (the folder is the build context)." <<'X'
docker rmi -f devlab-api:exam >/dev/null 2>&1
---
docker image inspect devlab-api:exam >/dev/null 2>&1
---
docker build -q -f 02-containers/Dockerfile.api -t devlab-api:exam app/api >/dev/null 2>&1
X

final "Run it correctly" "Exam 2 of 3. Run devlab-api:exam as a container named exam-api, published on host port 5002 (container port 5000), with the two required settings JWT_SECRET (at least 32 characters) and ADMIN_PASSWORD. Wait until Docker reports it healthy." "Use  docker run -d --name exam-api -p 5002:5000 -e JWT_SECRET=... -e ADMIN_PASSWORD=... devlab-api:exam  . The health check needs about 20 seconds." <<'X'
docker rm -f exam-api >/dev/null 2>&1
---
[ "$(docker inspect -f '{{.State.Health.Status}}' exam-api 2>/dev/null)" = healthy ] && curl -s localhost:5002/healthz | grep -q '"ok":true'
---
docker run -d --name exam-api -p 5002:5000 -e JWT_SECRET=exam-secret-exam-secret-exam-secret-1 -e ADMIN_PASSWORD=x devlab-api:exam >/dev/null 2>&1; sleep 28
---
docker rm -f exam-api >/dev/null 2>&1
X

final "Fail fast" "Exam 3 of 3. Run the image WITHOUT the JWT_SECRET setting and save everything it prints into playground/fatal.txt. The file must contain the word FATAL." "docker run --rm devlab-api:exam > playground/fatal.txt 2>&1   (the app refuses to start without a secret and says why)." <<'X'
rm -f playground/fatal.txt
---
grep -q FATAL playground/fatal.txt
---
docker run --rm devlab-api:exam > playground/fatal.txt 2>&1; true
---
docker rmi -f devlab-api:exam >/dev/null 2>&1
X
