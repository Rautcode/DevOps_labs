# OPTIONAL, advanced: let GitHub Actions deploy to AWS WITHOUT any stored access keys (OIDC).
# GitHub proves its identity with a short-lived token; AWS trusts it for ONE repository only.
# Disabled unless you set  github_repo = "your-user/your-repo".
variable "github_repo" {
  description = "owner/repo allowed to assume the deploy role. Empty = feature off."
  type        = string
  default     = ""
}

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.github_repo == "" ? 0 : 1
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_trust" {
  count = var.github_repo == "" ? 0 : 1
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  count              = var.github_repo == "" ? 0 : 1
  name               = "${var.name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_trust[0].json
}

resource "aws_iam_role_policy_attachment" "github_deploy_storage" {
  count      = var.github_repo == "" ? 0 : 1
  role       = aws_iam_role.github_deploy[0].name
  policy_arn = module.storage.policy_arn # least privilege: only the storage policy, never admin
}
