# Terraform: infrastructure as code (about 2.5h)
title "Module 05 · Terraform (Infrastructure as Code)"
explain "Terraform lets you describe cloud resources (storage, queues, permissions) in files, review them like code, and create or delete them with one command. You practise on a free local copy of AWS called LocalStack, so there is no cost and no risk."
AWSX='AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test aws --no-cli-pager --endpoint-url=http://localhost:4566 --region ap-south-1'
export AWSX

part "PART A · Test the module (no cloud needed)"
step "Run the module's built-in tests" "2 passed, 0 failed. The tests check the bucket is private and versioned." <<'CMD'
docker run --rm --entrypoint sh -v "$PWD/05-terraform:/w" -w /w/modules/storage hashicorp/terraform:1.9 -c "terraform init -backend=false >/dev/null && terraform test" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -4
CMD
step "Start LocalStack (a fake AWS on your computer)" "LocalStack container Started." <<'CMD'
docker compose -f 05-terraform/compose.localstack.yml up -d 2>&1 | tail -2; sleep 15; curl -s localhost:4566/_localstack/health | head -c 150; echo
CMD

part "PART B · Plan, apply, inspect"
step "terraform init: download the AWS plugin" "Terraform has been successfully initialized" <<'CMD'
bash 05-terraform/tf.sh init 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -3
CMD
step "terraform plan: PREVIEW the changes (always read the plan!)" "Plan: 8 to add, 0 to change, 0 to destroy." <<'CMD'
bash 05-terraform/tf.sh plan 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -6
CMD
step "terraform apply: create everything (takes about a minute)" "Apply complete! Resources: 8 added." <<'CMD'
bash 05-terraform/tf.sh apply -auto-approve 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -6
CMD
step "Look at what was created, using the AWS command line" "A bucket named devlab-dev-uploads and queues named devlab-dev-leads and devlab-dev-leads-dlq." <<'CMD'
eval "$AWSX s3 ls"; eval "$AWSX sqs list-queues --query QueueUrls --output text"
CMD
step "Apply AGAIN" "0 added, 0 changed. Terraform is idempotent: it only changes what differs from the code." <<'CMD'
bash 05-terraform/tf.sh apply -auto-approve 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -3
CMD

part "PART C · Hands-on: drift"
explain "Drift = someone changes the real infrastructure by hand so it no longer matches the code. Terraform can detect it and heal it."
task "Create drift, then heal it" "1) Delete the leads queue by hand: URL=\$(aws --endpoint-url=http://localhost:4566 --region ap-south-1 sqs get-queue-url --queue-name devlab-dev-leads --query QueueUrl --output text)  then  aws --endpoint-url=http://localhost:4566 --region ap-south-1 sqs delete-queue --queue-url \$URL   (set AWS_ACCESS_KEY_ID=test and AWS_SECRET_ACCESS_KEY=test first). 2) Run: bash 05-terraform/tf.sh apply -auto-approve  . The queue comes back." "The check passes when the queue devlab-dev-leads exists in LocalStack again." <<'X'
eval "$AWSX sqs list-queues --query QueueUrls --output text" | tr '\t' '\n' | grep -qx '.*/devlab-dev-leads'
---
U=$(eval "$AWSX sqs get-queue-url --queue-name devlab-dev-leads --query QueueUrl --output text") && eval "$AWSX sqs delete-queue --queue-url $U" && bash 05-terraform/tf.sh apply -auto-approve
X

part "PART D · Clean up"
step "terraform destroy: remove everything it created" "Destroy complete! Resources: 8 destroyed." <<'CMD'
bash 05-terraform/tf.sh destroy -auto-approve 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -2
CMD
step "Stop LocalStack" "Container removed." <<'CMD'
docker compose -f 05-terraform/compose.localstack.yml down 2>&1 | tail -2
CMD
quiz "Terraform keeps a 'state' file. What is in it and why must it never be committed to git?" "secret|sensitive|password|map|resource|real|id|credential" "State maps your code to the real resources and can contain secrets. Teams keep it in a protected remote backend with locking."

explain "Done! Next: bash lab.sh 06"
