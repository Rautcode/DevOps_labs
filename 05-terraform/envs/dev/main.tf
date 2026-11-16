terraform {
  required_version = ">= 1.6"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
  # Industry practice: remote state + locking (S3 + DynamoDB). Left as a module exercise: see README.
}

variable "endpoint" {
  description = "LocalStack URL"
  type        = string
  default     = "http://localhost:4566"
}

provider "aws" {
  region                      = "ap-south-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true
  endpoints {
    s3  = var.endpoint
    sqs = var.endpoint
    iam = var.endpoint
    sts = var.endpoint
  }
}

module "storage" {
  source      = "../../modules/storage"
  name        = "devlab"
  environment = "dev"
}

output "bucket" { value = module.storage.bucket }
output "queue_url" { value = module.storage.queue_url }
