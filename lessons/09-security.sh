# DevSecOps: scan for security problems automatically (about 2h)
title "Module 09 · DevSecOps"
explain "Security checks should run automatically, early and often. Five scanners look at your secrets, Dockerfiles, container images, Terraform and Kubernetes files. You will run them all, then break one on purpose to see it fail."

part "PART A · Run the security gate"
step "Make sure both images exist" "devlab-api:lab and devlab-web:lab are listed." <<'CMD'
docker image inspect devlab-api:lab devlab-web:lab >/dev/null 2>&1 || dc build 2>&1 | tail -2; docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab
CMD
step "Scan for leaked secrets in git history (gitleaks)" "'no leaks found'. A leaked key in git history stays there forever, even if you delete it later." <<'CMD'
docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:latest detect --source /repo --no-banner --redact 2>&1 | tail -3
CMD
step "Lint the Dockerfiles (hadolint)" "No output = no problems." <<'CMD'
docker run --rm -i hadolint/hadolint < 02-containers/Dockerfile.api && docker run --rm -i hadolint/hadolint < 02-containers/Dockerfile.web && echo "Dockerfiles are clean"
CMD
step "Run the whole gate (all 5 scanners, takes a few minutes the first time)" "ALL GATES PASSED. Trivy: 0 HIGH/CRITICAL. Checkov and kubeconform: no failures." <<'CMD'
bash 09-security/scan.sh 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "==|no leaks|Total:|Valid:|PASSED|FAILED"
CMD
quiz "Why scan for secrets in git history, not only in the current files?" "history|forever|deleted|still|old|commit|remain" "Anything ever committed stays in history and can be recovered. A leaked key must be rotated (replaced), not just deleted."

part "PART B · Hands-on: break the gate and fix it"
explain "Dependencies are a common way vulnerabilities get in. You will install an old, vulnerable library into a COPY of the API (your real code is untouched), watch the audit fail, then fix it."
task "Add a vulnerable library, see the audit fail, then fix it" "Type these commands one by one at the lab prompt: mkdir -p playground/api-copy && cp app/api/package*.json app/api/server.js playground/api-copy/ && cd playground/api-copy && npm install lodash@4.17.20 . Then run: npm audit --omit=dev --audit-level=high   (it FAILS, listing lodash). Then fix it with: npm audit fix   and run the audit again (it passes)." "The check passes when the audit is clean AND lodash is newer than 4.17.20." <<'X'
cd playground/api-copy && npm audit --omit=dev --audit-level=high >/dev/null 2>&1 && ! node -p "require('./node_modules/lodash/package.json').version" | grep -qx '4.17.20'
---
rm -rf playground/api-copy && mkdir -p playground/api-copy && cp app/api/package*.json app/api/server.js playground/api-copy/ && cd playground/api-copy && npm install lodash@4.17.20 --silent && (npm audit --omit=dev --audit-level=high >/dev/null 2>&1; true) && npm audit fix --silent
X
quiz "Why was npm removed from the final API image?" "attack|surface|vulnerab|need|smaller|tool|cve|bundled" "The running app does not need a package manager. npm bundled outdated libraries with HIGH CVEs, and what you do not ship cannot be exploited."
quiz "Name two layers of defense used in this lab's Kubernetes setup." "non-root|root|read-only|network|polic|capabilit|seccomp|admission|limit" "Examples: non-root user, read-only filesystem, dropped capabilities, NetworkPolicy default-deny, Pod Security 'restricted'. No single control is enough (defense in depth)."

explain "Done! Next: bash lab.sh 10"
