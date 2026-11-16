#!/usr/bin/env bash
# Run Helm without installing it (Docker only). If the lab cluster (module 06) is running, Helm joins its
# network so it can reach the cluster's API at 127.0.0.1:6443.
#   bash 14-helm/helm.sh lint 14-helm/devlab
#   bash 14-helm/helm.sh install devlab 14-helm/devlab -n devlab-helm --create-namespace --wait
# Have native helm? Skip this script and run helm directly.
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
net=()
if docker inspect devlab-k3s >/dev/null 2>&1; then net=(--network container:devlab-k3s); fi
exec docker run --rm "${net[@]}" -v "$PWD:/w" -w /w -e KUBECONFIG=/w/.kube/config alpine/helm:3.16.2 "$@"
