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
step "List the jobs in the CI workflow" "Jobs: app, docker, security, infra. Each is a group of steps that can run in parallel." <<'CMD'
grep -nE "^  [a-z]+:$" 04-ci-cd/workflows/ci.yml
CMD
step "Lint both workflow files (like a spell-checker for YAML)" "workflows are valid. No errors printed." <<'CMD'
docker run --rm -v "$PWD/04-ci-cd/workflows:/w" -w /w rhysd/actionlint:latest -color=false /w/ci.yml /w/release.yml && echo "workflows are valid"
CMD
step "See the least-privilege setting" "permissions: contents: read. The pipeline's token can only READ the code by default." <<'CMD'
grep -n -A1 "^permissions" 04-ci-cd/workflows/ci.yml
CMD

part "PART B · Run the CI steps locally"
learn "Reproducible builds" "npm ci installs exactly the versions in the lock file, so CI and your laptop agree. The pipeline then runs the tests and a vulnerability audit on every change. If anything fails, the change is blocked before it reaches production."
say "How do you make builds reproducible?" "I commit lock files and install with npm ci, so CI uses exactly the same dependency versions as my machine. I pin base images and actions, ideally to a digest or commit SHA, and I avoid latest tags. That way a build that passes today produces the same result tomorrow, and a supply-chain surprise cannot sneak in."
step "Install the API's dependencies exactly as locked" "added N packages. 'npm ci' is the strict, reproducible install CI uses." <<'CMD'
cd app/api && npm ci --silent && echo "dependencies installed"
CMD
step "Run the automated tests" "4 tests, all passing (health, auth, leads, rate limit)." <<'CMD'
cd app/api && npm test 2>&1 | grep -E "^# (tests|pass|fail)|✔|✖"
CMD
step "Check dependencies for known vulnerabilities" "found 0 vulnerabilities. CI fails the build if a HIGH one appears." <<'CMD'
cd app/api && npm audit --omit=dev --audit-level=high
CMD
quiz "Why does the pipeline give the token only 'contents: read' permission?" "least|privilege|minimal|only|damage|compromis|limit|secur" "Least privilege: if a step is compromised it can only read code, not push, publish or delete."

part "PART C · Hands-on: write your own workflow"
learn "Anatomy of a workflow" "name is a label, on says what triggers it, permissions limits what the pipeline token may do, jobs holds the work, runs-on picks the machine, and steps are the commands. A step either reuses a ready-made action (uses) or runs a shell command (run). The linter catches typos before you push."
say "Walk me through a GitHub Actions workflow." "A workflow is a YAML file in .github/workflows. The on key says what triggers it, like a push or pull request. Jobs run on runners, and each job has steps that use actions or run commands. I give it the minimum permissions, pin actions to a commit SHA, and use secrets for credentials. A failing step fails the job and blocks the merge."
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
step "Read the Jenkinsfile that mirrors this lab's CI" "pipeline, agent, stages: Install, Test, Audit, Build image, and a post section." ok 'pipeline' <<'CMD'
cat 04-ci-cd/Jenkinsfile
CMD
mcq "What do you have to do with Jenkins that you do not with GitHub Actions?" "Run and maintain the server yourself (updates, plugins, backups)|Write the pipeline in YAML|Pay per minute|Use Git" 1 "Jenkins is self-hosted: that gives control and flexibility, and also work and responsibility."
step "Start a real Jenkins server (first time downloads about 500 MB)" "A long container id. Jenkins is starting." <<'CMD'
docker rm -f lab-jenkins >/dev/null 2>&1; docker run -d --name lab-jenkins -p 8085:8080 jenkins/jenkins:lts-jdk21
CMD
step "Wait until it says it is up (about a minute)" "Jenkins is fully up and running." ok 'fully up and running' <<'CMD'
for i in $(seq 1 80); do docker logs lab-jenkins 2>&1 | grep -q "fully up and running" && break; sleep 3; done; docker logs lab-jenkins 2>&1 | grep "fully up and running"
CMD
step "A new Jenkins generates a one-time admin password" "password length: 32. On first login you paste it into the Unlock Jenkins page." ok 'length: 32' <<'CMD'
echo "password length: $(docker exec lab-jenkins cat /var/jenkins_home/secrets/initialAdminPassword | tr -d '\r\n' | wc -c)"
CMD
step "Ask its web port for the login page" "HTTP 200 or 403: the server answers on port 8085. Open http://localhost:8085 in a browser to see the Unlock Jenkins screen." ok 'HTTP (200|403)' <<'CMD'
curl -s -m 8 -w '\nHTTP %{http_code}\n' localhost:8085/login | tail -1
CMD
task "Write a Jenkinsfile" "Create playground/Jenkinsfile with a declarative pipeline: it must start with  pipeline {  , use  agent any  , and have a stage called Test that runs  sh 'npm test'  . Use  edit playground/Jenkinsfile  . (Jenkins checks the syntax when it runs, and this fresh server has no pipeline plugins yet, so this lab checks the structure.)" "Look at 04-ci-cd/Jenkinsfile for the shape: pipeline { agent any  stages { stage('Test') { steps { sh 'npm test' } } } }" <<'X'
grep -q 'pipeline *{' playground/Jenkinsfile 2>/dev/null && grep -q 'agent' playground/Jenkinsfile && grep -q "stage('Test')\|stage(\"Test\")" playground/Jenkinsfile && grep -q "sh .npm test" playground/Jenkinsfile
---
printf "pipeline {\n  agent any\n  stages {\n    stage('Test') { steps { sh 'npm test' } }\n  }\n}\n" > playground/Jenkinsfile
X
step "Stop Jenkins" "lab-jenkins removed." ok 'lab-jenkins' <<'CMD'
docker rm -f lab-jenkins
CMD
quiz "Name one reason a company might choose Jenkins and one reason it might choose GitHub Actions." "plugin|control|self|host|on-prem|flexib|maintain|server|yaml|integrat|simple|managed|no server|marketplace" "Jenkins: full control, self-hosting, a huge plugin library, works with any source system. Actions: nothing to maintain, tight GitHub integration, quick to start."

deeper "GitHub Actions Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/GitHub-Actions-Zero-to-Hero" "node-todo-cicd (Shubham Londhe)|https://github.com/LondheShubham153/node-todo-cicd" "Jenkins Zero to Hero, a second CI tool (Abhishek Veeramalla)|https://github.com/iam-veeramalla/Jenkins-Zero-To-Hero"
explain "To use these for real on GitHub: copy 04-ci-cd/workflows/ci.yml to .github/workflows/ci.yml, commit and push. Next: bash lab.sh 05"
