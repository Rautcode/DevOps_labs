#!/usr/bin/env bash
# Local Kubernetes with zero installs beyond Docker + kubectl (k3s in a container).
#   bash 06-kubernetes/cluster.sh up     start cluster, load images, write .kube/config
#   bash 06-kubernetes/cluster.sh down   delete everything
# Then: export KUBECONFIG=$PWD/.kube/config
# (Prefer kind/minikube? Fine: the manifests are identical. See kind-config.yaml.)
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
N=devlab-k3s
case "${1:-}" in
  up)
    docker inspect $N >/dev/null 2>&1 || docker run -d --name $N --privileged -p 6443:6443 -p 30080:30080 \
      rancher/k3s:v1.30.5-k3s1 server --disable traefik --disable metrics-server --write-kubeconfig-mode 644 >/dev/null
    until docker exec $N kubectl get nodes 2>/dev/null | grep -q " Ready"; do sleep 3; done
    mkdir -p .kube
    docker exec $N cat /etc/rancher/k3s/k3s.yaml | sed 's#https://127.0.0.1:6443#https://127.0.0.1:6443#' > .kube/config
    for i in devlab-api:lab devlab-web:lab; do
      docker image inspect $i >/dev/null 2>&1 || { echo "build $i first (module 02/03)"; exit 1; }
      docker save $i | docker exec -i $N ctr images import - >/dev/null
    done
    echo "cluster ready. export KUBECONFIG=$PWD/.kube/config"
    echo "deploy:  kubectl apply -k 06-kubernetes/overlays/dev   ->  http://localhost:30080" ;;
  down) docker rm -f $N >/dev/null 2>&1 || true; rm -rf .kube; echo "cluster removed" ;;
  *) echo "usage: cluster.sh up|down"; exit 1 ;;
esac
