# Module 17 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Two dangerous cloud settings" "Interviewer: 'playground/aws-exam/main.tf lets the whole internet reach remote desktop (port 3389) and does not block public access to a bucket. Fix both: restrict the network rule to a private range such as 10.0.0.0/8 and turn ALL FOUR public-access protections on. The scanner (Checkov) has to agree.'" "In the security group change cidr_blocks to [\"10.0.0.0/8\"]. In the aws_s3_bucket_public_access_block set block_public_acls, block_public_policy, ignore_public_acls and restrict_public_buckets all to true." <<'X'
rm -rf playground/aws-exam; mkdir -p playground/aws-exam; printf 'resource "aws_s3_bucket" "data" {\n  bucket = "exam-data"\n}\n\nresource "aws_s3_bucket_public_access_block" "data" {\n  bucket                  = aws_s3_bucket.data.id\n  block_public_acls       = false\n  block_public_policy     = false\n  ignore_public_acls      = false\n  restrict_public_buckets = false\n}\n\nresource "aws_security_group" "rdp" {\n  name = "open-rdp"\n  ingress {\n    from_port   = 3389\n    to_port     = 3389\n    protocol    = "tcp"\n    cidr_blocks = ["0.0.0.0/0"]\n  }\n}\n' > playground/aws-exam/main.tf
---
docker run --rm -v "$PWD:/tf:ro" bridgecrew/checkov:latest -d /tf/playground/aws-exam --framework terraform --quiet --check CKV_AWS_25,CKV_AWS_53,CKV_AWS_54,CKV_AWS_55,CKV_AWS_56 >/dev/null 2>&1
---
sed -i 's/= false/= true/; s#0.0.0.0/0#10.0.0.0/8#' playground/aws-exam/main.tf
X

interview "Spend safely" "Interviewer: 'Before anyone touches a real account I want a budget alarm. Write playground/aws-exam/budget.tf with an aws_budgets_budget that limits spending to 10 USD per month (limit_amount 10, limit_unit USD, time_unit MONTHLY, budget_type COST). The folder must pass terraform validate.'" "See the budget resource in 17-aws/envs/aws/main.tf. After writing the file, validate:  docker run --rm -v \"\$PWD/playground/aws-exam:/w\" -w /w hashicorp/terraform:1.9 init -backend=false  then  validate" <<'X'
rm -f playground/aws-exam/budget.tf; printf 'terraform {\n  required_providers {\n    aws = {\n      source  = "hashicorp/aws"\n      version = "~> 5.0"\n    }\n  }\n}\n' > playground/aws-exam/versions.tf
---
grep -q aws_budgets_budget playground/aws-exam/budget.tf && grep -q '"10"' playground/aws-exam/budget.tf && docker run --rm --entrypoint sh -v "$PWD/playground/aws-exam:/w" -w /w hashicorp/terraform:1.9 -c "terraform init -backend=false >/dev/null 2>&1 && terraform validate" >/dev/null 2>&1
---
printf 'resource "aws_budgets_budget" "monthly" {\n  name         = "exam-monthly"\n  budget_type  = "COST"\n  limit_amount = "10"\n  limit_unit   = "USD"\n  time_unit    = "MONTHLY"\n}\n' > playground/aws-exam/budget.tf
X

part "PART · MODULE FINAL"

final "Validate the real environment" "Exam 1 of 3. Validate the Terraform for the real AWS environment (17-aws/envs/aws) WITHOUT any AWS account, and save the result into playground/validate.txt. It must say the configuration is valid." "docker run --rm --entrypoint sh -v \"\$PWD:/w\" -w /w/17-aws/envs/aws hashicorp/terraform:1.9 -c \"terraform init -backend=false >/dev/null && terraform validate\" > playground/validate.txt" <<'X'
rm -f playground/validate.txt
---
grep -qi 'valid' playground/validate.txt
---
docker run --rm --entrypoint sh -v "$PWD:/w" -w /w/17-aws/envs/aws hashicorp/terraform:1.9 -c "terraform init -backend=false >/dev/null 2>&1 && terraform validate" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' > playground/validate.txt; rm -rf 17-aws/envs/aws/.terraform 17-aws/envs/aws/.terraform.lock.hcl
X

final "Scan the real environment" "Exam 2 of 3. Scan 17-aws/envs/aws with Checkov and save the summary into playground/checkov.txt. It must show 0 failed checks." "docker run --rm -v \"\$PWD:/tf:ro\" bridgecrew/checkov:latest -d /tf/17-aws/envs/aws --framework terraform --compact --quiet > playground/checkov.txt" <<'X'
rm -f playground/checkov.txt
---
grep -q 'Failed checks: 0' playground/checkov.txt
---
docker run --rm -v "$PWD:/tf:ro" bridgecrew/checkov:latest -d /tf/17-aws/envs/aws --framework terraform --compact --quiet > playground/checkov.txt 2>&1
X

final "Write your safety habits" "Exam 3 of 3. Write playground/habits.md: the cloud safety habits you will follow. It has to mention all four of: MFA, budget, destroy, and tags." "One short line each is enough." <<'X'
rm -f playground/habits.md
---
f=playground/habits.md; [ -f $f ] && for w in MFA budget destroy tags; do grep -qi "$w" $f || exit 1; done
---
printf 'Turn on MFA for the root account.\nCreate a budget alarm first.\nRun terraform destroy when I finish practising.\nPut tags on every resource.\n' > playground/habits.md
X
