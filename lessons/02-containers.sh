# Containers: build, run and harden images (about 2h)
title "Module 02 · Containers"
mission "Your team's app works on one laptop and breaks on another: different versions, missing files. A container fixes that by packing the app and everything it needs into one sealed box that runs the same everywhere. You will run your first container in two minutes, build your own image, then build and harden the real app images."
docker rm -f my-nginx my-page lab-api >/dev/null 2>&1

part "PART A · Your first container"
learn "Image, container, registry" "An IMAGE is a read-only package: an app plus everything it needs. A CONTAINER is a running copy of an image, like a running process is to a program. A REGISTRY (Docker Hub) is a download site for images. docker run downloads the image if needed and starts a container from it."
art "Image, container, registry" <<'ART'
   REGISTRY (Docker Hub)        YOUR COMPUTER
  +------------------+  pull  +-----------+   run   +-------------+
  | nginx, postgres, | -----> |   IMAGE   | ------> |  CONTAINER  |
  | hello-world ...  |        | (template)|         |  (running)  |
  +------------------+        +-----------+         +-------------+
ART
step "Check that Docker works" "A Docker version line, such as Docker version 27.x. If you see an error, start Docker Desktop first." ok 'Docker version' <<'CMD'
docker --version
CMD
step "Run the smallest possible container" "A friendly message starting with Hello from Docker! Docker downloaded the image, ran it, and it printed and exited." ok 'Hello from Docker' <<'CMD'
docker run --rm hello-world
CMD
mcq "What is the difference between an image and a container?" "They are the same thing|An image is the template, a container is a running copy|A container is a file you download|An image only runs on Linux" 2 "Image = recipe or template. Container = a running instance made from it. One image can start many containers."
step "List the images on your computer" "hello-world is listed with its size (tiny). Images are stored locally after the first download." ok 'hello-world' <<'CMD'
docker images
CMD
step "List ALL containers, including stopped ones" "Usually nothing from hello-world: --rm told Docker to delete it after it finished. -a shows stopped containers too." <<'CMD'
docker ps -a
CMD

part "PART B · Run a real web server"
learn "Ports and background containers" "A web server keeps running, so we run it in the background with -d (detached). The server listens on port 80 INSIDE the container; -p 8088:80 publishes it as port 8088 on your computer (host:container). --name gives the container a name you can use later."
art "-p 8088:80 : opening a door" <<'ART'
   your browser/curl                 your computer              container
   localhost:8088  ------------>  [ port 8088 ] ===> [ port 80 : nginx ]
                                   (host port)          (container port)
ART
step "Start nginx in the background" "A long container id (letters and numbers). The server is now running." <<'CMD'
docker run -d --name my-nginx -p 8088:80 nginx:alpine
CMD
step "See it running" "my-nginx with status Up and 0.0.0.0:8088->80/tcp. That arrow is the port mapping." ok 'my-nginx' <<'CMD'
docker ps --filter name=my-nginx
CMD
step "Talk to it from your computer" "The first lines of the nginx welcome page, including Welcome to nginx!" ok 'Welcome to nginx' <<'CMD'
sleep 2; curl -s localhost:8088 | head -5
CMD
predict "You run the same command again but with -p 9090:80. Which address will show the welcome page?" "localhost:80|localhost:9090|localhost:8088|container:9090" 2 "The first number is the host port (your computer). The second is the port inside the container."
step "Read its logs" "A line for your request: GET / HTTP/1.1 200. Logs are the first place to look when something is wrong." ok 'GET /' <<'CMD'
docker logs my-nginx 2>&1 | tail -3
CMD
step "Stop and remove it" "my-nginx is printed back. rm -f stops and deletes it in one go." ok 'my-nginx' <<'CMD'
docker rm -f my-nginx
CMD

part "PART C · Build your own tiny image"
learn "The Dockerfile" "A Dockerfile is a recipe, one instruction per line. FROM picks the starting image. COPY puts your files in. CMD is the command to run when a container starts. docker build -t name folder follows the recipe and makes an image. Each instruction becomes a LAYER, and Docker re-uses layers it already built (the cache)."
art "A Dockerfile becomes layers" <<'ART'
   Dockerfile                        The image (stacked layers)
   FROM alpine:3.20          --->    [ layer 1: alpine Linux     ]
   COPY hello.txt /hello.txt --->    [ layer 2: your file        ]
   CMD ["cat","/hello.txt"]  --->    [ start command (metadata)  ]
ART
step "Make a folder with a file to package" "No output. The folder playground/first-image now has hello.txt." <<'CMD'
mkdir -p playground/first-image && echo "Hello from MY image" > playground/first-image/hello.txt
CMD
step "Write the Dockerfile (three lines)" "The three lines of the Dockerfile are printed back so you can read them." ok 'FROM alpine' <<'CMD'
printf 'FROM alpine:3.20\nCOPY hello.txt /hello.txt\nCMD ["cat", "/hello.txt"]\n' > playground/first-image/Dockerfile && cat playground/first-image/Dockerfile
CMD
step "Build the image" "A line naming first:lab, the tag you gave it. Your image exists now." ok 'first:lab' <<'CMD'
docker build -t first:lab playground/first-image 2>&1 | grep 'first:lab' | tail -2
CMD
step "Run your image" "Hello from MY image. Your own app, packaged." ok 'Hello from MY image' <<'CMD'
docker run --rm first:lab
CMD
step "See its layers" "A list: your CMD, your COPY, and the alpine base. Same as the picture above." ok 'COPY' <<'CMD'
docker history first:lab
CMD

part "PART D · Package a web page"
learn "Static site in nginx" "nginx serves every file in /usr/share/nginx/html. Copy your page there and the base image's own start command (nginx) does the rest, so no CMD is needed. This is exactly how the lab's web image works."
step "Create a web page and a Dockerfile" "No output. A folder with index.html and a two-line Dockerfile." <<'CMD'
mkdir -p playground/my-page && echo "<h1>My first container page</h1>" > playground/my-page/index.html && printf 'FROM nginx:alpine\nCOPY index.html /usr/share/nginx/html/index.html\n' > playground/my-page/Dockerfile
CMD
step "Build it" "A line naming my-page:lab, the tag you gave it." ok 'my-page:lab' <<'CMD'
docker build -t my-page:lab playground/my-page 2>&1 | grep 'my-page:lab' | tail -2
CMD
step "Run it on port 8089 and fetch it" "<h1>My first container page</h1>. Your page, served from a container." ok 'My first container page' <<'CMD'
docker run -d --rm --name my-page -p 8089:80 my-page:lab >/dev/null; sleep 2; curl -s localhost:8089
CMD
step "Clean up" "my-page is printed back." ok 'my-page' <<'CMD'
docker rm -f my-page
CMD

part "PART E · The real app images"
learn "Production images" "The lab's API and web images follow the same recipe with extra care: a MULTI-STAGE build (one stage installs and builds, the final stage copies only what is needed, so build tools never ship), a non-root user, a HEALTHCHECK, and a .dockerignore. Putting rarely changing steps first, such as copying package.json before the code, keeps rebuilds fast thanks to the layer cache."
art "Multi-stage build" <<'ART'
   stage 1: BUILD (big)                 stage 2: FINAL (small)
  +------------------------+  copy    +------------------------+
  | node + npm + compilers | -------> | node + your app only   |
  | install dependencies   |  result  | runs as normal user    |
  +------------------------+          +------------------------+
        thrown away                          this is shipped
ART
step "Look at the key lines of the API Dockerfile" "FROM lines (one per stage), COPY lines, and later USER and HEALTHCHECK." ok 'FROM' <<'CMD'
grep -nE '^(FROM|USER|HEALTHCHECK|COPY)' 02-containers/Dockerfile.api
CMD
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

part "PART F · Run the API on its own"
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

part "PART G · Break it on purpose"
learn "Fail fast" "Good services check their configuration when they start and refuse to run if something unsafe or missing, such as a weak secret. A loud crash at startup is cheap to fix. A quietly misconfigured service in production is expensive."
step "Start the API WITHOUT a secret" "FATAL: JWT_SECRET must be set. The app refuses to start insecurely. This is 'fail fast'." fail <<'CMD'
docker run --rm devlab-api:lab
CMD
quiz "Why is it better that the app crashes at start instead of running without a secret?" "insecure|secur|safe|silent|fail fast|weak|obvious|early" "A loud failure at startup is easy to notice and fix. Running quietly with a weak or missing secret is a hidden security hole."

part "PART H · Your turn: write your own image"
learn "Your own Dockerfile" "A tiny Dockerfile needs two things: FROM picks the base image and CMD says what to run. Write CMD in the exec form with square brackets so signals reach your program. Pin versions (alpine:3.20) instead of latest, so builds are repeatable."
task "Build an image from your own Dockerfile" "Create the file playground/Dockerfile.hello with just two lines: FROM alpine:3.20  and  CMD [\"echo\", \"hello from my first image\"]  . Then build it with: docker build -f playground/Dockerfile.hello -t hello:lab playground   and run it with: docker run --rm hello:lab" "The file must be in the playground folder. The CMD must use square brackets and double quotes." <<'X'
docker build -q -f playground/Dockerfile.hello -t hello:lab playground >/dev/null && docker run --rm hello:lab | grep -qi hello
---
printf 'FROM alpine:3.20\nCMD ["echo", "hello from my first image"]\n' > playground/Dockerfile.hello
X
quiz "Name two reasons the images in this lab run as a normal user instead of root." "attack|hack|damage|privile|install|write|limit|least" "If the process is hacked it has few rights: it cannot change system files or install tools (least privilege)."

deeper "Docker Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/Docker-Zero-to-Hero" "Containerise a Flask app: two-tier-flask-app (Shubham Londhe)|https://github.com/LondheShubham153/two-tier-flask-app"
explain "Done! Next: bash lab.sh 03"
