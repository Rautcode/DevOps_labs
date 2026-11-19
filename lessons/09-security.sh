# DevSecOps: scan for security problems automatically (about 2h)
title "Module 09 · DevSecOps"
mission "A security review is coming. Instead of checking by hand, your mission is to put five automatic scanners in front of every change, so secrets, weak Dockerfiles and risky infrastructure are caught early."
explain "Security checks should run automatically, early and often. Five scanners look at your secrets, Dockerfiles, container images, Terraform and Kubernetes files. You will run them all, then break one on purpose to see it fail."

part "PART A · Run the security gate"
learn "Shift left" "Shift left means finding security problems as early as possible, when they are cheap to fix. Five different scanners look at five different things: secrets in git, Dockerfile mistakes, vulnerabilities in images, misconfigured cloud code, and insecure Kubernetes manifests."
say "What does shift left mean in DevSecOps?" "It means finding security problems as early as possible, when they are cheapest to fix. Instead of one audit before release, I scan on every commit and pull request: secrets with gitleaks, Dockerfiles with hadolint, images and dependencies with Trivy, and infrastructure code with Checkov. Developers get fast feedback, and the pipeline blocks risky changes automatically."
art "Shift left" <<'ART'
   code -> commit -> build -> test -> deploy -> production
    ^                                              ^
   cheap to fix here                  expensive and risky here
   (scan on every push)               (breach, outage, headlines)
ART
mcq "Why scan on every commit instead of once a year?" "Problems are cheapest to fix right after they are introduced|Scanners only work on commits|It is required by Git|It makes the code smaller" 1 "The earlier a problem is found, the cheaper it is to fix."
why "docker image inspect::check that the images exist locally|dc build::build them if they do not" "The scanners look at real images, so the images must exist first. Checking before building saves time."
step "Make sure both images exist" "devlab-api:lab and devlab-web:lab are listed." <<'CMD'
docker image inspect devlab-api:lab devlab-web:lab >/dev/null 2>&1 || dc build 2>&1 | tail -2; docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab
CMD
why "gitleaks detect::search every commit for passwords and keys|--source /repo::the repository to scan|--redact::hide the secret values in the output" "A secret committed once stays in the history forever, even if you delete the file later. Scanning the whole history finds leaks that a normal file search misses. Finding one means you must rotate the secret."
step "Scan for leaked secrets in git history (gitleaks)" "'no leaks found'. A leaked key in git history stays there forever, even if you delete it later." <<'CMD'
docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:latest detect --source /repo --no-banner --redact 2>&1 | tail -3
CMD
why "hadolint::a linter that checks Dockerfiles for bad practice|< Dockerfile.api::feed the file to it" "A linter reads the recipe and warns about risky habits, such as running as root or using the latest tag. It is fast and catches problems before the image exists."
step "Lint the Dockerfiles (hadolint)" "No output = no problems." <<'CMD'
docker run --rm -i hadolint/hadolint < 02-containers/Dockerfile.api && docker run --rm -i hadolint/hadolint < 02-containers/Dockerfile.web && echo "Dockerfiles are clean"
CMD
learn "Test what the site REALLY sends" "Scanners read your files, but only a request shows what a visitor receives. A classic nginx trap: add_header at the server level is NOT inherited by a location that sets its own add_header, so a page can silently lose its security headers. X-Content-Type-Options stops browsers guessing file types, X-Frame-Options stops other sites framing yours (clickjacking), and Referrer-Policy limits what is leaked in links. This very lab had that bug on its home page until a review found it."
say "How do you verify security headers?" "Scanners read files, but only a real request shows what the server actually sends. I use curl -i against the running site and check headers like Content-Security-Policy, X-Content-Type-Options and Strict-Transport-Security. In my lab I hit a subtle nginx issue where add_header in a location block replaced the inherited headers, which a live header check caught and a file scan did not."
art "Files vs reality" <<'ART'
   nginx.conf says: add_header X-Frame-Options ...        (what you wrote)
   curl -I localhost:8080/ shows the real headers         (what visitors get)
   if they differ (inheritance gotcha), trust the request, not the file
ART
why "curl -sI::fetch only the response headers|grep -iE::keep the security headers" "Security headers tell the browser to protect the visitor (for example do not guess file types, do not allow framing). Only a real request shows what the server really sends. Files can look right and still send nothing."
step "Ask the home page for its headers" "X-Content-Type-Options: nosniff, X-Frame-Options: DENY and Referrer-Policy on the HOME page (/), not only on /healthz." ok 'X-Frame-Options: DENY' <<'CMD'
dc up -d >/dev/null 2>&1; sleep 10; curl -sI localhost:8080/ | grep -iE "^HTTP|x-content-type|x-frame|referrer"
CMD
why "scan.sh::runs the five scanners one after the other|grep -E::show only the verdict lines" "A gate is the set of checks every change must pass. Secrets, Dockerfiles, images, Terraform and Kubernetes files are all scanned. Shift left means catching problems here, not in production."
step "Run the whole gate (all 5 scanners, takes a few minutes the first time)" "ALL GATES PASSED. Trivy: 0 HIGH/CRITICAL. Checkov and kubeconform: no failures." <<'CMD'
bash 09-security/scan.sh 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "==|no leaks|Total:|Valid:|PASSED|FAILED"
CMD
quiz "Why scan for secrets in git history, not only in the current files?" "history|forever|deleted|still|old|commit|remain" "Anything ever committed stays in history and can be recovered. A leaked key must be rotated (replaced), not just deleted."

part "PART B · Hands-on: break the gate and fix it"
explain "Dependencies are a common way vulnerabilities get in. You will install an old, vulnerable library into a COPY of the API (your real code is untouched), watch the audit fail, then fix it."
learn "Dependencies are risk" "Every library you add also adds its bugs. npm audit compares your dependencies with a database of known vulnerabilities. The usual fix is to upgrade to a patched version, and the best habit is to keep the dependency list short."
say "How do you handle vulnerable dependencies?" "I run npm audit and an image scanner in CI, keep a lock file, and enable Dependabot so updates arrive as reviewed pull requests. I prioritise by severity and by whether the vulnerable code is actually reachable, and I fix or upgrade rather than ignore. Fewer dependencies and minimal base images also reduce the risk."
art "Your code is mostly other people code" <<'ART'
   your app (5%) + libraries (60%) + their libraries (30%) + base image (5%)
   every layer can bring a known vulnerability:
   npm audit / Trivy compare them with a database  ->  upgrade, or accept with a reason
ART
task "Add a vulnerable library, see the audit fail, then fix it" "Type these commands one by one at the lab prompt: mkdir -p playground/api-copy && cp app/api/package*.json app/api/server.js playground/api-copy/ && cd playground/api-copy && npm install lodash@4.17.20 . Then run: npm audit --omit=dev --audit-level=high   (it FAILS, listing lodash). Then fix it with: npm audit fix   and run the audit again (it passes)." "The check passes when the audit is clean AND lodash is newer than 4.17.20." <<'X'
cd playground/api-copy && npm audit --omit=dev --audit-level=high >/dev/null 2>&1 && ! node -p "require('./node_modules/lodash/package.json').version" | grep -qx '4.17.20'
---
rm -rf playground/api-copy && mkdir -p playground/api-copy && cp app/api/package*.json app/api/server.js playground/api-copy/ && cd playground/api-copy && npm install lodash@4.17.20 --silent && (npm audit --omit=dev --audit-level=high >/dev/null 2>&1; true) && npm audit fix --silent
X
quiz "Why was npm removed from the final API image?" "attack|surface|vulnerab|need|smaller|tool|cve|bundled" "The running app does not need a package manager. npm bundled outdated libraries with HIGH CVEs, and what you do not ship cannot be exploited."
quiz "Name two layers of defense used in this lab's Kubernetes setup." "non-root|root|read-only|network|polic|capabilit|seccomp|admission|limit" "Examples: non-root user, read-only filesystem, dropped capabilities, NetworkPolicy default-deny, Pod Security 'restricted'. No single control is enough (defense in depth)."

explain "Done! Next: bash lab.sh 10"
