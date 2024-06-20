locals {
  terraform_cloud_role_name = "terraform-cloud-automatiom-admin"
  amdnin_policy_arn         = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "tls_certificate" "terraform_cloud" {
  url = "https://${var.terraform_cloud_hostname}"
}

# imported
resource "aws_iam_openid_connect_provider" "terraform_cloud" {
  url             = data.tls_certificate.terraform_cloud.url
  client_id_list  = [var.terraform_cloud_audience]
  thumbprint_list = var.openid_provider_certs

  tags = local.common_tags
}

data "aws_iam_policy_document" "terraform_cloud_admin_assume_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.terraform_cloud.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringLike"
      variable = "${var.terraform_cloud_hostname}:sub"
      values   = ["organization:AmitsMizs:project:devops-training-infra:workspace:main:run_phase:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.terraform_cloud_hostname}:aud"
      values   = [var.terraform_cloud_audience]
    }
  }
}

#imported
resource "aws_iam_role" "terraform_cloud_admin" {
  name               = local.terraform_cloud_role_name
  assume_role_policy = data.aws_iam_policy_document.terraform_cloud_admin_assume_policy.json
}

data "aws_iam_policy" "admin" {
  arn = local.amdnin_policy_arn
}

#imported
resource "aws_iam_role_policy_attachment" "terraform_cloud_admin" {
  role       = aws_iam_role.terraform_cloud_admin.name
  policy_arn = data.aws_iam_policy.admin.arn
}
