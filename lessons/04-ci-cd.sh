# CI/CD: automatic checks with GitHub Actions (about 2h)
title "Module 04 · CI/CD"
explain "CI/CD means every change is automatically tested, scanned and built, so mistakes are caught in minutes instead of in production. GitHub runs these 'workflows' from YAML files. Here you will check and run the same steps on your own computer."

part "PART A · Read the pipeline"
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

explain "To use these for real on GitHub: copy 04-ci-cd/workflows/ci.yml to .github/workflows/ci.yml, commit and push. Next: bash lab.sh 05"
