#!/usr/bin/env bash
# One-command security gate. Needs only Docker. Run from repo root: bash 09-security/scan.sh
# Each tool = one layer of "shift-left" security. Exit code is non-zero if any gate fails.
set -u
cd "$(dirname "$0")/.." || exit 1
export MSYS_NO_PATHCONV=1
fail=0
step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
run()  { "$@" || fail=1; }

step "1/5 Secrets in git history (gitleaks)"
run docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:latest detect --source /repo --no-banner --redact

step "2/5 Dockerfile lint (hadolint)"
for f in api web; do run docker run --rm -i hadolint/hadolint < "02-containers/Dockerfile.$f"; done

step "3/5 Image CVEs (trivy, fixable HIGH/CRITICAL)"
for i in api web; do
  docker image inspect "devlab-$i:lab" >/dev/null 2>&1 || { echo "build devlab-$i:lab first (module 02)"; fail=1; continue; }
  run docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v "$PWD/.trivyignore:/.trivyignore:ro" aquasec/trivy:0.58.0 image \
    --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --quiet "devlab-$i:lab"
done

step "4/5 Terraform misconfig (checkov)"
run docker run --rm -v "$PWD/05-terraform:/tf:ro" bridgecrew/checkov:latest -d /tf --framework terraform --quiet --compact --soft-fail-on LOW

step "5/5 Kubernetes manifests (kubeconform + trivy config)"
for o in dev prod; do kubectl kustomize "06-kubernetes/overlays/$o" | run docker run --rm -i ghcr.io/yannh/kubeconform:latest -strict -summary -; done
run docker run --rm -v "$PWD/06-kubernetes:/k:ro" aquasec/trivy:0.58.0 config --severity HIGH,CRITICAL --exit-code 1 --quiet /k

[ $fail -eq 0 ] && echo -e "\n\033[32mALL GATES PASSED\033[0m" || echo -e "\n\033[31mSOME GATES FAILED\033[0m"
exit $fail
