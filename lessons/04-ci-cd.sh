# CI/CD: automatic checks with GitHub Actions (about 2h)
title "Module 04 · CI/CD"
mission "A teammate pushed a change that broke the build, and nobody noticed for two days. Your mission: make GitHub test, scan and build every change automatically, so a broken change is caught in minutes, before it reaches anyone."
explain "CI/CD means every change is automatically tested, scanned and built, so mistakes are caught in minutes instead of in production. GitHub runs these 'workflows' from YAML files. Here you will check and run the same steps on your own computer."

part "PART A · Read the pipeline"
learn "What CI/CD means" "CI (continuous integration) means every change is automatically built and tested. CD (continuous delivery) means passing changes are automatically released. A GitHub Actions workflow lives in .github/workflows and has jobs; each job runs steps on a fresh machine, so results never depend on one person's laptop."
say "What is CI/CD?" "Continuous integration means every change is automatically built, tested and scanned, so problems are caught within minutes. Continuous delivery or deployment extends that: a passing change is packaged and can be released automatically. The result is small, frequent, low-risk releases instead of big risky ones. In my project, every pull request runs tests, a dependency audit and an image build."
art "The CI/CD flow" <<'ART'
   you push code
        |
        v
   [ test ] -> [ scan ] -> [ build image ] -> [ deploy ]
      fail anywhere = stop, you are told in minutes
ART
mcq "What is the main benefit of CI?" "Mistakes are caught minutes after the change, not weeks later|It makes the code faster|It removes the need for tests|It replaces Git" 1 "CI runs the checks on every change automatically so broken code is found while it is still small."
why "grep -nE::search with line numbers using a pattern|04-ci-cd/workflows/ci.yml::the CI workflow file" "A workflow file is a list of jobs. This prints their names, so you can see what the pipeline does on every change without reading the whole file."
step "List the jobs in the CI workflow" "Jobs: app, docker, security, infra. Each is a group of steps that can run in parallel." <<'CMD'
grep -nE "^  [a-z]+:$" 04-ci-cd/workflows/ci.yml
CMD
why "docker run --rm::run a tool in a throwaway container|rhysd/actionlint::a checker for GitHub Actions files|ci.yml release.yml::the two files to check" "A typo in a workflow only shows up after you push and wait. A linter catches mistakes in seconds, on your own computer, before anything runs on GitHub."
step "Lint both workflow files (like a spell-checker for YAML)" "workflows are valid. No errors printed." <<'CMD'
docker run --rm -v "$PWD/04-ci-cd/workflows:/w" -w /w rhysd/actionlint:latest -color=false /w/ci.yml /w/release.yml && echo "workflows are valid"
CMD
why "grep -n -A1 ^permissions::find the permissions line and show the line after it" "The workflow only gets read access to the code. Giving a pipeline the smallest rights it needs (least privilege) limits the damage if it is ever abused."
step "See the least-privilege setting" "permissions: contents: read. The pipeline's token can only READ the code by default." <<'CMD'
grep -n -A1 "^permissions" 04-ci-cd/workflows/ci.yml
CMD

part "PART B · Run the CI steps locally"
learn "Reproducible builds" "npm ci installs exactly the versions in the lock file, so CI and your laptop agree. The pipeline then runs the tests and a vulnerability audit on every change. If anything fails, the change is blocked before it reaches production."
say "How do you make builds reproducible?" "I commit lock files and install with npm ci, so CI uses exactly the same dependency versions as my machine. I pin base images and actions, ideally to a digest or commit SHA, and I avoid latest tags. That way a build that passes today produces the same result tomorrow, and a supply-chain surprise cannot sneak in."
art "Why lock files matter" <<'ART'
   package.json   "express": "^4.0.0"     = any 4.x   (could change tomorrow)
   package-lock   "express": "4.19.2"     = this exact version
   npm install -> may differ per day        npm ci -> identical everywhere (laptop = CI)
ART
why "npm ci::install exactly the versions in the lock file|--silent::hide the noisy output" "npm ci is different from npm install: it never changes the lock file and fails if it does not match. That makes the build reproducible, so CI and your laptop use identical versions."
step "Install the API's dependencies exactly as locked" "added N packages. 'npm ci' is the strict, reproducible install CI uses." <<'CMD'
cd app/api && npm ci --silent && echo "dependencies installed"
CMD
why "npm test::run the test suite|grep -E::keep only the summary lines" "Tests are the main safety net in CI. A pull request with failing tests is blocked, so a broken change never reaches the main branch."
step "Run the automated tests" "4 tests, all passing (health, auth, leads, rate limit)." <<'CMD'
cd app/api && npm test 2>&1 | grep -E "^# (tests|pass|fail)|✔|✖"
CMD
why "npm audit::compare every library with a database of known problems|--omit=dev::skip tools that are not shipped|--audit-level=high::fail only for high or critical issues" "Every library you add brings its own bugs. Checking them in CI means you hear about a dangerous one on the day it is published, not after an attack."
step "Check dependencies for known vulnerabilities" "found 0 vulnerabilities. CI fails the build if a HIGH one appears." <<'CMD'
cd app/api && npm audit --omit=dev --audit-level=high
CMD
quiz "Why does the pipeline give the token only 'contents: read' permission?" "least|privilege|minimal|only|damage|compromis|limit|secur" "Least privilege: if a step is compromised it can only read code, not push, publish or delete."

part "PART C · Hands-on: write your own workflow"
learn "Anatomy of a workflow" "name is a label, on says what triggers it, permissions limits what the pipeline token may do, jobs holds the work, runs-on picks the machine, and steps are the commands. A step either reuses a ready-made action (uses) or runs a shell command (run). The linter catches typos before you push."
say "Walk me through a GitHub Actions workflow." "A workflow is a YAML file in .github/workflows. The on key says what triggers it, like a push or pull request. Jobs run on runners, and each job has steps that use actions or run commands. I give it the minimum permissions, pin actions to a commit SHA, and use secrets for credentials. A failing step fails the job and blocks the merge."
art "A GitHub Actions workflow" <<'ART'
   name: CI                        a label
   on: [push, pull_request]        WHEN to run
   permissions: contents: read     the least access it needs
   jobs:
     test:                         a job (runs on its own runner)
       steps:                      the steps, in order
         - uses: actions/checkout@SHA        reuse an action (pinned)
         - run: npm test                     run a command
ART
task "Write a valid workflow" "Create playground/hello.yml. It needs: name: hello  /  on: [push]  /  permissions: contents: read  /  one job called hello that runs-on: ubuntu-latest and has one step: run: echo hello. Then lint it: docker run --rm -v \"\$PWD/playground:/w\" -w /w rhysd/actionlint:latest -color=false /w/hello.yml" "Indent with 2 spaces. Steps start with a dash:  - run: echo hello" <<'X'
docker run --rm -v "$PWD/playground:/w" -w /w rhysd/actionlint:latest -color=false /w/hello.yml
---
printf 'name: hello\non: [push]\npermissions:\n  contents: read\njobs:\n  hello:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo hello\n' > playground/hello.yml
X
task "Break it on purpose and watch the linter catch it" "Copy hello.yml to playground/broken.yml and change 'runs-on' to 'runs_on' (a typo). Lint it. The linter should report an error." "The check passes only if broken.yml exists AND the linter finds a problem in it." <<'X'
[ -f playground/broken.yml ] && ! docker run --rm -v "$PWD/playground:/w" -w /w rhysd/actionlint:latest -color=false /w/broken.yml
---
sed 's/runs-on/runs_on/' playground/hello.yml > playground/broken.yml
X
quiz "Why sign release images (the release workflow uses cosign)?" "who|built|trust|tamper|verify|supply|origin|prove|authentic" "A signature proves who built the image and that nobody changed it afterwards (supply-chain security)."

part "PART D · Jenkins, side by side"
learn "Jenkins and GitHub Actions" "Jenkins is the long-established, self-hosted CI server: you run it yourself, pipelines are written in a Jenkinsfile (Groovy), and its power comes from thousands of plugins. GitHub Actions is hosted next to your code, with workflows in YAML and a marketplace of actions. Both do the same job: run stages on every change. Many companies still run Jenkins, so interviewers ask about both. The vocabulary maps closely: a Jenkins stage is like an Actions job, an agent is a runner, a plugin is an action, credentials are secrets."
say "How does Jenkins compare with GitHub Actions?" "Both run pipeline stages on every change. Jenkins is self-hosted and very flexible, with a huge plugin ecosystem and a Jenkinsfile, but I have to maintain the server, plugins and security. GitHub Actions is hosted next to the code, written in YAML, and needs no server. I would choose Actions for simplicity, and Jenkins when a company already runs it or needs heavy customisation."
art "The same pipeline in two tools" <<'ART'
   GitHub Actions (YAML)              Jenkins (Jenkinsfile)
   on: push                           triggers / webhook
   jobs: test: runs-on: ubuntu        pipeline { agent any
   steps: - run: npm test               stages { stage('Test') { steps { sh 'npm test' } } } }
   secrets.X                          credentials('X')
   hosted by GitHub                   hosted by YOU (patching, backups, plugins)
ART
why "cat::print a file|Jenkinsfile::the same pipeline written for Jenkins" "You are comparing two tools that do the same job. Look for the matching words: a Jenkins stage is like an Actions job, and sh is like run."
step "Read the Jenkinsfile that mirrors this lab's CI" "pipeline, agent, stages: Install, Test, Audit, Build image, and a post section." ok 'pipeline' <<'CMD'
cat 04-ci-cd/Jenkinsfile
CMD
mcq "What do you have to do with Jenkins that you do not with GitHub Actions?" "Run and maintain the server yourself (updates, plugins, backups)|Write the pipeline in YAML|Pay per minute|Use Git" 1 "Jenkins is self-hosted: that gives control and flexibility, and also work and responsibility."
why "docker run -d::start in the background|--name lab-jenkins::a name|-p 8085:8080::open port 8085 for it|jenkins/jenkins:lts-jdk21::the official long-term-support image" "Jenkins is something you host yourself, so we really run one. The first start downloads a big image, which is the price of self-hosting."
step "Start a real Jenkins server (first time downloads about 500 MB)" "A long container id. Jenkins is starting." <<'CMD'
docker rm -f lab-jenkins >/dev/null 2>&1; docker run -d --name lab-jenkins -p 8085:8080 jenkins/jenkins:lts-jdk21
CMD
why "for ...; do ...; done::keep checking until a condition is true|docker logs::read what Jenkins printed|grep -q::look for the words fully up and running" "Servers take time to start. Instead of guessing a delay, a script polls the logs for the ready message. This pattern is common in automation."
step "Wait until it says it is up (about a minute)" "Jenkins is fully up and running." ok 'fully up and running' <<'CMD'
for i in $(seq 1 80); do docker logs lab-jenkins 2>&1 | grep -q "fully up and running" && break; sleep 3; done; docker logs lab-jenkins 2>&1 | grep "fully up and running"
CMD
why "docker exec::run a command inside the container|cat ...initialAdminPassword::read the generated password|wc -c::count its characters" "A fresh Jenkins locks itself and gives a secret password for the first login. We only print its length, because passwords should not be shown on screen."
step "A new Jenkins generates a one-time admin password" "password length: 32. On first login you paste it into the Unlock Jenkins page." ok 'length: 32' <<'CMD'
echo "password length: $(docker exec lab-jenkins cat /var/jenkins_home/secrets/initialAdminPassword | tr -d '\r\n' | wc -c)"
CMD
why "curl -s -m 8::fetch a page quietly, give up after 8 seconds|-w HTTP code::print the status|localhost:8085/login::the login page" "A status of 200 or 403 proves the server answers on its port. Open http://localhost:8085 in a browser to see the Unlock Jenkins screen."
step "Ask its web port for the login page" "HTTP 200 or 403: the server answers on port 8085. Open http://localhost:8085 in a browser to see the Unlock Jenkins screen." ok 'HTTP (200|403)' <<'CMD'
curl -s -m 8 -w '\nHTTP %{http_code}\n' localhost:8085/login | tail -1
CMD
task "Write a Jenkinsfile" "Create playground/Jenkinsfile with a declarative pipeline: it must start with  pipeline {  , use  agent any  , and have a stage called Test that runs  sh 'npm test'  . Use  edit playground/Jenkinsfile  . (Jenkins checks the syntax when it runs, and this fresh server has no pipeline plugins yet, so this lab checks the structure.)" "Look at 04-ci-cd/Jenkinsfile for the shape: pipeline { agent any  stages { stage('Test') { steps { sh 'npm test' } } } }" <<'X'
grep -q 'pipeline *{' playground/Jenkinsfile 2>/dev/null && grep -q 'agent' playground/Jenkinsfile && grep -q "stage('Test')\|stage(\"Test\")" playground/Jenkinsfile && grep -q "sh .npm test" playground/Jenkinsfile
---
printf "pipeline {\n  agent any\n  stages {\n    stage('Test') { steps { sh 'npm test' } }\n  }\n}\n" > playground/Jenkinsfile
X
why "docker rm -f lab-jenkins::stop and remove the container" "Free the memory and the port. A self-hosted server costs resources while it runs, which is part of why many teams prefer hosted CI."
step "Stop Jenkins" "lab-jenkins removed." ok 'lab-jenkins' <<'CMD'
docker rm -f lab-jenkins
CMD
quiz "Name one reason a company might choose Jenkins and one reason it might choose GitHub Actions." "plugin|control|self|host|on-prem|flexib|maintain|server|yaml|integrat|simple|managed|no server|marketplace" "Jenkins: full control, self-hosting, a huge plugin library, works with any source system. Actions: nothing to maintain, tight GitHub integration, quick to start."

deeper "GitHub Actions Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/GitHub-Actions-Zero-to-Hero" "node-todo-cicd (Shubham Londhe)|https://github.com/LondheShubham153/node-todo-cicd" "Jenkins Zero to Hero, a second CI tool (Abhishek Veeramalla)|https://github.com/iam-veeramalla/Jenkins-Zero-To-Hero"
explain "To use these for real on GitHub: copy 04-ci-cd/workflows/ci.yml to .github/workflows/ci.yml, commit and push. Next: bash lab.sh 05"
