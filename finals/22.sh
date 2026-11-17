# Module 22 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Is the pipeline green?" "Interviewer: 'Do not tell me it works: show me. Ask GitHub for the latest FINISHED run of the CI workflow on this repository and save its conclusion (one word) into playground/ci.txt. I will compare it with what GitHub says.'" "ghget '/actions/workflows/ci.yml/runs?status=completed&per_page=1' | grep -m1 '\"conclusion\"'   shows the conclusion. Keep just the word." <<'X'
rm -f playground/ci.txt
---
[ -n "$(tr -d '[:space:]' < playground/ci.txt)" ] && [ "$(tr -d '[:space:]' < playground/ci.txt)" = "$(ghget '/actions/workflows/ci.yml/runs?status=completed&per_page=1' | grep -m1 '"conclusion"' | sed -E 's/.*: "([a-z_]+)".*/\1/')" ]
---
ghget '/actions/workflows/ci.yml/runs?status=completed&per_page=1' | grep -m1 '"conclusion"' | sed -E 's/.*: "([a-z_]+)".*/\1/' > playground/ci.txt
X

interview "Which jobs run?" "Interviewer: 'Name the jobs the CI pipeline runs. Save the names of all jobs of the latest finished run into playground/jobs.txt, one per line.'" "ghjobs prints  name: <job>  lines; keep those lines." <<'X'
rm -f playground/jobs.txt
---
for j in app docker security infra; do grep -q "$j" playground/jobs.txt || exit 1; done
---
ghjobs | grep '^name:' > playground/jobs.txt
X

part "PART · MODULE FINAL"

final "A build matrix" "Exam 1 of 3. Write playground/exam-matrix.yml: a GitHub Actions workflow that runs on push and tests on TWO Node versions (20 and 22) using a build matrix, then prints the node version. It must pass the workflow linter." "Under the job add  strategy: matrix: node: [20, 22]  and use  node-version: \${{ matrix.node }}  in actions/setup-node@v4. Lint with the actionlint docker command from module 04." <<'X'
rm -f playground/exam-matrix.yml
---
[ -f playground/exam-matrix.yml ] && grep -q 'matrix' playground/exam-matrix.yml && grep -q '20' playground/exam-matrix.yml && grep -q '22' playground/exam-matrix.yml && docker run --rm -v "$PWD/playground:/w" -w /w rhysd/actionlint:latest -color=false /w/exam-matrix.yml
---
printf 'name: matrix\non: [push]\npermissions:\n  contents: read\njobs:\n  test:\n    runs-on: ubuntu-latest\n    strategy:\n      matrix:\n        node: [20, 22]\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-node@v4\n        with:\n          node-version: ${{ matrix.node }}\n      - run: node --version\n' > playground/exam-matrix.yml
X

final "Automate dependency updates" "Exam 2 of 3. Write playground/exam-dependabot.yml: a Dependabot configuration (version 2) that checks the npm packages in /app/api and the GitHub Actions in / every week." "Copy the shape of .github/dependabot.yml: version, updates, package-ecosystem, directory, schedule interval weekly." <<'X'
rm -f playground/exam-dependabot.yml
---
f=playground/exam-dependabot.yml; [ -f $f ] && grep -q 'version: 2' $f && grep -q 'package-ecosystem: npm' $f && grep -q '/app/api' $f && grep -q 'github-actions' $f && grep -q 'weekly' $f
---
printf 'version: 2\nupdates:\n  - package-ecosystem: npm\n    directory: "/app/api"\n    schedule:\n      interval: weekly\n  - package-ecosystem: github-actions\n    directory: "/"\n    schedule:\n      interval: weekly\n' > playground/exam-dependabot.yml
X

final "Prove the deployment code is safe" "Exam 3 of 3. Without touching any cloud account, prove the deployment code in 22-ship/aws-deploy is valid AND secure. Save the Terraform validation result into playground/deploy-validate.txt (it must say valid) and the Checkov summary into playground/deploy-scan.txt (it must show 0 failed checks)." "Use the two commands from module 22, part D (terraform validate through docker, and checkov through docker) and redirect their output into the two files." <<'X'
rm -f playground/deploy-validate.txt playground/deploy-scan.txt
---
grep -qi 'valid' playground/deploy-validate.txt && grep -q 'Failed checks: 0' playground/deploy-scan.txt
---
docker run --rm --entrypoint sh -v "$PWD:/w" -w /w/22-ship/aws-deploy hashicorp/terraform:1.9 -c "terraform init -backend=false >/dev/null 2>&1 && terraform validate" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' > playground/deploy-validate.txt; docker run --rm -v "$PWD:/tf:ro" bridgecrew/checkov:latest -d /tf/22-ship/aws-deploy --framework terraform --compact --quiet > playground/deploy-scan.txt 2>&1; rm -rf 22-ship/aws-deploy/.terraform 22-ship/aws-deploy/.terraform.lock.hcl
X
