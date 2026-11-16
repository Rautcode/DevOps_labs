#!/usr/bin/env bash
# Run Terraform without installing it (Docker only), against LocalStack on the host.
# usage (from repo root):  bash 05-terraform/tf.sh init | plan | apply -auto-approve | destroy -auto-approve
# Have native terraform? Skip this script: cd 05-terraform/envs/dev && terraform init && terraform apply
set -euo pipefail
export MSYS_NO_PATHCONV=1
cmd="${1:?usage: tf.sh init|plan|apply|destroy [args]}"; shift
extra=()
case "$cmd" in plan|apply|destroy) extra=(-var=endpoint=http://host.docker.internal:4566) ;; esac
exec docker run --rm -i --add-host=host.docker.internal:host-gateway \
  -v "$PWD/05-terraform:/w" -w /w/envs/dev hashicorp/terraform:1.9 "$cmd" "${extra[@]}" "$@"
