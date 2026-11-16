# EXERCISE: this file contains three classic cloud security mistakes. Do NOT apply it.
# Your job (in the lesson): copy it to playground/aws-fix/main.tf and fix the problems until the scanner is happy.
resource "aws_s3_bucket" "data" {
  bucket = "devlab-risky-data"
}

resource "aws_security_group" "ssh" {
  name = "open-ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_policy" "admin" {
  name = "everything"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}
