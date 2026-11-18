# Ship it for real: a live GitHub pipeline, releases and a real cloud deploy (about 3h)
title "Module 22 · Ship it for real"
mission "Employers believe what they can click. Your mission: put a real pipeline on GitHub, ship a tagged release, protect the main branch, and collect the evidence for your CV."
explain "Everything before this ran on your computer. Employers want proof that you have shipped to the real world: a pipeline running on GitHub, a release that others can pull, and a deployment on a real cloud. This module uses your REAL GitHub repository (the pipeline is already live in it) and prepares a real cloud deployment. The steps that need your own accounts are marked OPTIONAL and come with safety rules. The shortcut ghget reads your repo from the GitHub API; ghjobs shows the jobs of the latest CI run."

part "PART A · Your pipeline is live"
learn "CI on GitHub" "Every push to main and every pull request now runs .github/workflows/ci.yml on a fresh GitHub machine: tests and audit (app), Dockerfile lint and image builds with a vulnerability scan (docker), secret scanning (security), and Terraform and Kubernetes checks (infra). A red cross blocks trust in a change; a green tick is the minimum bar for merging."
say "Tell me about a CI/CD pipeline you built." "In my project every push and pull request runs on GitHub Actions: tests, a dependency audit, secret and Dockerfile scanning, an image build and a vulnerability scan. Actions are pinned to commit SHAs and permissions are minimal. The status badge is on the README, so anyone can see the pipeline is green. It is a small project, but it shows the real workflow end to end."
art "From a push to a release" <<'ART'
   push -> GitHub Actions: test, scan, build -> green check
   open a pull request -> review -> merge to main
   tag v1.0.0 -> release + published images
ART
step "Which jobs does the pipeline have?" "app, docker, security and infra." ok 'docker' <<'CMD'
grep -nE '^  [a-z]+:$' .github/workflows/ci.yml
CMD
step "What did the latest finished run conclude?" "\"conclusion\": \"success\"" ok 'success' <<'CMD'
ghget '/actions/workflows/ci.yml/runs?status=completed&per_page=1' | grep -m1 '"conclusion"'
CMD
step "Look at the result of every job in that run" "Four jobs (app, security, infra, docker), each with conclusion: success. The conclusion line comes just before the job name." ok 'success' <<'CMD'
ghjobs
CMD
learn "A real failure, and what it teaches" "The first run of this pipeline failed in the docker job: GitHub reported Unable to resolve action aquasecurity/trivy-action@0.28.0, because that tag no longer existed. Nothing was wrong with the code. Lessons: third-party actions are code you run with your credentials, tags can move or vanish, so pin important actions to a full commit SHA, prefer few dependencies, and read failures at the very first red line (here: Set up job)."
say "Tell me about a time a pipeline broke." "In my project the pipeline failed because the tag of a third-party scanning action I used no longer existed. I found it in the job logs, replaced it by running the scanner from a pinned container image, and pinned the rest of the actions too. The lesson was that external dependencies in a pipeline are a risk and should be pinned and monitored."
step "Find the commit that fixed it" "CI: run Trivy from its container (the trivy-action tag no longer exists)." ok 'Trivy' <<'CMD'
git log --oneline --grep='Trivy' -3
CMD
quiz "Why pin a GitHub Action to a full commit SHA instead of a tag like @v4?" "tag|move|change|compromis|supply|immutable|vanish|hijack|safe|trust" "A tag can be moved or deleted, so the code you run can change under you (supply-chain attack, or a broken build). A commit SHA is immutable. Dependabot can keep pinned SHAs up to date."

part "PART B · Keep the pipeline healthy"
learn "Dependabot and a status badge" "Dependabot opens pull requests when your npm packages, Docker base images or Actions have newer versions, so security fixes arrive as small reviewed changes instead of a once-a-year panic. A status badge in the README shows the pipeline state to everyone who visits the repo, which is a quiet signal of engineering discipline."
say "How do you keep dependencies up to date?" "I use Dependabot, which opens pull requests for new versions of npm packages, GitHub Actions and Docker images. The pipeline tests each one, so I can review and merge small updates regularly instead of facing a big risky upgrade later. A status badge on the README shows the current health of the pipeline."
step "See the Dependabot configuration" "Three ecosystems: npm, github-actions, docker, each checked weekly." ok 'npm' <<'CMD'
cat .github/dependabot.yml
CMD
step "Is the CI badge in the README?" "1 (the badge image line is present)." ok '^[1-9]' <<'CMD'
grep -c 'actions/workflows/ci.yml/badge.svg' README.md
CMD
learn "Protect main" "On GitHub: Settings, Branches, Add rule for main. Turn on: require a pull request before merging, require status checks to pass (choose the four CI jobs), require at least one approval, and block force pushes. After that nobody, including you, can push broken code straight to main. (A free private repo may need a paid plan for this; public repos have it.)"
say "How do you protect the main branch?" "With branch protection rules: require a pull request, require status checks to pass, require at least one review, and block force pushes. That means nothing reaches main without tests and review, and mistakes are caught before release."
quiz "Name two settings of a good branch protection rule on main." "pull request|review|approv|status check|ci|force|direct|required" "Require a pull request with at least one approval, require the CI status checks to pass, and block force pushes and direct pushes."

part "PART C · The pull-request flow on your real repo (OPTIONAL, needs push access)"
explain "These tasks use your real repository and your own Git login, so they are optional and skipping them does not block the module. They are the best practice you can get: you will do the same thing daily at work."
OPT=1 task "Open a pull request" "Type these commands at the lab prompt, one by one:  git switch -c lab/pr-test   then   echo my notes > NOTES.md   then   git add NOTES.md   then   git commit -m 'docs: my notes'   then   git push -u origin lab/pr-test   . GitHub prints a link to open a pull request: open it in your browser, wait for the green checks, then merge or close it. Finally  git switch main . Then type check." "The check passes when the branch lab/pr-test exists on GitHub." <<'X'
ghget /branches/lab/pr-test | grep -q '"name": "lab/pr-test"'
---
true
X
OPT=1 task "Cut a release" "A release publishes versioned images that a server can pull. Copy the release workflow:  cp 04-ci-cd/workflows/release.yml .github/workflows/release.yml  then  git add .github  and  git commit -m 'ci: release workflow'  and  git push  . Then tag and push the tag:  git tag v0.1.0  and  git push origin v0.1.0  . Watch the Actions tab until the release workflow is green. Then, in your GitHub profile under Packages, make devlab-api and devlab-web public (so a server can pull them without a password). Type check when the release workflow succeeded." "The check passes when the latest release.yml run on GitHub concluded success." <<'X'
ghget '/actions/workflows/release.yml/runs?status=completed&per_page=1' | grep -m1 '"conclusion"' | grep -q success
---
true
X

part "PART D · A real cloud deployment (code checked here, apply is OPTIONAL)"
learn "From a pipeline to a server" "The pipeline produced signed images. A deployment puts them on a machine people can reach. The Terraform in 22-ship/aws-deploy creates one small server with Docker that pulls your images and serves the website on port 80. Good habits are built in: no SSH port at all (use Session Manager), a role instead of keys, IMDSv2 only, an encrypted disk, and secrets generated ON the server so they never appear in git or Terraform state."
say "How does a change get from a pipeline to production?" "The pipeline builds a versioned image and pushes it to a registry on a release tag. A deployment step, ideally GitOps, updates the environment to that version after approval, with health checks and an easy rollback to the previous version. I keep the infrastructure in Terraform, and I always set budgets and least-privilege access for a cloud account."
step "Format and validate the deployment code (no AWS account needed)" "Success! The configuration is valid." ok 'valid' <<'CMD'
docker run --rm --entrypoint sh -v "$PWD:/w" -w /w/22-ship/aws-deploy hashicorp/terraform:1.9 -c "terraform fmt -check -recursive /w/22-ship && terraform init -backend=false >/dev/null 2>&1 && terraform validate" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -2; rm -rf 22-ship/aws-deploy/.terraform 22-ship/aws-deploy/.terraform.lock.hcl
CMD
step "Scan it for security problems" "Passed checks: 32, Failed checks: 0. One documented skip: the website port is public on purpose." ok 'Failed checks: 0' <<'CMD'
docker run --rm -v "$PWD:/tf:ro" bridgecrew/checkov:latest -d /tf/22-ship/aws-deploy --framework terraform --compact --quiet 2>&1 | grep -E "Passed checks"
CMD
step "Read the first-boot script the server will run" "It installs Docker, generates random secrets ON the server, and starts the api and web containers." ok 'urandom' <<'CMD'
grep -nE "docker|urandom|ghcr" 22-ship/aws-deploy/main.tf | head -12
CMD
quiz "Why are the secrets generated on the server instead of passed in as Terraform variables?" "state|git|file|visible|leak|never|stored|plain" "Terraform keeps variable values in its state file and in plans, and user_data is readable on the instance. Generating them on the server keeps them out of git and state. (Better still: fetch them from a secret manager, module 20.)"
OPT=1 task "Deploy it to a real AWS account, look at it, then DESTROY it" "ONLY with your own AWS account, a budget alarm (module 17) and MFA. Needs: the release from PART C, with public packages. Run:  lab-tf-aws init   is for module 17; for this module use the folder 22-ship/aws-deploy directly:  docker run --rm -it -v \"\$PWD:/w\" -w /w/22-ship/aws-deploy -v \"\$HOME/.aws:/root/.aws:ro\" hashicorp/terraform:1.9 apply -var github_owner=<you> -var image_tag=0.1.0   Wait about 3 minutes, open the printed website address, then CLEAN UP with the same command but destroy. A t3.micro is inside the free tier for new accounts and costs a few cents a day otherwise." "Not required. Type skip to continue." <<'X'
false
---
true
X

part "PART E · What an employer sees"
learn "Turn this into evidence" "Evidence beats a list of tools. After this module you can point at: a public repository with a green pipeline badge, Dependabot pull requests, tagged releases with signed container images, infrastructure as code with tests and scans, runbooks and postmortems, and (with an account) a live URL. The JOB-READY.md guide shows how to present each of these on your CV and in interviews."
say "Walk me through a project you have built." "I built a small web service, a Node API behind nginx, and operated it end to end: containers, Compose, CI with scanning, Terraform, Kubernetes with probes and autoscaling, GitOps, monitoring with SLO alerts, and incident drills with postmortems. It is a lab, not production, but everything is public in my repository with a green pipeline, so you can see how I work."
quiz "In one sentence: what is the difference between continuous delivery and continuous deployment?" "manual|approval|automatic|every|release|human|button|click" "Continuous delivery keeps every change ready to release, with a human pressing the button. Continuous deployment releases every passing change to production automatically, with no human step."

deeper "cicd-end-to-end (Abhishek Veeramalla)|https://github.com/iam-veeramalla/cicd-end-to-end" "An end-to-end DevOps project (Abhishek Veeramalla)|https://github.com/iam-veeramalla/ultimate-devops-project-aws"
explain "Done! Next: bash lab.sh 23"
