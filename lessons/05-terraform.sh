# Terraform: infrastructure as code (about 2.5h)
title "Module 05 · Terraform (Infrastructure as Code)"
mission "Your manager asks for a cloud storage bucket, a queue and permissions, and last time someone clicked them together by hand and nobody could repeat it. Your mission: describe the infrastructure in code, preview the change, and create it with one command."
explain "Terraform lets you describe cloud resources (storage, queues, permissions) in files, review them like code, and create or delete them with one command. You practise on a free local copy of AWS called LocalStack, so there is no cost and no risk."

part "PART A · Test the module (no cloud needed)"
learn "Infrastructure as code" "Instead of clicking in a cloud console, you describe the infrastructure in files. Terraform compares the files with reality and changes only what differs. Modules are reusable building blocks, and tests catch mistakes before anything is created."
say "What is infrastructure as code, and why use it?" "It means describing infrastructure in files instead of clicking in a console. The files live in Git, so changes are reviewed, versioned and repeatable, and I can recreate an environment from scratch. It also reduces drift and human error. In my lab I used Terraform to create a bucket, queues and permissions, and tested the module before applying it."
art "Code in, cloud out" <<'ART'
   .tf files (in Git) --> terraform plan --> review --> terraform apply --> real cloud
        ^                                                                     |
        +------------- change the code, never click in the console <---------+
ART
why "terraform init -backend=false::prepare without any remote storage|terraform test::run the tests written next to the module|--entrypoint sh::start a shell inside the Terraform container" "You can test infrastructure code without creating anything real. Tests in the module check that its rules work, such as bucket naming. Good infrastructure code has tests, like any other code."
step "Run the module's built-in tests" "2 passed, 0 failed. The tests check the bucket is private and versioned." <<'CMD'
docker run --rm --entrypoint sh -v "$PWD/05-terraform:/w" -w /w/modules/storage hashicorp/terraform:1.9 -c "terraform init -backend=false >/dev/null && terraform test" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -4
CMD
why "docker compose up -d::start the container in the background|localhost:4566::the address where the fake AWS listens|curl /health::ask LocalStack if it is ready" "LocalStack pretends to be AWS, so you can practise Terraform for free and without risk. It answers the same API calls as the real cloud."
step "Start LocalStack (a fake AWS on your computer)" "LocalStack container Started." <<'CMD'
docker compose -f 05-terraform/compose.localstack.yml up -d 2>&1 | tail -2; sleep 15; curl -s localhost:4566/_localstack/health | head -c 150; echo
CMD

part "PART B · Plan, apply, inspect"
learn "The Terraform workflow" "The loop is init (download plugins), plan (preview), apply (create), destroy (remove). ALWAYS read the plan before applying. Terraform remembers what it created in a state file, which maps your code to real resources and must be protected."
say "Explain the Terraform workflow and the state file." "I run init to download providers, plan to preview exactly what will change, and apply to make it so. Terraform stores what it created in a state file that maps my code to real resources. State can contain secrets, so it is never committed, and in a team it lives in a remote backend with locking. I always read the plan before applying."
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
why "terraform init::prepare the folder|plugin::the provider that knows how to talk to AWS" "Terraform itself knows nothing about AWS. A provider plugin does. init downloads it, once, into the folder."
step "terraform init: download the AWS plugin" "Terraform has been successfully initialized" <<'CMD'
bash 05-terraform/tf.sh init 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -3
CMD
why "terraform plan::compare my code with what exists and show the difference|tail -6::the last lines (the summary)" "Plan changes nothing. It tells you what would be added, changed or destroyed. Reading the plan before every apply is the habit that prevents expensive accidents."
step "terraform plan: PREVIEW the changes (always read the plan!)" "Plan: 8 to add, 0 to change, 0 to destroy." <<'CMD'
bash 05-terraform/tf.sh plan 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -6
CMD
why "terraform apply::make the real world match the code|-auto-approve::do not stop to ask yes (the lab does this for speed)" "This is the step that creates resources. Normally Terraform shows the plan and asks you to type yes. In real work you read that plan first."
step "terraform apply: create everything (takes about a minute)" "Apply complete! Resources: 8 added." <<'CMD'
bash 05-terraform/tf.sh apply -auto-approve 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -6
CMD
why "awsl::the AWS CLI pointed at the fake AWS|s3 ls::list buckets|sqs list-queues::list queues" "Do not trust Terraform output alone. Ask the cloud itself what exists. This is the same command you would use against real AWS."
step "Look at what was created, using the AWS command line" "A bucket named devlab-dev-uploads and queues named devlab-dev-leads and devlab-dev-leads-dlq." <<'CMD'
awsl s3 ls; awsl sqs list-queues --query QueueUrls --output text
CMD
why "terraform apply::run it a second time" "Nothing changes the second time: 0 added. Terraform is idempotent, it only changes what differs from the code. That makes running it safe and repeatable."
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

part "PART D · Workspaces: one code, several environments"
learn "Workspaces" "A Terraform workspace is a separate STATE for the same code. The default workspace is called default. Create another one (for example staging) and Terraform starts with an empty state: the same code now wants to create everything again, without touching what the other workspace built. Teams use workspaces, or separate folders, to run dev, staging and production from one set of files. Inside the code, terraform.workspace holds the current name, so you can change names or sizes per environment. Production usually gets its own state and its own access rights, because a wrong workspace is an easy mistake."
say "What are Terraform workspaces?" "A workspace is a separate state for the same code, so one configuration can manage several environments such as dev and staging. A new workspace starts empty, so Terraform wants to create everything again without touching the other one. Many teams prefer separate folders or state files per environment, because applying in the wrong workspace is an easy mistake, so I always check the current workspace first."
art "One code, many states" <<'ART'
   same .tf files
      |-- workspace default  -> state A -> dev resources
      |-- workspace staging  -> state B -> staging resources   (empty at first)
      |-- workspace qa       -> state C -> qa resources
   terraform workspace select NAME   switches which state is used
ART
why "terraform workspace list::show the workspaces, with a star on the current one" "A workspace is a separate state for the same code. Everyone starts in one called default."
step "List the workspaces" "A star marks the one in use: default." ok 'default' <<'CMD'
bash 05-terraform/tf.sh workspace list
CMD
why "terraform workspace new staging::create it and switch to it" "A new workspace starts with an empty state, as if nothing had been built. That is how one set of files can manage several environments."
step "Create a workspace called staging" "Created and switched to workspace staging." ok 'staging' <<'CMD'
bash 05-terraform/tf.sh workspace new staging 2>&1 | head -2
CMD
why "terraform plan::preview|grep -E::show only the summary line" "Terraform wants to create all 8 resources again, because the staging state is empty. Nothing in default is touched. Always check which workspace you are in before you apply."
step "Plan in the new workspace" "Plan: 8 to add. The staging state is empty, so Terraform wants to create everything, even though default already has it." ok '8 to add' <<'CMD'
bash 05-terraform/tf.sh plan 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "^Plan:|No changes"
CMD
why "workspace select default::go back|terraform plan::preview again" "In default, Terraform still remembers the resources it built, so the plan says no changes. Each workspace keeps its own memory."
step "Switch back to default and plan again" "No changes. The default workspace still knows the resources it built." ok 'No changes' <<'CMD'
bash 05-terraform/tf.sh workspace select default >/dev/null 2>&1; bash 05-terraform/tf.sh plan 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "^Plan:|No changes"
CMD
predict "You run terraform apply while the staging workspace is selected, but you meant to change dev. What happens?" "It changes dev|It builds a SEPARATE copy using the staging state|It fails|Nothing" 2 "Each workspace has its own state, so the apply works on the staging state only. Always check which workspace you are in (terraform workspace show) before you apply."
task "Plan in your own workspace" "Create a workspace called qa, then save its plan into playground/qa-plan.txt:  bash 05-terraform/tf.sh workspace new qa   then   bash 05-terraform/tf.sh plan > playground/qa-plan.txt   The plan must say 8 to add, and qa must be the selected workspace." "workspace new creates AND selects it. Check with: bash 05-terraform/tf.sh workspace show" <<'X'
grep -q '8 to add' playground/qa-plan.txt 2>/dev/null && [ "$(bash 05-terraform/tf.sh workspace show 2>/dev/null | tr -d '\r\n')" = qa ]
---
bash 05-terraform/tf.sh workspace new qa >/dev/null 2>&1; bash 05-terraform/tf.sh plan 2>&1 | sed 's/\x1b\[[0-9;]*m//g' > playground/qa-plan.txt
X
why "workspace select default::move off the workspace first|workspace delete::remove a workspace|workspace list::check the result" "You cannot delete the workspace you stand on, so switch first. Leaving only default keeps the lab tidy for the destroy step."
step "Return to default and delete the practice workspaces" "The staging and qa workspaces are deleted; default stays." ok 'default' <<'CMD'
bash 05-terraform/tf.sh workspace select default >/dev/null 2>&1; bash 05-terraform/tf.sh workspace delete staging >/dev/null 2>&1; bash 05-terraform/tf.sh workspace delete qa >/dev/null 2>&1; bash 05-terraform/tf.sh workspace list
CMD

part "PART E · Clean up"
why "terraform destroy::delete every resource in this state" "Destroy cleans up completely. With a real cloud account this is what stops the bill. Always destroy what you created for practice."
step "terraform destroy: remove everything it created" "Destroy complete! Resources: 8 destroyed." <<'CMD'
bash 05-terraform/tf.sh destroy -auto-approve 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -2
CMD
why "docker compose down::stop and remove the fake AWS" "Free the memory and the ports."
step "Stop LocalStack" "Container removed." <<'CMD'
docker compose -f 05-terraform/compose.localstack.yml down 2>&1 | tail -2
CMD
quiz "Terraform keeps a 'state' file. What is in it and why must it never be committed to git?" "secret|sensitive|password|map|resource|real|id|credential" "State maps your code to the real resources and can contain secrets. Teams keep it in a protected remote backend with locking."

deeper "Terraform Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/terraform-zero-to-hero" "TerraWeek, a 7-day challenge (Shubham Londhe)|https://github.com/LondheShubham153/TerraWeek"
explain "Done! Next: bash lab.sh 06"
