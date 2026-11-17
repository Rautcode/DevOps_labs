# 22 · Ship it for real (Extra, ~3h)

> **Guided version:** run `bash lab.sh 22` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference. **Unlocks after module 11.**

**Goal:** real-world proof. A live GitHub pipeline, pull requests, a tagged release with images, Dependabot, and the code to deploy to a real cloud server.

| File | What it is |
|---|---|
| [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | the live pipeline (app, docker, security, infra jobs) |
| [`.github/dependabot.yml`](../.github/dependabot.yml) | automatic update pull requests (npm, Docker, Actions) |
| [aws-deploy/main.tf](aws-deploy/main.tf) | one small AWS server running the two containers, with no SSH port, IMDSv2 and an encrypted disk |

Shortcuts: `ghget /PATH` reads your repo from the GitHub API (public repos need no login), `ghjobs` shows the jobs of the latest CI run.

## What is verified for real
The CI pipeline runs on GitHub for every push: **all four jobs pass**, including a Trivy vulnerability gate. Its first run failed for a real reason (a third-party action tag, `trivy-action@0.28.0`, no longer existed), which is why the pipeline now runs Trivy from its container, and why the lesson teaches pinning. The deployment Terraform passes `terraform validate` and Checkov (32 checks passed, 1 documented skip). The **apply to a real AWS account was not run by the lab author**: it needs your account.

## Optional real steps (you do them)
1. **Pull request flow:** branch, push, open the PR, watch checks, merge.
2. **Release:** copy `04-ci-cd/workflows/release.yml` to `.github/workflows/`, push a tag `v0.1.0`, then make the two packages public in your GitHub profile.
3. **Cloud deploy (costs money outside the free tier):** with a budget alarm and MFA, run Terraform in `aws-deploy` with `github_owner` and `image_tag`, open the printed URL, **then destroy**.

## Cost and safety rules
- Create the budget alarm first (module 17). A t3.micro is inside the free tier for new accounts; otherwise it costs a few cents per day. Always run `destroy`.
- No SSH is opened; use Session Manager for a shell (the instance has the SSM role).
- Secrets are generated on the server so they are not in git, user data variables or Terraform state. Better still: use a secret manager (module 20).

## Concepts
Pin third-party actions to commit SHAs; protect `main` (PR, status checks, approvals, no force push); use Dependabot; publish signed, versioned images; deploy by version tag, never `latest`.

## Industry notes
Real pipelines add environments with approval gates, OIDC to the cloud (no stored keys: `17-aws/envs/aws/github-oidc.tf`), staged rollouts and automatic rollback on SLO burn. Managed container services (ECS Fargate, App Runner, Cloud Run) replace a hand-managed server for most small teams.
