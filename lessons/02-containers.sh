# Containers: build, run and harden images (about 2h)
title "Module 02 · Containers"
mission "Your team's app works on one laptop and breaks on another: different versions, missing files. A container fixes that by packing the app and everything it needs into one sealed box that runs the same everywhere. You will run your first container in two minutes, build your own image, then build and harden the real app images."
docker rm -f my-nginx my-page lab-api >/dev/null 2>&1

part "PART A · Your first container"
learn "Image, container, registry" "An IMAGE is a read-only package: an app plus everything it needs. A CONTAINER is a running copy of an image, like a running process is to a program. A REGISTRY (Docker Hub) is a download site for images. docker run downloads the image if needed and starts a container from it."
say "What are an image, a container and a registry?" "An image is a read-only package with an app and everything it needs. A container is a running instance of an image. A registry, like Docker Hub or ECR, is where images are stored and pulled from. So the flow is: build an image, push it to a registry, then pull and run it as containers wherever I need it."
art "Image, container, registry" <<'ART'
   REGISTRY (Docker Hub)        YOUR COMPUTER
  +------------------+  pull  +-----------+   run   +-------------+
  | nginx, postgres, | -----> |   IMAGE   | ------> |  CONTAINER  |
  | hello-world ...  |        | (template)|         |  (running)  |
  +------------------+        +-----------+         +-------------+
ART
why "docker::the Docker program|--version::print its version" "If a version appears, Docker is installed and running. If you get an error instead, start Docker Desktop first, because every other step in this module needs it."
step "Check that Docker works" "A Docker version line, such as Docker version 27.x. If you see an error, start Docker Desktop first." ok 'Docker version' <<'CMD'
docker --version
CMD
why "docker run::create a container from an image and start it|--rm::delete the container when it stops|hello-world::the name of a tiny test image" "Docker downloads the image the first time (that is the pull), runs it, prints a welcome message and exits. It proves the whole chain works: download, create, run."
step "Run the smallest possible container" "A friendly message starting with Hello from Docker! Docker downloaded the image, ran it, and it printed and exited." ok 'Hello from Docker' <<'CMD'
docker run --rm hello-world
CMD
mcq "What is the difference between an image and a container?" "They are the same thing|An image is the template, a container is a running copy|A container is a file you download|An image only runs on Linux" 2 "Image = recipe or template. Container = a running instance made from it. One image can start many containers."
why "docker images::list the images stored locally" "Images are downloaded once and kept. This list shows what you have and how big each one is. Small images start faster and have less to attack."
step "List the images on your computer" "hello-world is listed with its size (tiny). Images are stored locally after the first download." ok 'hello-world' <<'CMD'
docker images
CMD
why "docker ps::list containers|-a::all, also the stopped ones" "Plain docker ps shows only running containers. Adding -a also shows the ones that exited, which is where you look when something crashed. hello-world is gone because of --rm."
step "List ALL containers, including stopped ones" "Usually nothing from hello-world: --rm told Docker to delete it after it finished. -a shows stopped containers too." <<'CMD'
docker ps -a
CMD

part "PART B · Run a real web server"
learn "Ports and background containers" "A web server keeps running, so we run it in the background with -d (detached). The server listens on port 80 INSIDE the container; -p 8088:80 publishes it as port 8088 on your computer (host:container). --name gives the container a name you can use later."
say "What does docker run -d -p 8080:80 do?" "It starts a container in the background, detached, and publishes port 80 inside the container as port 8080 on my machine. The first number is the host port and the second is the container port. I usually add --name so I can refer to it, and I check it with docker ps and docker logs."
art "-p 8088:80 : opening a door" <<'ART'
   your browser/curl                 your computer              container
   localhost:8088  ------------>  [ port 8088 ] ===> [ port 80 : nginx ]
                                   (host port)          (container port)
ART
why "docker run -d::start in the background|--name my-nginx::give it a name you can use later|-p 8088:80::open port 8088 on your computer and send it to port 80 inside|nginx:alpine::a small web server image" "A web server keeps running, so we detach it. The port flag is like opening a door: host port first, container port second. Without it, the server would be running but unreachable from your computer."
step "Start nginx in the background" "A long container id (letters and numbers). The server is now running." <<'CMD'
docker run -d --name my-nginx -p 8088:80 nginx:alpine
CMD
why "docker ps::list running containers|--filter name=my-nginx::show only the one with that name" "Confirm the container is Up and look at the PORTS column: the arrow 8088->80 is the door you opened."
step "See it running" "my-nginx with status Up and 0.0.0.0:8088->80/tcp. That arrow is the port mapping." ok 'my-nginx' <<'CMD'
docker ps --filter name=my-nginx
CMD
why "sleep 2::give it a moment to start|curl -s localhost:8088::ask the server for its home page|head -5::show only the first 5 lines" "You call your own computer on port 8088 and Docker forwards the call into the container. Seeing the Welcome to nginx page proves the port mapping works."
step "Talk to it from your computer" "The first lines of the nginx welcome page, including Welcome to nginx!" ok 'Welcome to nginx' <<'CMD'
sleep 2; curl -s localhost:8088 | head -5
CMD
predict "You run the same command again but with -p 9090:80. Which address will show the welcome page?" "localhost:80|localhost:9090|localhost:8088|container:9090" 2 "The first number is the host port (your computer). The second is the port inside the container."
why "docker logs::show what the container printed|my-nginx::which container|tail -3::the last 3 lines" "Logs are the first place to look when something is wrong. You should see the request you just made (GET / with status 200)."
step "Read its logs" "A line for your request: GET / HTTP/1.1 200. Logs are the first place to look when something is wrong." ok 'GET /' <<'CMD'
docker logs my-nginx 2>&1 | tail -3
CMD
why "docker rm -f::force-remove a container, stopping it if needed|my-nginx::the container" "Containers are disposable. Remove practice containers when you finish so they do not use memory or hold ports. This frees port 8088 again."
step "Stop and remove it" "my-nginx is printed back. rm -f stops and deletes it in one go." ok 'my-nginx' <<'CMD'
docker rm -f my-nginx
CMD

part "PART C · Build your own tiny image"
learn "The Dockerfile" "A Dockerfile is a recipe, one instruction per line. FROM picks the starting image. COPY puts your files in. CMD is the command to run when a container starts. docker build -t name folder follows the recipe and makes an image. Each instruction becomes a LAYER, and Docker re-uses layers it already built (the cache)."
say "What is a Dockerfile, and how do layers and caching work?" "A Dockerfile is the recipe for an image: FROM chooses the base, COPY adds files, RUN executes build commands and CMD sets what starts. Each instruction becomes a layer, and Docker caches layers it has already built. So I put rarely changing steps, like installing dependencies, before frequently changing ones, like copying the source code, to keep rebuilds fast."
art "A Dockerfile becomes layers" <<'ART'
   Dockerfile                        The image (stacked layers)
   FROM alpine:3.20          --->    [ layer 1: alpine Linux     ]
   COPY hello.txt /hello.txt --->    [ layer 2: your file        ]
   CMD ["cat","/hello.txt"]  --->    [ start command (metadata)  ]
ART
why "mkdir -p::create a folder (and parents), no error if it exists|echo ... > hello.txt::write a line of text into a file" "An image is built from a folder, so we make one and put a file in it. This file will be copied into your first image."
step "Make a folder with a file to package" "No output. The folder playground/first-image now has hello.txt." <<'CMD'
mkdir -p playground/first-image && echo "Hello from MY image" > playground/first-image/hello.txt
CMD
why "FROM alpine:3.20::start from a tiny Linux image (pinned version)|COPY hello.txt /hello.txt::put my file inside the image|CMD [cat, /hello.txt]::the command to run when a container starts" "A Dockerfile is a recipe with one instruction per line. These three lines are a complete image: a base, a file, and what to do on start. Pinning the version (3.20, not latest) keeps builds repeatable."
step "Write the Dockerfile (three lines)" "The three lines of the Dockerfile are printed back so you can read them." ok 'FROM alpine' <<'CMD'
printf 'FROM alpine:3.20\nCOPY hello.txt /hello.txt\nCMD ["cat", "/hello.txt"]\n' > playground/first-image/Dockerfile && cat playground/first-image/Dockerfile
CMD
why "docker build::follow the recipe and create an image|-t first:lab::give the image the name first and the tag lab|playground/first-image::the folder with the Dockerfile (the build context)" "Building turns the recipe into a reusable image. The name and tag let you refer to it later. Each instruction becomes a layer."
step "Build the image" "A line naming first:lab, the tag you gave it. Your image exists now." ok 'first:lab' <<'CMD'
docker build -t first:lab playground/first-image 2>&1 | grep 'first:lab' | tail -2
CMD
why "docker run --rm::start a container and delete it after|first:lab::your image" "Your own program, packaged. It prints the line you wrote and exits. The same image would run the same way on any computer with Docker."
step "Run your image" "Hello from MY image. Your own app, packaged." ok 'Hello from MY image' <<'CMD'
docker run --rm first:lab
CMD
why "docker history::list the layers of an image, newest first" "Every instruction in the Dockerfile became a layer. The history shows them with sizes. Docker re-uses layers it already built, which is why rebuilds are fast."
step "See its layers" "A list: your CMD, your COPY, and the alpine base. Same as the picture above." ok 'COPY' <<'CMD'
docker history first:lab
CMD

part "PART D · Package a web page"
learn "Static site in nginx" "nginx serves every file in /usr/share/nginx/html. Copy your page there and the base image's own start command (nginx) does the rest, so no CMD is needed. This is exactly how the lab's web image works."
say "How would you containerise a static website?" "I use the official nginx image as the base and copy the site files into /usr/share/nginx/html with a two-line Dockerfile. nginx already knows how to start, so I do not need a CMD. Then I build the image, run it with a published port and check it with curl. For production I would pin the image version."
art "A web page in a container" <<'ART'
   index.html  --COPY-->  /usr/share/nginx/html/   inside the nginx image
   browser --> localhost:8089 --> [ nginx container ] --> serves index.html
ART
why "index.html::a simple web page|FROM nginx:alpine::start from the nginx web server image|COPY index.html /usr/share/nginx/html/index.html::put the page where nginx serves files" "nginx serves whatever is in /usr/share/nginx/html. We only need to add our page, because the base image already knows how to start nginx. So there is no CMD line at all."
step "Create a web page and a Dockerfile" "No output. A folder with index.html and a two-line Dockerfile." <<'CMD'
mkdir -p playground/my-page && echo "<h1>My first container page</h1>" > playground/my-page/index.html && printf 'FROM nginx:alpine\nCOPY index.html /usr/share/nginx/html/index.html\n' > playground/my-page/Dockerfile
CMD
why "docker build -t my-page:lab::build an image and name it|playground/my-page::the folder to build from|grep::show only the line that mentions the name" "Same build command as before, now for a web page. We filter the long output to the one line that proves the image got its name."
step "Build it" "A line naming my-page:lab, the tag you gave it." ok 'my-page:lab' <<'CMD'
docker build -t my-page:lab playground/my-page 2>&1 | grep 'my-page:lab' | tail -2
CMD
why "-d::background|-p 8089:80::host port 8089 to container port 80|--name my-page::a name|curl localhost:8089::fetch the page" "You packaged a web page into an image and served it from a container. This is exactly how real static sites are shipped."
step "Run it on port 8089 and fetch it" "<h1>My first container page</h1>. Your page, served from a container." ok 'My first container page' <<'CMD'
docker run -d --rm --name my-page -p 8089:80 my-page:lab >/dev/null; sleep 2; curl -s localhost:8089
CMD
why "docker rm -f my-page::stop and remove the container" "Tidy up the practice container and free port 8089."
step "Clean up" "my-page is printed back." ok 'my-page' <<'CMD'
docker rm -f my-page
CMD

part "PART E · The real app images"
learn "Production images" "The lab's API and web images follow the same recipe with extra care: a MULTI-STAGE build (one stage installs and builds, the final stage copies only what is needed, so build tools never ship), a non-root user, a HEALTHCHECK, and a .dockerignore. Putting rarely changing steps first, such as copying package.json before the code, keeps rebuilds fast thanks to the layer cache."
say "What makes a Docker image production-ready?" "A small base image and a multi-stage build, so compilers and build tools are not shipped; a non-root user; pinned versions instead of latest; a HEALTHCHECK; and a .dockerignore so secrets and junk stay out. Then I scan the image for vulnerabilities in CI. Smaller, simpler images pull faster and have less attack surface."
art "Multi-stage build" <<'ART'
   stage 1: BUILD (big)                 stage 2: FINAL (small)
  +------------------------+  copy    +------------------------+
  | node + npm + compilers | -------> | node + your app only   |
  | install dependencies   |  result  | runs as normal user    |
  +------------------------+          +------------------------+
        thrown away                          this is shipped
ART
why "grep -nE::search with line numbers for several words at once|FROM, USER, HEALTHCHECK, COPY::the lines that matter most" "This is the real Dockerfile for the lab API. Two FROM lines mean a multi-stage build: one stage builds, the last stage is small and is the one that ships. USER means it runs as a normal user."
step "Look at the key lines of the API Dockerfile" "FROM lines (one per stage), COPY lines, and later USER and HEALTHCHECK." ok 'FROM' <<'CMD'
grep -nE '^(FROM|USER|HEALTHCHECK|COPY)' 02-containers/Dockerfile.api
CMD
why "-f 02-containers/Dockerfile.api::use this specific Dockerfile|-t devlab-api:lab::name the image|app/api::the folder with the source code" "Now you build the real production-style image. Multi-stage builds keep compilers and tools out of the final image, so it is smaller and safer."
step "Build the API image" "The last lines say the image was built and named devlab-api:lab." <<'CMD'
docker build -f 02-containers/Dockerfile.api -t devlab-api:lab app/api 2>&1 | tail -4
CMD
why "-f 02-containers/Dockerfile.web::the Dockerfile for the web server|.::build from the repo root, because it needs files from several folders" "The web image holds the site and the nginx settings. The final dot is the build context: Docker can only copy files from inside it."
step "Build the web image" "Built and named devlab-web:lab." <<'CMD'
docker build -f 02-containers/Dockerfile.web -t devlab-web:lab . 2>&1 | tail -4
CMD
why "--format::choose which columns to show|grep devlab::keep only this lab images" "Both images are small because of slim bases and multi-stage builds. Small images download faster and contain less that can be attacked."
step "Compare the sizes" "Both are small because they use slim bases and multi-stage builds." <<'CMD'
docker images --format '{{.Repository}}:{{.Tag}}   {{.Size}}' | grep devlab
CMD
why "--progress=plain::print every build step as plain text|grep -c CACHED::count how many steps were re-used" "Docker reuses a layer when nothing in it changed. A number above 0 proves the cache works. That is why the Dockerfile copies package.json before the source code: the slow install step stays cached."
step "Build the API image AGAIN and count cached layers" "A number above 0. Docker reuses unchanged layers, so rebuilds take seconds. That is why package.json is copied before the source code." <<'CMD'
docker build --progress=plain -f 02-containers/Dockerfile.api -t devlab-api:lab app/api 2>&1 | grep -c CACHED
CMD
quiz "Why is package.json copied BEFORE the rest of the source in the Dockerfile?" "cache|layer|rebuild|reinstall|faster" "Dependencies change rarely and code changes often. Copying package.json first lets Docker cache the slow npm install layer."

part "PART F · Run the API on its own"
learn "Running a container" "docker run starts a container from an image. -d runs it in the background, -p 5001:5000 maps host port 5001 to container port 5000, and -e sets an environment variable. A HEALTHCHECK in the Dockerfile lets Docker tell the difference between started and really working."
say "How do you run and verify a container properly?" "I run it detached with a name, a port mapping and environment variables for configuration, never secrets baked into the image. Then I verify it with the health check status, docker logs and a curl to its health endpoint. A HEALTHCHECK matters because it tells Docker the difference between started and actually working."
why "-e JWT_SECRET=...::pass a setting (an environment variable) into the container|-p 5001:5000::host port to container port|--rm -d --name lab-api::delete after, background, a name" "The app refuses to start without a secret, so we pass one in at run time. Configuration and secrets come from outside the image, never baked into it."
step "Run the API alone on port 5001" "A long container id is printed." <<'CMD'
docker rm -f lab-api >/dev/null 2>&1; docker run --rm -d --name lab-api -p 5001:5000 -e JWT_SECRET=lab-only-lab-only-lab-only-lab-only-123 -e ADMIN_PASSWORD=x devlab-api:lab
CMD
why "sleep 4::wait for the app|curl -s localhost:5001/healthz::the health page" "You should see ok true. Now the API is running alone, outside Compose, which shows what one container needs on its own."
step "Ask it for its health" '{"ok":true}' <<'CMD'
sleep 4; curl -s localhost:5001/healthz
CMD
why "docker inspect::show all details about a container|--format::pick one field|.State.Health.Status::the health status" "The Dockerfile has a HEALTHCHECK, so Docker itself can tell the difference between started and really working. You want to see healthy."
step "Docker's own health check" "healthy. The Dockerfile has a HEALTHCHECK, so Docker knows if the app is really working (not just started)." <<'CMD'
sleep 15; docker inspect lab-api --format '{{.State.Health.Status}}'
CMD
why "id::the user the container runs as|which npm::look for the npm program|or echo::if it is not found, print a message" "Running as a normal user and having no npm in the final image both reduce what an attacker can do. Fewer tools in the image means less to abuse."
step "Who runs it, and is npm inside?" "uid=1000 (not root) and a message that npm is not in the image. Fewer tools = less for an attacker to use." <<'CMD'
docker exec lab-api id; docker exec lab-api sh -c 'which npm || echo "npm is not in this image, on purpose"'
CMD
why "docker rm -f lab-api::stop and remove the container" "Clean up the practice container."
step "Stop it" "The container is removed." <<'CMD'
docker rm -f lab-api
CMD

part "PART G · Break it on purpose"
learn "Fail fast" "Good services check their configuration when they start and refuse to run if something unsafe or missing, such as a weak secret. A loud crash at startup is cheap to fix. A quietly misconfigured service in production is expensive."
say "What does fail fast mean for a service?" "The service checks its required configuration at startup, for example a missing or weak secret, and refuses to run with a clear error. A loud crash at startup is cheap to fix, while a service that quietly runs misconfigured can cause a security hole or data problems in production. And the orchestrator sees the failure immediately."
art "Fail fast vs fail quietly" <<'ART'
   FAIL FAST:    start --> secret missing? --> crash with a clear message --> fixed in minutes
   FAIL QUIETLY: start --> secret missing? --> runs anyway --> weak security found months later
ART
why "docker run --rm devlab-api:lab::start it with no JWT_SECRET setting" "It should crash on purpose with a FATAL message. Failing loudly at start is better than running with an unsafe, missing secret. This is called failing fast."
step "Start the API WITHOUT a secret" "FATAL: JWT_SECRET must be set. The app refuses to start insecurely. This is 'fail fast'." fail <<'CMD'
docker run --rm devlab-api:lab
CMD
quiz "Why is it better that the app crashes at start instead of running without a secret?" "insecure|secur|safe|silent|fail fast|weak|obvious|early" "A loud failure at startup is easy to notice and fix. Running quietly with a weak or missing secret is a hidden security hole."

part "PART H · Your turn: write your own image"
learn "Your own Dockerfile" "A tiny Dockerfile needs two things: FROM picks the base image and CMD says what to run. Write CMD in the exec form with square brackets so signals reach your program. Pin versions (alpine:3.20) instead of latest, so builds are repeatable."
say "What are best practices when writing a Dockerfile?" "Use a specific, pinned base image, write CMD in exec form so signals reach the process, copy only what is needed, order layers for caching, run as a non-root user and keep the image small. I also use multi-stage builds when there is a build step, and I lint the file with hadolint."
task "Build an image from your own Dockerfile" "Create the file playground/Dockerfile.hello with just two lines: FROM alpine:3.20  and  CMD [\"echo\", \"hello from my first image\"]  . Then build it with: docker build -f playground/Dockerfile.hello -t hello:lab playground   and run it with: docker run --rm hello:lab" "The file must be in the playground folder. The CMD must use square brackets and double quotes." <<'X'
docker build -q -f playground/Dockerfile.hello -t hello:lab playground >/dev/null && docker run --rm hello:lab | grep -qi hello
---
printf 'FROM alpine:3.20\nCMD ["echo", "hello from my first image"]\n' > playground/Dockerfile.hello
X
quiz "Name two reasons the images in this lab run as a normal user instead of root." "attack|hack|damage|privile|install|write|limit|least" "If the process is hacked it has few rights: it cannot change system files or install tools (least privilege)."

deeper "Docker Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/Docker-Zero-to-Hero" "Containerise a Flask app: two-tier-flask-app (Shubham Londhe)|https://github.com/LondheShubham153/two-tier-flask-app"
explain "Done! Next: bash lab.sh 03"
