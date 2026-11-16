# Native `terraform test` (plan-only, no cloud needed)
provider "aws" {
  region                      = "ap-south-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}
variables {
  name        = "devlab"
  environment = "test"
}
run "bucket_is_private_and_versioned" {
  command = plan
  assert {
    condition     = aws_s3_bucket_public_access_block.uploads.block_public_policy == true
    error_message = "bucket must block public policies"
  }
  assert {
    condition     = aws_s3_bucket_versioning.uploads.versioning_configuration[0].status == "Enabled"
    error_message = "versioning must be enabled"
  }
}
run "dlq_keeps_messages_14_days" {
  command = plan
  assert {
    condition     = aws_sqs_queue.dlq.message_retention_seconds == 1209600
    error_message = "DLQ must retain failed messages for 14 days"
  }
}
