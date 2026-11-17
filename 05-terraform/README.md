# 05 · Infrastructure as Code with Terraform (Intermediate, ~5h)

> **Guided version:** run `bash lab.sh 05` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** define cloud resources as reviewed, versioned, tested code. You use a **free local AWS emulator** so you learn real AWS APIs at zero cost.

| Path | What |
|---|---|
| [modules/storage](modules/storage/main.tf) | reusable module: private, encrypted, versioned S3 bucket, SQS queue + dead-letter queue, least-privilege IAM policy |
| [modules/storage/storage.tftest.hcl](modules/storage/storage.tftest.hcl) | `terraform test`: policy-as-tests, no cloud needed |
| [envs/dev](envs/dev/main.tf) | an environment that consumes the module (add `envs/prod` the same way) |
| [compose.localstack.yml](compose.localstack.yml) | the emulator |
| [tf.sh](tf.sh) | runs Terraform in Docker if you have not installed it |

> **LocalStack note.** Since March 2026 the *latest* LocalStack image requires an account/auth token. This lab pins `localstack/localstack:4.12` (the last tokenless version, no new fixes). Alternatives: Floci, or MinIO + moto. Everything here also works against a real AWS account by removing the `endpoints` block.

## Do it (from the repo root)
```bash
docker compose -f 05-terraform/compose.localstack.yml up -d
bash 05-terraform/tf.sh init
bash 05-terraform/tf.sh plan                     # READ it. Always read the plan.
bash 05-terraform/tf.sh apply -auto-approve      # ~1 min (the emulator is slow on lifecycle rules)
aws --endpoint-url=http://localhost:4566 --region ap-south-1 s3 ls     # needs AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
bash 05-terraform/tf.sh destroy -auto-approve
```
Native Terraform instead: `cd 05-terraform/envs/dev && terraform init && terraform apply`.

Run the module tests (no emulator needed):
```bash
docker run --rm --entrypoint sh -v "$PWD/05-terraform:/w" -w /w/modules/storage hashicorp/terraform:1.9 -c "terraform init -backend=false && terraform test"
```
**Check:** `Apply complete! Resources: 8 added` and `2 passed, 0 failed`.

## Concepts
- **Declarative + idempotent:** you describe the end state; applying twice changes nothing the second time. Try it.
- **State** maps code to real resources. It can contain secrets and must never be committed (`.gitignore` excludes it). Teams use a **remote backend with locking**.
- **Modules** = reusable building blocks with inputs/outputs; **environments** = thin callers.
- **Drift:** change the bucket by hand (`aws s3api put-bucket-versioning ... Suspended`), then `plan`: Terraform shows the drift and heals it.
- **Policy as code:** [Checkov](../09-security/README.md) found real gaps here (unencrypted SQS, no multipart-abort rule). They were fixed; the remaining ones are *documented suppressions* (`# checkov:skip=... reason`).

## Exercises
1. Add a `prod` environment with a different `environment` name and 90-day version retention (new variable, default 30).
2. Add a third `terraform test` that asserts the bucket name contains the environment.
3. Move state to a remote backend: create an S3 bucket + DynamoDB table in LocalStack, add a `backend "s3"` block with `endpoints`, run `terraform init -migrate-state`.
4. **Expert:** deploy this module to a real AWS free-tier account. Set a billing alarm *first*, use an IAM user with least privilege, never an admin key on your laptop (prefer SSO / OIDC).

## Industry notes
- `fmt`, `validate`, `plan`, `test` run in CI on every PR (module 04); `apply` only from `main`, after review.
- Pin provider versions (`~> 5.0`) and commit `.terraform.lock.hcl` in real projects.
- Tag every resource (`app`, `env`, `managed-by`): it powers cost allocation (FinOps).

**Next:** [06 · Kubernetes](../06-kubernetes/README.md)
