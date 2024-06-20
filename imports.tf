import {
  to = aws_iam_openid_connect_provider.terraform_cloud
  id = var.provider_arn
}

import {
  to = aws_iam_role.terraform_cloud_admin
  id = local.terraform_cloud_role_name
}

import {
  to = aws_iam_role_policy_attachment.terraform_cloud_admin
  id = "${aws_iam_role.terraform_cloud_admin.name}/${data.aws_iam_policy.admin.arn}"
}
