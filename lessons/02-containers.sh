# Containers: build, run and harden images (about 2h)
title "Module 02 · Containers"
explain "A container image is a sealed package of your app plus everything it needs. You will build two images, run one on its own, break it on purpose, and write your own image."

part "PART A · Build the images"
learn "Images, layers and the Dockerfile" "An image is a read-only template; a container is a running copy of it. A Dockerfile lists the steps to build an image. Each instruction (FROM, COPY, RUN) adds a layer, and Docker caches layers, so putting rarely changing steps first makes rebuilds fast. A multi-stage build keeps build tools out of the final image."
step "Build the API image" "The last lines say the image was built and named devlab-api:lab." <<'CMD'
docker build -f 02-containers/Dockerfile.api -t devlab-api:lab app/api 2>&1 | tail -4
CMD
step "Build the web image" "Built and named devlab-web:lab." <<'CMD'
docker build -f 02-containers/Dockerfile.web -t devlab-web:lab . 2>&1 | tail -4
CMD
step "Compare the sizes" "Both are small because they use slim bases and multi-stage builds." <<'CMD'
docker images --format '{{.Repository}}:{{.Tag}}   {{.Size}}' | grep devlab
CMD
step "Build the API image AGAIN and count cached layers" "A number above 0. Docker reuses unchanged layers, so rebuilds take seconds. That is why package.json is copied before the source code." <<'CMD'
docker build --progress=plain -f 02-containers/Dockerfile.api -t devlab-api:lab app/api 2>&1 | grep -c CACHED
CMD
quiz "Why is package.json copied BEFORE the rest of the source in the Dockerfile?" "cache|layer|rebuild|reinstall|faster" "Dependencies change rarely and code changes often. Copying package.json first lets Docker cache the slow npm install layer."

part "PART B · Run one container on its own"
learn "Running a container" "docker run starts a container from an image. -d runs it in the background, -p 5001:5000 maps host port 5001 to container port 5000, and -e sets an environment variable. A HEALTHCHECK in the Dockerfile lets Docker tell the difference between started and really working."
step "Run the API alone on port 5001" "A long container id is printed." <<'CMD'
docker rm -f lab-api >/dev/null 2>&1; docker run --rm -d --name lab-api -p 5001:5000 -e JWT_SECRET=lab-only-lab-only-lab-only-lab-only-123 -e ADMIN_PASSWORD=x devlab-api:lab
CMD
step "Ask it for its health" '{"ok":true}' <<'CMD'
sleep 4; curl -s localhost:5001/healthz
CMD
step "Docker's own health check" "healthy. The Dockerfile has a HEALTHCHECK, so Docker knows if the app is really working (not just started)." <<'CMD'
sleep 15; docker inspect lab-api --format '{{.State.Health.Status}}'
CMD
step "Who runs it, and is npm inside?" "uid=1000 (not root) and a message that npm is not in the image. Fewer tools = less for an attacker to use." <<'CMD'
docker exec lab-api id; docker exec lab-api sh -c 'which npm || echo "npm is not in this image, on purpose"'
CMD
step "Stop it" "The container is removed." <<'CMD'
docker rm -f lab-api
CMD

part "PART C · Break it on purpose"
learn "Fail fast" "Good services check their configuration when they start and refuse to run if something unsafe or missing, such as a weak secret. A loud crash at startup is cheap to fix. A quietly misconfigured service in production is expensive."
step "Start the API WITHOUT a secret" "FATAL: JWT_SECRET must be set. The app refuses to start insecurely. This is 'fail fast'." fail <<'CMD'
docker run --rm devlab-api:lab
CMD
quiz "Why is it better that the app crashes at start instead of running without a secret?" "insecure|secur|safe|silent|fail fast|weak|obvious|early" "A loud failure at startup is easy to notice and fix. Running quietly with a weak or missing secret is a hidden security hole."

part "PART D · Hands-on: write your own image"
learn "Your own Dockerfile" "A tiny Dockerfile needs two things: FROM picks the base image and CMD says what to run. Write CMD in the exec form with square brackets so signals reach your program. Pin versions (alpine:3.20) instead of latest, so builds are repeatable."
task "Build an image from your own Dockerfile" "Create the file playground/Dockerfile.hello with just two lines: FROM alpine:3.20  and  CMD [\"echo\", \"hello from my first image\"]  . Then build it with: docker build -f playground/Dockerfile.hello -t hello:lab playground   and run it with: docker run --rm hello:lab" "The file must be in the playground folder. The CMD must use square brackets and double quotes." <<'X'
docker build -q -f playground/Dockerfile.hello -t hello:lab playground >/dev/null && docker run --rm hello:lab | grep -qi hello
---
printf 'FROM alpine:3.20\nCMD ["echo", "hello from my first image"]\n' > playground/Dockerfile.hello
X
quiz "Name two reasons the images in this lab run as a normal user instead of root." "attack|hack|damage|privile|install|write|limit|least" "If the process is hacked it has few rights: it cannot change system files or install tools (least privilege)."

explain "Done! Next: bash lab.sh 03"
