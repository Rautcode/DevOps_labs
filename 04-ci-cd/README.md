# 04 · CI/CD with GitHub Actions (Intermediate, ~4h)

> **Guided version:** run `bash lab.sh 04` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** every push is automatically tested, built, scanned; every tag produces a signed, traceable release.

| Workflow | Trigger | Does |
|---|---|---|
| [workflows/ci.yml](workflows/ci.yml) | push, PR | API tests + `npm audit`, hadolint, image build + Trivy gate, gitleaks, `terraform test`, manifest validation |
| [workflows/release.yml](workflows/release.yml) | tag `v*.*.*` | multi-arch build, push to GHCR, SBOM + provenance, keyless cosign signature |

Both files pass `actionlint` (the workflow linter).

## Do it
```bash
mkdir -p .github/workflows
cp 04-ci-cd/workflows/ci.yml .github/workflows/ci.yml
git switch -c ci/enable && git add .github && git commit -m "ci: add pipeline" && git push -u origin ci/enable
# open a PR on GitHub and watch the checks run
```
Lint a workflow locally without pushing:
```bash
docker run --rm -v "$PWD/04-ci-cd/workflows:/w" -w /w rhysd/actionlint:latest -color=false /w/ci.yml
```
**Check:** all jobs green on the PR. Then require them: *Settings → Branches → protect `main` → require status checks*.

## Release
```bash
cp 04-ci-cd/workflows/release.yml .github/workflows/
git tag v1.0.0 && git push --tags
```
Images appear under *Packages* as `devlab-api` / `devlab-web`. Verify the signature:
```bash
cosign verify ghcr.io/<you>/devlab-web:1.0.0 --certificate-identity-regexp 'github.com/<you>/' --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Concepts
- **Fail fast, cheap checks first** (tests before build before scan). `needs:` orders jobs.
- **Least-privilege tokens.** `permissions: contents: read` by default; `packages: write` and `id-token: write` only in the release job.
- **Keyless signing.** No private key to leak: GitHub's OIDC identity signs the image.
- **SBOM + provenance** answer "what is inside this image and who built it?" (supply-chain security, SLSA).
- **Cache** (`type=gha`) cuts build time dramatically.
- **Immutable versions.** Deploy `1.0.0` (or better, its digest), never `latest`.

## Jenkins side by side
Many companies still run Jenkins, so interviewers ask how it compares with GitHub Actions. [Jenkinsfile](Jenkinsfile) is this repo's CI written for Jenkins (a *declarative pipeline*).

| GitHub Actions | Jenkins |
|---|---|
| workflow file in `.github/workflows/*.yml` | `Jenkinsfile` (Groovy) in the repo |
| `on: push` | webhook or polling trigger |
| job, step, `run:` | stage, step, `sh '...'` |
| runner | agent |
| action from the marketplace | plugin |
| `secrets.NAME` | credentials binding |
| hosted by GitHub | **hosted by you**: updates, plugins, backups, security |

```bash
docker run -d --name lab-jenkins -p 8085:8080 jenkins/jenkins:lts-jdk21
docker logs lab-jenkins 2>&1 | grep "fully up"                                   # wait for it
docker exec lab-jenkins cat /var/jenkins_home/secrets/initialAdminPassword       # first-login password
# open http://localhost:8085, unlock, install suggested plugins, create a Pipeline job that uses the Jenkinsfile
docker rm -f lab-jenkins
```
The guided lab stops at the unlock page, because pipeline syntax checking needs the pipeline plugins that the setup wizard installs.

## Break it
1. Break a test in `app/api/server.test.js`, push: the PR is blocked. Fix it.
2. Add a fake AWS key (`AKIA` + 16 chars) to a file, push: gitleaks should fail. Then learn why deleting it in a later commit is **not** enough (history; rotate the key).
3. Downgrade the nginx base image to an old tag: Trivy should fail the build.

## Industry notes
- Trunk-based development: short branches, PR checks, merge to `main` often. Measure with DORA metrics (module 11).
- Pin third-party actions to a commit SHA in security-sensitive repos (Dependabot keeps them updated).
- CD to the cluster should be **pull-based GitOps** (module 07), not `kubectl apply` from CI.

**More practice (second helping on another app):** [node-todo-cicd](https://github.com/LondheShubham153/node-todo-cicd), [github-actions-cicd-masterclass](https://github.com/LondheShubham153/github-actions-cicd-masterclass), [django-todo-cicd](https://github.com/LondheShubham153/django-todo-cicd). See [RESOURCES.md](../RESOURCES.md) for the full list.

**Next:** [05 · Terraform](../05-terraform/README.md)
