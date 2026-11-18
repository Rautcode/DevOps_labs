# CI/CD: automatic checks with GitHub Actions (about 2h)
title "Module 04 · CI/CD"
mission "A teammate pushed a change that broke the build, and nobody noticed for two days. Your mission: make GitHub test, scan and build every change automatically, so a broken change is caught in minutes, before it reaches anyone."
explain "CI/CD means every change is automatically tested, scanned and built, so mistakes are caught in minutes instead of in production. GitHub runs these 'workflows' from YAML files. Here you will check and run the same steps on your own computer."

part "PART A · Read the pipeline"
learn "What CI/CD means" "CI (continuous integration) means every change is automatically built and tested. CD (continuous delivery) means passing changes are automatically released. A GitHub Actions workflow lives in .github/workflows and has jobs; each job runs steps on a fresh machine, so results never depend on one person's laptop."
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

deeper "GitHub Actions Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/GitHub-Actions-Zero-to-Hero" "node-todo-cicd (Shubham Londhe)|https://github.com/LondheShubham153/node-todo-cicd" "Jenkins Zero to Hero, a second CI tool (Abhishek Veeramalla)|https://github.com/iam-veeramalla/Jenkins-Zero-To-Hero"
explain "To use these for real on GitHub: copy 04-ci-cd/workflows/ci.yml to .github/workflows/ci.yml, commit and push. Next: bash lab.sh 05"
