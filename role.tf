resource "aws_iam_role" "access_bastion" {
  name        = var.resource_names.prefix
  description = "Role used to connect to the bastion instance."

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "sts:AssumeRole",
        Principal = { "AWS" : var.iam_user_arns }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "access_bastion" {
  role       = aws_iam_role.access_bastion.name
  policy_arn = aws_iam_policy.access_bastion.arn
}

resource "aws_iam_policy" "access_bastion" {
  name        = var.resource_names.prefix
  path        = var.iam_role_path
  description = "Allows the access to the bastion host."

  policy = data.aws_iam_policy_document.access_bastion.json

  tags = var.tags
}

data "aws_iam_policy_document" "access_bastion" {
  statement {
    sid    = "Ec2FindBastion"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = [
      "*"
    ]
  }

  # not critical as we use a condition and thus allowing a very limited number of resources only
  # tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    sid    = "SSHBastion"
    effect = "Allow"
    actions = [
      "ec2-instance-connect:SendSSHPublicKey",
      "ssm:StartSession"
    ]
    resources = ["*"]

    condition {
      test     = "ForAnyValue:StringEqualsIfExists"
      values   = [var.bastion_access_tag_value]
      variable = "aws:ResourceTag/bastion-access"
    }
  }

  statement {
    sid    = "SsmStartSession"
    effect = "Allow"
    actions = [
      "ssm:StartSession"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.this.name}::document/AWS-StartSSHSession"
    ]
  }

  statement {
    sid    = "SsmGetDocument"
    effect = "Allow"
    actions = [
      "ssm:GetDocument",
    ]
    resources = [
      "arn:aws:ssm:::document/SSM-SessionManagerRunShell"
    ]
  }

  # terminate session is not critical
  # tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    sid    = "SsmTerminateSession"
    effect = "Allow"
    actions = [
      "ssm:TerminateSession",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "ManipulateSchedule"
    effect = "Allow"
    actions = [
      "autoscaling:BatchDeleteScheduledAction"
    ]
    resources = [
      var.instance.enable_spot ? aws_autoscaling_group.on_spot.arn : aws_autoscaling_group.on_demand.arn
    ]
  }

  statement {
    sid    = "SsmDescribeSSMConnection"
    effect = "Allow"
    actions = [
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus",
      "ssm:DescribeInstanceProperties",
    ]
    resources = [
      "*"
    ]
  }
}
