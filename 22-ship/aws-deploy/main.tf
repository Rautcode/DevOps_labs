# OPTIONAL, real AWS: run the two app containers on one small server and reach them from the internet.
# This costs money unless your account is within the free tier. Read 22-ship/README.md before you apply,
# set a budget first (module 17), and ALWAYS run destroy afterwards.
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
  type    = string
  default = "ap-south-1"
}

variable "github_owner" {
  description = "Your GitHub user name (lower case). The images are pulled from ghcr.io/<owner>/devlab-api and devlab-web (make those packages public)."
  type        = string
}

variable "image_tag" {
  description = "The release tag you pushed (module 22), without the v, for example 0.1.0"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
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

# Latest Amazon Linux 2023, looked up by AWS so the code never holds a stale image id
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "web" {
  name        = "devlab-web"
  description = "HTTP from the internet; no SSH at all (use AWS Systems Manager to get a shell)"

  ingress {
    description = "public website"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #checkov:skip=CKV_AWS_260: this is a public website on purpose
  }

  egress {
    description = "HTTPS for package and image downloads and AWS Systems Manager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP for the Amazon Linux package repositories"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A role so you can open a shell with AWS Systems Manager Session Manager instead of exposing SSH
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "devlab-web"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web" {
  name = "devlab-web"
  role = aws_iam_role.web.name
}

resource "aws_instance" "web" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name
  monitoring             = true
  ebs_optimized          = true

  metadata_options {
    http_tokens = "required" # IMDSv2 only: blocks a common credential-theft trick
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
  }

  # The secrets are generated ON the server, so they never appear in this file, in git or in Terraform state.
  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    dnf install -y docker
    systemctl enable --now docker
    docker network create devlab
    JWT=$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')
    ADMIN=$(head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n')
    docker run -d --name api --network devlab --restart unless-stopped \
      -e JWT_SECRET="$JWT" -e ADMIN_PASSWORD="$ADMIN" \
      ghcr.io/${var.github_owner}/devlab-api:${var.image_tag}
    docker run -d --name web --network devlab --restart unless-stopped -p 80:8080 \
      -e API_UPSTREAM=api:5000 \
      ghcr.io/${var.github_owner}/devlab-web:${var.image_tag}
  EOT

  tags = {
    Name = "devlab-web"
  }
}

output "website" {
  value = "http://${aws_instance.web.public_ip}"
}
