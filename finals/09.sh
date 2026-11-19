# Module 09 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Hunt the leaked secret" "Interviewer: 'A teammate saved a GitHub token in playground/leaky/config.txt. Find it with the secret scanner (gitleaks, scanning the folder without git history), then REMOVE the secret from the file but keep the rest of the file. The scanner must come back clean.'" "docker run --rm -v \"\$PWD/playground/leaky:/src\" zricethezav/gitleaks:latest detect --no-git --source /src --no-banner   shows the finding. Delete just that line, for example with sed -i '/ghp_/d' playground/leaky/config.txt" <<'X'
rm -rf playground/leaky; mkdir -p playground/leaky; printf 'app=devlab\ngithub_token=%s%s\nport=5000\n' ghp_ 1234567890abcdefghijklmnopqrstuvwxyz > playground/leaky/config.txt
---
grep -q 'port=5000' playground/leaky/config.txt && docker run --rm -v "$PWD/playground/leaky:/src" zricethezav/gitleaks:latest detect --no-git --source /src --no-banner >/dev/null 2>&1
---
sed -i '/ghp_/d' playground/leaky/config.txt
X

interview "Fix the Dockerfile" "Interviewer: 'The Dockerfile playground/bad.Dockerfile is unsafe: it uses the moving tag latest, copies with ADD, and runs as root. Rewrite it so the linter (hadolint) is happy: pin a version, use COPY, run as a non-root user.'" "Use FROM node:24-slim , COPY instead of ADD, and USER 1000:1000 before CMD. Lint:  docker run --rm -i hadolint/hadolint < playground/bad.Dockerfile" <<'X'
printf 'FROM node:latest\nADD . /app\nWORKDIR /app\nCMD ["node", "server.js"]\n' > playground/bad.Dockerfile
---
! grep -q ':latest' playground/bad.Dockerfile && ! grep -q '^ADD' playground/bad.Dockerfile && grep -q '^USER' playground/bad.Dockerfile && docker run --rm -i hadolint/hadolint < playground/bad.Dockerfile >/dev/null 2>&1
---
printf 'FROM node:24-slim\nWORKDIR /app\nCOPY . /app\nUSER 1000:1000\nCMD ["node", "server.js"]\n' > playground/bad.Dockerfile
X

part "PART · MODULE FINAL"

final "Scan the image" "Exam 1 of 3. Scan the web image devlab-web:lab for HIGH and CRITICAL vulnerabilities that already have a fix (trivy) and save the result into playground/trivy.txt. It must show Total: 0." "docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v \"\$PWD/.trivyignore:/.trivyignore:ro\" aquasec/trivy:0.58.0 image --severity HIGH,CRITICAL --ignore-unfixed --quiet devlab-web:lab > playground/trivy.txt   (the extra -v line hands Trivy the lab time-boxed exception file, see .trivyignore)" <<'X'
docker image inspect devlab-web:lab >/dev/null 2>&1 || dc build >/dev/null 2>&1; rm -f playground/trivy.txt
---
grep -q 'Total: 0' playground/trivy.txt
---
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v "$PWD/.trivyignore:/.trivyignore:ro" aquasec/trivy:0.58.0 image --severity HIGH,CRITICAL --ignore-unfixed --quiet devlab-web:lab 2>&1 | sed 's/\x1b\[[0-9;]*m//g' > playground/trivy.txt
X

final "Fix a risky cloud config" "Exam 2 of 3. The Terraform file playground/risky-s3/main.tf creates a storage bucket without a public access block. Make the Checkov check CKV2_AWS_6 pass by adding an aws_s3_bucket_public_access_block that turns all four protections on." "Resource aws_s3_bucket_public_access_block with bucket = aws_s3_bucket.data.id and block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets all true." <<'X'
rm -rf playground/risky-s3; mkdir -p playground/risky-s3; printf 'resource "aws_s3_bucket" "data" {\n  bucket = "exam-risky"\n}\n' > playground/risky-s3/main.tf
---
docker run --rm -v "$PWD:/tf:ro" bridgecrew/checkov:latest -d /tf/playground/risky-s3 --framework terraform --quiet --check CKV2_AWS_6 >/dev/null 2>&1
---
printf 'resource "aws_s3_bucket_public_access_block" "data" {\n  bucket                  = aws_s3_bucket.data.id\n  block_public_acls       = true\n  block_public_policy     = true\n  ignore_public_acls      = true\n  restrict_public_buckets = true\n}\n' >> playground/risky-s3/main.tf
X

final "Pass the whole gate" "Exam 3 of 3. Run the complete security gate (bash 09-security/scan.sh). Save its LAST line into playground/gate.txt. It must say ALL GATES PASSED. (It takes a few minutes.)" "bash 09-security/scan.sh 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -1 > playground/gate.txt" <<'X'
rm -f playground/gate.txt
---
grep -q 'ALL GATES PASSED' playground/gate.txt
---
bash 09-security/scan.sh 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -1 > playground/gate.txt
X
