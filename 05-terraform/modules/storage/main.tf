# Reusable module: private, encrypted, versioned bucket for uploads + a work queue with a dead-letter queue.
terraform {
  required_version = ">= 1.6"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}

variable "name" { type = string }
variable "environment" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

locals { tags = merge(var.tags, { app = "devlab", env = var.environment, managed-by = "terraform" }) }

resource "aws_s3_bucket" "uploads" {
  # checkov:skip=CKV_AWS_144: cross-region replication is a prod-only cost; enable per environment
  # checkov:skip=CKV_AWS_145: SSE-S3 (AES256) is enough for the lab; use a KMS key in prod
  # checkov:skip=CKV_AWS_18: access logging needs a separate log bucket; added in the prod module
  # checkov:skip=CKV2_AWS_62: no event consumers yet
  bucket = "${var.name}-${var.environment}-uploads"
  tags   = local.tags
}
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-${var.environment}-leads-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
  tags                      = local.tags
}
resource "aws_sqs_queue" "leads" {
  name                       = "${var.name}-${var.environment}-leads"
  visibility_timeout_seconds = 60
  sqs_managed_sse_enabled    = true
  redrive_policy             = jsonencode({ deadLetterTargetArn = aws_sqs_queue.dlq.arn, maxReceiveCount = 5 })
  tags                       = local.tags
}

# Least privilege: the API may only touch its own bucket objects and queue.
data "aws_iam_policy_document" "api" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]
  }
  statement {
    actions   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"]
    resources = [aws_sqs_queue.leads.arn]
  }
}
resource "aws_iam_policy" "api" {
  name   = "${var.name}-${var.environment}-api"
  policy = data.aws_iam_policy_document.api.json
  tags   = local.tags
}

output "bucket" { value = aws_s3_bucket.uploads.id }
output "queue_url" { value = aws_sqs_queue.leads.url }
output "policy_arn" { value = aws_iam_policy.api.arn }
