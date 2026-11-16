# The SAME storage module from module 05, but pointed at a REAL AWS account.
# SAFETY FIRST: it also creates a budget alarm, so a surprise bill gets an email.
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "region" {
  description = "AWS region (ap-south-1 = Mumbai)"
  type        = string
  default     = "ap-south-1"
}

variable "name" {
  description = "Short, globally unique prefix, for example devlab-yourname (S3 bucket names are shared by everyone on AWS)"
  type        = string
}

variable "budget_email" {
  description = "Where to send the budget alert"
  type        = string
}

variable "monthly_budget_usd" {
  description = "Alert when spending passes 80% of this"
  type        = number
  default     = 5
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project    = "devlab"
      managed-by = "terraform"
    }
  }
}

module "storage" {
  source      = "../../../05-terraform/modules/storage"
  name        = var.name
  environment = "aws"
}

resource "aws_budgets_budget" "monthly" {
  name         = "${var.name}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_email]
  }
}

output "bucket" {
  value = module.storage.bucket
}

output "queue_url" {
  value = module.storage.queue_url
}
