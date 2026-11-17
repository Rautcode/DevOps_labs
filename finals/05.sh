# Module 05 · interview and final (sourced by lab.sh)
# helper: run terraform against the exam folder (LocalStack = a free fake AWS)
tfx() { docker run --rm --entrypoint sh --add-host=host.docker.internal:host-gateway -v "$PWD/playground/tf-exam:/w" -w /w hashicorp/terraform:1.9 -c "terraform init -input=false >/dev/null 2>&1 && terraform $*"; }

part "PART · INTERVIEW"

interview "Plan a new resource" "Interviewer: 'The provider is already configured for you in playground/tf-exam/provider.tf (it points at LocalStack). A teammate wants a second queue. Add ONE SQS queue named exam-queue by creating playground/tf-exam/queue.tf. I will run terraform plan: it must say exactly 1 to add.'" "A resource looks like:  resource \"aws_sqs_queue\" \"exam_queue\" {  name = \"exam-queue\"  }  (use the edit command to create the file)." <<'X'
docker compose -f 05-terraform/compose.localstack.yml up -d >/dev/null 2>&1; sleep 15; rm -rf playground/tf-exam; mkdir -p playground/tf-exam; printf '%s\n' 'terraform {' '  required_providers {' '    aws = {' '      source  = "hashicorp/aws"' '      version = "~> 5.0"' '    }' '  }' '}' 'provider "aws" {' '  region                      = "ap-south-1"' '  access_key                  = "test"' '  secret_key                  = "test"' '  skip_credentials_validation = true' '  skip_requesting_account_id  = true' '  skip_metadata_api_check     = true' '  endpoints {' '    sqs = "http://host.docker.internal:4566"' '  }' '}' > playground/tf-exam/provider.tf
---
tfx plan -no-color 2>&1 | grep -q 'Plan: 1 to add'
---
printf 'resource "aws_sqs_queue" "exam_queue" {\n  name = "exam-queue"\n}\n' > playground/tf-exam/queue.tf
X

interview "Make it real" "Interviewer: 'Good plan. Now apply it, and prove the queue really exists in the (fake) cloud. I will ask LocalStack for its queues.'" "terraform apply needs -auto-approve when there is nobody to type yes. Run it with the tfx helper:  tfx apply -auto-approve" <<'X'
true
---
awsl sqs list-queues | grep -q exam-queue
---
tfx apply -auto-approve >/dev/null 2>&1
X

part "PART · MODULE FINAL"

final "Run the module tests" "Exam 1 of 3. Run the built-in tests of the storage module (05-terraform/modules/storage) and save the test output into playground/tf-tests.txt. It must show that 2 tests passed." "Use the docker command from lesson 05, step 1, and redirect its output into the file with  >  ." <<'X'
rm -f playground/tf-tests.txt
---
grep -q "2 passed" playground/tf-tests.txt
---
docker run --rm --entrypoint sh -v "$PWD/05-terraform:/w" -w /w/modules/storage hashicorp/terraform:1.9 -c "terraform init -backend=false >/dev/null && terraform test" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' > playground/tf-tests.txt
X

final "Fix the formatting" "Exam 2 of 3. The file playground/tf-fmt/bad.tf is badly formatted. Make  terraform fmt -check  pass for that folder WITHOUT rewriting the file by hand." "terraform fmt reformats files in place. Run it in Docker on that folder:  docker run --rm -v \"\$PWD/playground/tf-fmt:/w\" -w /w hashicorp/terraform:1.9 fmt" <<'X'
rm -rf playground/tf-fmt; mkdir -p playground/tf-fmt; printf 'resource "aws_s3_bucket"   "b" {\nbucket="exam-fmt"\n  tags={a="b"}\n}\n' > playground/tf-fmt/bad.tf
---
docker run --rm -v "$PWD/playground/tf-fmt:/w" -w /w hashicorp/terraform:1.9 fmt -check >/dev/null 2>&1
---
docker run --rm -v "$PWD/playground/tf-fmt:/w" -w /w hashicorp/terraform:1.9 fmt >/dev/null 2>&1
X

final "Clean up with Terraform" "Exam 3 of 3. Always destroy what you practised with. Remove the exam queue USING TERRAFORM (not by hand) and prove it is gone from LocalStack." "tfx destroy -auto-approve" <<'X'
true
---
! awsl sqs list-queues | grep -q exam-queue
---
tfx destroy -auto-approve >/dev/null 2>&1
---
docker compose -f 05-terraform/compose.localstack.yml down >/dev/null 2>&1; rm -rf playground/tf-exam playground/tf-fmt
X
