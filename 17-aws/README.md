# 17 · Real cloud: AWS (Specialist, ~2h)

> **Guided version:** run `bash lab.sh 17` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** bridge from your laptop to a real cloud account **without a surprise bill**: safety habits first, security scanning with no account needed, and an optional, budget-protected apply.

| File | What it is |
|---|---|
| [envs/aws/main.tf](envs/aws/main.tf) | the SAME storage module as module 05, on real AWS, plus a **budget alarm** |
| [envs/aws/github-oidc.tf](envs/aws/github-oidc.tf) | optional: let GitHub Actions deploy with **no stored keys** (OIDC), limited to one repo |
| [exercises/risky.tf](exercises/risky.tf) | three classic cloud mistakes for you to find and fix |
| [tf-aws.sh](tf-aws.sh) | runs Terraform for real AWS in Docker using your `~/.aws` login |

## What is verified here
Without an AWS account: `terraform fmt` + `validate`, a Checkov scan of the real environment (49 passed, 0 failed), and the risky-file exercise (4 failures before the fix, 4 passes after). **Not run by the lab author:** `plan`/`apply`/`destroy` against a real account.

## Before you touch a real account: the checklist
1. Create an AWS account, enable **MFA on the root user**, then stop using root.
2. Create an admin identity with **IAM Identity Center (SSO)** and log in with `aws configure sso` (short-lived credentials, no long-term keys).
3. Confirm: `aws sts get-caller-identity`.
4. Use a **tiny budget** (the Terraform creates one for USD 5) and a verified email address.
5. Use one region, free-tier or tiny resources, tags on everything.

## Apply (optional) and ALWAYS destroy
```bash
bash 17-aws/tf-aws.sh init
bash 17-aws/tf-aws.sh plan    -var name=devlab-yourname -var budget_email=you@example.com
bash 17-aws/tf-aws.sh apply   -var name=devlab-yourname -var budget_email=you@example.com
# look in the AWS console: S3, SQS, Budgets
bash 17-aws/tf-aws.sh destroy -var name=devlab-yourname -var budget_email=you@example.com
```
Then check the console for leftovers (Billing → Cost Explorer next day).

## Concepts
- **Same code, different target:** only the provider changes between LocalStack and AWS. That is why practising locally is valuable.
- **Cost control** is a skill: budgets, tags, destroy habits, and knowing which services bill by the hour (databases, NAT gateways, load balancers, Kubernetes control planes).
- **Identity:** SSO for humans, OIDC roles for pipelines, least-privilege policies for apps. Never long-lived keys in git.
- **Shift-left security:** the scanner finds public buckets, `0.0.0.0/0` SSH and `*:*` policies before they exist.

## Stretch goals
- Add a remote state backend (S3 + DynamoDB lock) with encryption.
- Deploy the app to a small EC2 instance or ECS Fargate with the images from module 04's release workflow.
- Enable the GitHub OIDC role (`-var github_repo=you/repo`) and deploy from Actions with no stored keys.
- Repeat on Azure or GCP and compare the concepts.

## Industry notes
- Use separate accounts per environment (AWS Organizations) and service control policies as guardrails.
- Turn on CloudTrail, GuardDuty and AWS Config early; they are cheap compared with an incident.
- Tag policy + cost allocation tags make FinOps possible.

**You have completed all modules.** Review [11 · Capstone](../11-capstone/README.md)'s readiness checklist against what you now know.
