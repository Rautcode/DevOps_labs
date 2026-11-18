# Terraform: infrastructure as code (about 2.5h)
title "Module 05 · Terraform (Infrastructure as Code)"
mission "Your manager asks for a cloud storage bucket, a queue and permissions, and last time someone clicked them together by hand and nobody could repeat it. Your mission: describe the infrastructure in code, preview the change, and create it with one command."
explain "Terraform lets you describe cloud resources (storage, queues, permissions) in files, review them like code, and create or delete them with one command. You practise on a free local copy of AWS called LocalStack, so there is no cost and no risk."

part "PART A · Test the module (no cloud needed)"
learn "Infrastructure as code" "Instead of clicking in a cloud console, you describe the infrastructure in files. Terraform compares the files with reality and changes only what differs. Modules are reusable building blocks, and tests catch mistakes before anything is created."
step "Run the module's built-in tests" "2 passed, 0 failed. The tests check the bucket is private and versioned." <<'CMD'
docker run --rm --entrypoint sh -v "$PWD/05-terraform:/w" -w /w/modules/storage hashicorp/terraform:1.9 -c "terraform init -backend=false >/dev/null && terraform test" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -4
CMD
step "Start LocalStack (a fake AWS on your computer)" "LocalStack container Started." <<'CMD'
docker compose -f 05-terraform/compose.localstack.yml up -d 2>&1 | tail -2; sleep 15; curl -s localhost:4566/_localstack/health | head -c 150; echo
CMD

part "PART B · Plan, apply, inspect"
learn "The Terraform workflow" "The loop is init (download plugins), plan (preview), apply (create), destroy (remove). ALWAYS read the plan before applying. Terraform remembers what it created in a state file, which maps your code to real resources and must be protected."
art "init, plan, apply" <<'ART'
   terraform init     download the plugins
        |
   terraform plan     PREVIEW: what will be added / changed / destroyed
        |
   terraform apply    do it (and write the state file)
        |
   terraform destroy  remove everything it made
ART
mcq "Which command shows what WOULD change without changing anything?" "terraform apply|terraform plan|terraform init|terraform fmt" 2 "Always read the plan first: it is your safety net."
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
awsl s3 ls; awsl sqs list-queues --query QueueUrls --output text
CMD
step "Apply AGAIN" "0 added, 0 changed. Terraform is idempotent: it only changes what differs from the code." <<'CMD'
bash 05-terraform/tf.sh apply -auto-approve 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -3
CMD

part "PART C · Hands-on: drift"
explain "Drift = someone changes the real infrastructure by hand so it no longer matches the code. Terraform can detect it and heal it."
task "Create drift, then heal it" "1) Delete the leads queue by hand. awsl is a shortcut for the AWS CLI pointed at LocalStack. First get the queue address:  URL=\$(awsl sqs get-queue-url --queue-name devlab-dev-leads --query QueueUrl --output text)  then delete it:  awsl sqs delete-queue --queue-url \$URL    2) Heal it: bash 05-terraform/tf.sh apply -auto-approve   The queue comes back. (Variables like URL last only for one command here, so do step 1 as ONE line joined with &&.)" "The check passes when the queue devlab-dev-leads exists in LocalStack again." <<'X'
awsl sqs list-queues --query QueueUrls --output text | tr '\t' '\n' | grep -qx '.*/devlab-dev-leads'
---
U=$(awsl sqs get-queue-url --queue-name devlab-dev-leads --query QueueUrl --output text) && awsl sqs delete-queue --queue-url $U && bash 05-terraform/tf.sh apply -auto-approve
X

part "PART D · Clean up"
step "terraform destroy: remove everything it created" "Destroy complete! Resources: 8 destroyed." <<'CMD'
bash 05-terraform/tf.sh destroy -auto-approve 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -2
CMD
step "Stop LocalStack" "Container removed." <<'CMD'
docker compose -f 05-terraform/compose.localstack.yml down 2>&1 | tail -2
CMD
quiz "Terraform keeps a 'state' file. What is in it and why must it never be committed to git?" "secret|sensitive|password|map|resource|real|id|credential" "State maps your code to the real resources and can contain secrets. Teams keep it in a protected remote backend with locking."

deeper "Terraform Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/terraform-zero-to-hero" "TerraWeek, a 7-day challenge (Shubham Londhe)|https://github.com/LondheShubham153/TerraWeek"
explain "Done! Next: bash lab.sh 06"
