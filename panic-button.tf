resource "aws_iam_role" "lambda_switch_off_execution" {
  name                  = "${var.resource_names.prefix}${var.resource_names.separator}panic-button-off"
  description           = "Role for executing the bastion panic button switch off"
  assume_role_policy    = data.aws_iam_policy_document.lambda_assume_role.json
  force_detach_policies = true

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "lambda_switch_off" {
  statement {
    sid = "ListInstances"
    actions = [
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
    effect = "Allow"
  }

  statement {
    sid = "KillBastionHosts"
    actions = [
      "ec2:StopInstances"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [local.bastion_host_name]
      variable = "aws:ResourceTag/Name"
    }
    effect = "Allow"
  }

  statement {
    sid="UpdateASG"
    actions = ["autoscaling:UpdateAutoScalingGroup"]
    resources = [var.instance.enable_spot ? aws_autoscaling_group.on_spot[0].arn : aws_autoscaling_group.on_demand[0].arn]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "lambda_switch_off" {
  name   = "${var.resource_names.prefix}${var.resource_names.separator}switch-off"
  policy = data.aws_iam_policy_document.lambda_switch_off.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_switch_off" {
  role       = aws_iam_role.lambda_switch_off_execution.name
  policy_arn = aws_iam_policy.lambda_switch_off.arn
}

resource "aws_iam_role_policy_attachment" "gitlab_webhook_authorizer_execution_lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_switch_off_execution.id
}

resource "aws_iam_role_policy_attachment" "gitlab_webhook_authorizer_execution_xray" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.lambda_switch_off_execution.id
}

data "archive_file" "panic_button_lambda_switch_off_package" {
  type        = "zip"
  source_file = local.panic_button_switch_off_lambda_source
  output_path = "${path.root}/builds/${local.panic_button_switch_off_lambda_source}.zip"
}

resource "aws_lambda_function" "panic_button_switch_off" {
  architectures    = ["arm64"]
  description      = "Terminates all bastion hosts forever"
  filename         = data.archive_file.panic_button_lambda_switch_off_package.output_path
  source_code_hash = data.archive_file.panic_button_lambda_switch_off_package.output_base64sha256
  function_name    = "${var.resource_names.prefix}${var.resource_names.separator}switch-off"
  handler          = "panic_button_switch_off.handler"
  timeout          = 30
  memory_size      = 256
  #package_type     = "Zip"
  publish          = true
  role             = aws_iam_role.lambda_switch_off_execution.arn
  runtime          = "python3.9"

  environment {
    variables = {
      AUTO_SCALING_GROUP_NAME = var.instance.enable_spot ? aws_autoscaling_group.on_spot[0].name : aws_autoscaling_group.on_demand[0].name
      BASTION_HOST_NAME = local.bastion_host_name

      LOG_LEVEL = "info"
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}
