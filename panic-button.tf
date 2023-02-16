resource "aws_iam_role" "lambda_switch_off" {
  name                  = "${var.resource_names.prefix}${var.resource_names.separator}panic-button-off"
  description           = "Role for executing the bastion panic button switch off"
  path                  = "/"
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
    sid = "KillBastionHosts"
    actions = [
      "ec2:DescribeInstances",
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
}

resource "aws_iam_policy" "lambda_switch_off" {
  name   = "${var.resource_names.prefix}${var.resource_names.separator}switch-off"
  policy = data.aws_iam_policy_document.lambda_switch_off.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_switch_off" {
  role       = aws_iam_role.lambda_switch_off.name
  policy_arn = aws_iam_policy.lambda_switch_off.arn
}

data "archive_file" "panic_button_lambda_switch_off" {
  type        = "zip"
  source_file = local.panic_button_switch_off_lambda_source
  output_path = "builds/${local.panic_button_switch_off_lambda_source_file_name}.zip"
}

resource "aws_lambda_function" "panic_button_switch_off" {
  architectures    = ["arm64"]
  description      = "Terminates all bastion hosts forever"
  filename         = data.archive_file.panic_button_lambda_switch_off.output_path
  source_code_hash = filebase64sha256(data.archive_file.panic_button_lambda_switch_off.output_path)
  function_name    = "${var.resource_names.prefix}${var.resource_names.separator}switch-off"
  handler          = "panic_button_switch_off.handler"
  memory_size      = 128
  package_type     = "Zip"
  publish          = true
  role             = aws_iam_role.lambda_switch_off.arn
  runtime          = "python3.8"
  timeout          = 30

  environment {
    variables = {
      AUTO_SCALING_GROUP_NAME = var.instance.enable_spot ? aws_autoscaling_group.on_demand[0].name : aws_autoscaling_group.on_demand[0].name
      BASTION_HOST_NAME = local.bastion_host_name

      LOG_LEVEL = "info"
    }
  }

  tracing_config {
    mode = "Passthrough"
  }

  tags = var.tags
}
