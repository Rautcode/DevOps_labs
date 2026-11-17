# Module 04 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Write a pipeline" "Interviewer: 'Write a minimal GitHub Actions workflow at playground/exam-ci.yml: it runs on every push, has one job on ubuntu-latest that checks out the code and runs  npm test  inside app/api. It has to pass the workflow linter.'" "Look at 04-ci-cd/workflows/ci.yml for the shape: name, on, permissions, jobs, runs-on, steps (uses: actions/checkout@v4, then run: with working-directory: app/api)." <<'X'
rm -f playground/exam-ci.yml
---
[ -f playground/exam-ci.yml ] && grep -q "npm test" playground/exam-ci.yml && docker run --rm -v "$PWD/playground:/w" -w /w rhysd/actionlint:latest -color=false /w/exam-ci.yml
---
printf 'name: exam\non: [push]\npermissions:\n  contents: read\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - run: npm ci && npm test\n        working-directory: app/api\n' > playground/exam-ci.yml
X

interview "Spot the dangerous workflow" "Interviewer: 'This workflow (playground/insecure.yml) was written by a colleague. Its pipeline token has full write access to the repository. Fix it with least privilege (read-only access to the code) and keep the file valid.'" "Replace  permissions: write-all  with  permissions:  then an indented  contents: read  . Check validity with the actionlint docker command from lesson 04." <<'X'
printf 'name: insecure\non: [push]\npermissions: write-all\njobs:\n  x:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo hi\n' > playground/insecure.yml
---
! grep -q 'write-all' playground/insecure.yml && grep -q 'contents: read' playground/insecure.yml && docker run --rm -v "$PWD/playground:/w" -w /w rhysd/actionlint:latest -color=false /w/insecure.yml
---
sed -i 's/permissions: write-all/permissions:\n  contents: read/' playground/insecure.yml
X

part "PART · MODULE FINAL"

final "Run the tests like CI" "Exam 1 of 3. Run the API test suite the way CI does and save the number of passing tests into playground/tests.txt (just the number)." "cd app/api && npm ci && npm test  prints a line like  ℹ pass 5  . The number is what I want." <<'X'
(cd app/api && npm ci --silent >/dev/null 2>&1); rm -f playground/tests.txt
---
n=$(cd app/api && npm test 2>&1 | grep -oE 'pass [0-9]+' | head -1 | grep -oE '[0-9]+'); [ -n "$n" ] && [ "$(tr -d '[:space:]' < playground/tests.txt)" = "$n" ]
---
(cd app/api && npm test 2>&1 | grep -oE 'pass [0-9]+' | head -1 | grep -oE '[0-9]+') > playground/tests.txt
X

final "Dependency audit" "Exam 2 of 3. CI must fail on serious vulnerabilities. Run the dependency audit for the API (production dependencies only) and save its output into playground/audit.txt. It has to show that there are 0 vulnerabilities." "cd app/api && npm audit --omit=dev > ../../playground/audit.txt" <<'X'
rm -f playground/audit.txt
---
grep -q "found 0 vulnerabilities" playground/audit.txt
---
(cd app/api && npm audit --omit=dev) > playground/audit.txt 2>&1; true
X

final "Tag a release" "Exam 3 of 3. The release workflow starts when a version tag is pushed. Create a LOCAL git tag named v0.0.0-exam on the current commit (do not push it)." "git tag <name>" <<'X'
git tag -d v0.0.0-exam >/dev/null 2>&1
---
git tag -l v0.0.0-exam | grep -q v0.0.0-exam
---
git tag v0.0.0-exam
---
git tag -d v0.0.0-exam >/dev/null 2>&1
X
