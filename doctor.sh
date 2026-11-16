#!/usr/bin/env bash
# Checks your machine for the lab. Run from repo root: bash doctor.sh
ok()  { printf '  \033[32m✔\033[0m %s\n' "$1"; }
bad() { printf '  \033[31m✘\033[0m %s  ->  %s\n' "$1" "$2"; miss=1; }
opt() { printf '  \033[33m○\033[0m %s (optional: %s)\n' "$1" "$2"; }
miss=0
echo "Required"
command -v git >/dev/null     && ok "git"          || bad "git" "install Git"
command -v docker >/dev/null  && ok "docker CLI"   || bad "docker" "install Docker Desktop"
docker info >/dev/null 2>&1   && ok "docker daemon running" || bad "docker daemon" "start Docker Desktop"
command -v kubectl >/dev/null && ok "kubectl"      || bad "kubectl" "install kubectl (https://kubernetes.io/docs/tasks/tools/)"
command -v node >/dev/null    && ok "node $(node -v)" || bad "node" "install Node 24+"
echo "Optional (the lab also runs these inside Docker)"
command -v terraform >/dev/null && ok "terraform" || opt "terraform" "use 05-terraform/tf.sh"
command -v kind >/dev/null      && ok "kind"      || opt "kind" "use 06-kubernetes/cluster.sh"
command -v helm >/dev/null      && ok "helm"      || opt "helm" "only for the Helm exercise in module 06"
if [ -f .env ]; then ok ".env exists"; else cp .env.example .env && ok "created .env from example"; fi
gb=$(docker info --format '{{.MemTotal}}' 2>/dev/null | awk '{printf "%d", $1/1073741824}')
if [ "${gb:-0}" -ge 6 ]; then ok "Docker has ${gb}GB RAM"; else bad "Docker memory ${gb:-?}GB" "give Docker >= 6GB (modules 06-08 run many containers)"; fi
case "${OSTYPE:-}" in msys*|cygwin*) [ -z "${MSYS_NO_PATHCONV:-}" ] && printf '  [33m![0m Windows Git Bash tip: run  export MSYS_NO_PATHCONV=1  (once per terminal) so Docker paths like /data are not rewritten.
' ;; esac
echo; echo "Next: bash lab.sh"
exit $miss
