#!/usr/bin/env bash
# Run Terraform for the REAL AWS environment in Docker, using your AWS login from ~/.aws.
#   bash 17-aws/tf-aws.sh init
#   bash 17-aws/tf-aws.sh plan    -var name=devlab-yourname -var budget_email=you@example.com
#   bash 17-aws/tf-aws.sh apply   -var name=devlab-yourname -var budget_email=you@example.com
#   bash 17-aws/tf-aws.sh destroy -var name=devlab-yourname -var budget_email=you@example.com
# Always read the plan. Always destroy when you are done practising.
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
exec docker run --rm -i -v "$PWD:/w" -w /w/17-aws/envs/aws -v "$HOME/.aws:/root/.aws:ro" \
  -e AWS_PROFILE="${AWS_PROFILE:-default}" -e AWS_REGION="${AWS_REGION:-ap-south-1}" \
  hashicorp/terraform:1.9 "$@"
