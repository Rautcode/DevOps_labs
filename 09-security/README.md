# 09 · DevSecOps (Advanced, ~4h)

> **Guided version:** run `bash lab.sh 09` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** make security automatic: every layer from code to cluster is scanned, and the cluster itself refuses bad workloads.

```bash
bash 09-security/scan.sh        # needs only Docker; build images first (module 02)
```

| Gate | Tool | Finds |
|---|---|---|
| 1 Secrets in git history | **gitleaks** | leaked keys/tokens |
| 2 Dockerfile lint | **hadolint** | unsafe or wasteful Dockerfile patterns |
| 3 Image vulnerabilities | **Trivy** | known CVEs in OS packages *and* npm dependencies |
| 4 Terraform misconfig | **Checkov** | public buckets, no encryption, over-broad IAM |
| 5 Kubernetes manifests | **kubeconform** + **Trivy config** | invalid or insecure manifests |

[policies/](policies/require-signed-and-restricted.yaml) holds Kyverno admission policies (no `:latest`, no root).

## What this lab's own scan found (real results, not examples)
| Finding | What happened | Lesson |
|---|---|---|
| nginx image had fixable **CRITICAL/HIGH** CVEs | added `apk upgrade` + moved off an old tag | base images rot: rebuild and rescan continuously |
| k8s web pod lacked `readOnlyRootFilesystem` | added `emptyDir` mounts | hardening has a cost: you must find what needs to write |
| SQS queues unencrypted, no multipart-abort rule | fixed in Terraform | IaC scanning catches cloud mistakes pre-deploy |
| Dockerfile lint warnings | exec-form `CMD`, numeric `USER` | small things matter for signal handling and k8s `runAsNonRoot` |
| API image: 6 HIGH CVEs in `npm`/`corepack` bundled with the Node base image | removed npm, npx and corepack from the runtime stage | the runtime needs no package manager; what you do not ship cannot be exploited |
| App dependencies: no known CVEs | kept the sample API to a single dependency (`express`) | fewer dependencies means a smaller attack surface |
| no secrets in 12 commits of history | gitleaks clean | keep it that way: add it to CI (module 04) |

**Your first task:** run the scan and see `ALL GATES PASSED`. Then break it on purpose: `cd app/api && npm install lodash@4.17.20`, rebuild the image, rescan, and watch Trivy and `npm audit` fail. Fix it with `npm audit fix` and watch it go green.

## Concepts
- **Shift left:** catch issues at commit/PR time, where they are cheapest.
- **Defense in depth:** non-root + read-only fs + dropped capabilities + NetworkPolicy + admission policy. No single control is enough.
- **Supply chain:** SBOM (what is inside), provenance (how it was built), signatures (who built it): module 04's release workflow.
- **Suppressions must be explicit and justified** (see `# checkov:skip=... <reason>` in the Terraform module).

## Exercises
1. Commit a fake secret on a throwaway branch; watch gitleaks fail; then purge it from history (`git filter-repo`) and explain why rotating the key is mandatory.
2. Install Kyverno on the module 06 cluster, apply the policy, then try `kubectl run bad --image=nginx:latest`: it is rejected.
3. Generate an SBOM: `docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.58.0 image --format cyclonedx devlab-web:lab`.
4. Add Dependabot (`.github/dependabot.yml`) for npm, Docker and GitHub Actions.
5. **Expert:** threat-model the lead form + admin login (STRIDE), then verify the app's rate limits, JWT cookie flags and CSP headers.

**Next:** [10 · SRE](../10-sre/README.md)
