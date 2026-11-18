# Real cloud (AWS): safely, with budgets and security checks (about 2h)
title "Module 17 · Real cloud: AWS"
mission "Everything so far was free and local. A real cloud account can send a real bill. Your mission: learn to deploy safely, with budgets, least-privilege permissions and automatic checks, before you ever click create."
explain "Everything so far ran on your computer. This module is the bridge to a REAL cloud account. The danger is not difficulty, it is the BILL: a forgotten resource keeps charging you. So you learn the safety habits first, practise security scanning on code with NO account needed, and only then (optionally) apply to a real account with a budget alarm in place."

part "PART A · Safety habits (before you create anything)"
explain "The five habits that stop surprise bills and breaches:"
explain "  1. Turn on MFA for the root account, then NEVER use root again: make an admin identity (IAM Identity Center / SSO)."
explain "  2. Create a BUDGET alarm first. This module's Terraform does it for you."
explain "  3. Use only free-tier or tiny resources, in one region, with tags on everything."
explain "  4. Never put access keys in git. Prefer short-lived logins (SSO) and OIDC for pipelines."
explain "  5. 'terraform destroy' when you finish practising. Check the console for leftovers."
quiz "A beginner leaves a managed database running for a month by accident. Which habit above would have caught it first?" "budget|alarm|alert|destroy|tag|email" "The budget alarm (and the habit of running terraform destroy). A budget emails you when spending passes a limit, before the bill gets large."
step "Is this computer connected to an AWS account yet?" "Either your account id, or 'No AWS account connected yet'. Both are fine: the rest of the lesson works without one." ok 'Account|No AWS account' <<'CMD'
aws sts get-caller-identity --output json 2>/dev/null | grep -E '"Account"' || echo "No AWS account connected yet (fine for now: see 17-aws/README.md when you are ready)"
CMD

part "PART B · Read and validate the real-AWS Terraform (no account needed)"
learn "Same code, different target" "The storage module is exactly the one you tested on LocalStack. Only the provider changes. That is the value of practising locally first. On a real account every resource can cost money, so safety habits come first."
art "LocalStack vs real AWS" <<'ART'
   same Terraform code
      |-- endpoint = LocalStack (free, on your laptop)   <- you practised here
      |-- endpoint = real AWS   (real money, real risk)  <- budget + checks first
ART
step "The real environment reuses the module you tested in module 05" "source = \"../../../05-terraform/modules/storage\": the SAME module. Only the provider (real AWS instead of LocalStack) changes." ok 'modules/storage' <<'CMD'
grep -n "source\|budget" 17-aws/envs/aws/main.tf | head -8
CMD
step "Format check and validate" "Success! The configuration is valid. (validate needs no AWS login)" ok 'valid' <<'CMD'
docker run --rm --entrypoint sh -v "$PWD:/w" -w /w/17-aws/envs/aws hashicorp/terraform:1.9 -c "terraform fmt -check -recursive /w/17-aws && terraform init -backend=false >/dev/null && terraform validate" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tail -2; rm -rf 17-aws/envs/aws/.terraform 17-aws/envs/aws/.terraform.lock.hcl
CMD
step "Scan the real AWS code for security problems (Checkov)" "Passed checks: 49, Failed checks: 0. Remaining skips are documented with a reason in the module." ok 'Failed checks: 0' <<'CMD'
docker run --rm -v "$PWD:/tf:ro" bridgecrew/checkov:latest -d /tf/17-aws/envs/aws --framework terraform --compact --quiet 2>&1 | grep -E "Passed checks"
CMD
step "See the budget alarm in the code" "A monthly budget of USD 5 that emails you at 80% of actual spend and when the forecast passes 100%." ok 'aws_budgets_budget' <<'CMD'
grep -n -A6 'resource "aws_budgets_budget"' 17-aws/envs/aws/main.tf
CMD

part "PART C · Find and fix cloud security mistakes"
explain "17-aws/exercises/risky.tf has three of the most common real-world cloud mistakes: a storage bucket that could be public, SSH open to the whole internet, and an admin policy that allows everything."
learn "Policy as code" "Security scanners read your infrastructure code and flag dangerous settings before anything exists: a public bucket, SSH open to the whole internet, an admin policy that allows everything. A fix is a small code change, reviewed like any other."
step "Scan the risky file" "4 failed checks: SSH open to 0.0.0.0/0, a policy with '*' actions, a policy with '*' resources, and a bucket with no public access block. This is exactly what a security reviewer looks for." fail 'Failed checks: 4' <<'CMD'
docker run --rm -v "$PWD:/tf:ro" bridgecrew/checkov:latest -d /tf/17-aws/exercises --framework terraform --compact --quiet --check CKV_AWS_24,CKV2_AWS_6,CKV_AWS_355,CKV_AWS_63 2>&1 | grep -E "Failed checks|Check:"; exit 1
CMD
task "Fix the three mistakes" "Copy the file:  mkdir -p playground/aws-fix && cp 17-aws/exercises/risky.tf playground/aws-fix/main.tf   Then edit playground/aws-fix/main.tf so that: (1) the SSH rule only allows a private network like 10.0.0.0/8, (2) the IAM policy allows only the action s3:GetObject on the resource arn:aws:s3:::devlab-risky-data/*, (3) an aws_s3_bucket_public_access_block resource for the bucket sets all four block_*/ignore_*/restrict_* options to true. Then scan it:  docker run --rm -v \"\$PWD:/tf:ro\" bridgecrew/checkov:latest -d /tf/playground/aws-fix --framework terraform --compact --quiet --check CKV_AWS_24,CKV2_AWS_6,CKV_AWS_355,CKV_AWS_63" "The scan must report 4 passed and 0 failed. Public access block options: block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets." <<'X'
docker run --rm -v "$PWD:/tf:ro" bridgecrew/checkov:latest -d /tf/playground/aws-fix --framework terraform --quiet --check CKV_AWS_24,CKV2_AWS_6,CKV_AWS_355,CKV_AWS_63 >/dev/null 2>&1
---
mkdir -p playground/aws-fix && printf '%s\n' 'resource "aws_s3_bucket" "data" {' '  bucket = "devlab-risky-data"' '}' '' 'resource "aws_s3_bucket_public_access_block" "data" {' '  bucket                  = aws_s3_bucket.data.id' '  block_public_acls       = true' '  block_public_policy     = true' '  ignore_public_acls      = true' '  restrict_public_buckets = true' '}' '' 'resource "aws_security_group" "ssh" {' '  name = "office-ssh"' '  ingress {' '    from_port   = 22' '    to_port     = 22' '    protocol    = "tcp"' '    cidr_blocks = ["10.0.0.0/8"]' '  }' '}' '' 'resource "aws_iam_policy" "read_data" {' '  name = "read-data"' '  policy = jsonencode({' '    Version = "2012-10-17"' '    Statement = [{' '      Effect   = "Allow"' '      Action   = ["s3:GetObject"]' '      Resource = "arn:aws:s3:::devlab-risky-data/*"' '    }]' '  })' '}' > playground/aws-fix/main.tf
X
quiz "Why is an IAM policy with Action \"*\" and Resource \"*\" dangerous?" "everything|admin|full|too much|least|blast|compromis|any|all" "It grants every permission on every resource. If those credentials leak, the attacker owns the whole account. Grant only the actions and resources a job truly needs (least privilege)."

part "PART D · OPTIONAL: apply to a real AWS account"
explain "Only if you have an AWS account with a budget and MFA set up (see 17-aws/README.md). Skip this part otherwise: you lose nothing. The commands are safe by design: a small budget alarm, a private versioned bucket and a queue, all removable with one destroy."
step "Plan against real AWS (only runs if an account is connected)" "If connected: 'Plan: 11 to add' (bucket pieces, queues, policy, budget). If not: a friendly message." ok 'Plan:|not connected|No AWS' <<'CMD'
if aws sts get-caller-identity >/dev/null 2>&1; then lab-tf-aws init >/dev/null && lab-tf-aws plan -var name=devlab-$USERNAME -var budget_email=you@example.com 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "Plan:|Error" ; else echo "not connected: skipping (that is fine)"; fi
CMD
OPT=1 task "Apply, look in the AWS console, then DESTROY" "With a connected account: run  bash 17-aws/tf-aws.sh apply -var name=devlab-<yourname> -var budget_email=<your email>  (read the plan, type yes). Open the AWS console: S3, SQS and Budgets. Then ALWAYS clean up:  bash 17-aws/tf-aws.sh destroy -var name=devlab-<yourname> -var budget_email=<your email>" "Not required. Press s to skip." <<'X'
false
---
true
X

deeper "AWS DevOps Zero to Hero, 30 days (Abhishek Veeramalla)|https://github.com/iam-veeramalla/aws-devops-zero-to-hero" "aws-zero-to-hero (Shubham Londhe)|https://github.com/LondheShubham153/aws-zero-to-hero"
explain "Done! You have finished all lessons. Run  bash lab.sh down  to stop everything."
