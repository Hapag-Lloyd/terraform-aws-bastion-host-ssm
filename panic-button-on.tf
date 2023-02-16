resource "aws_iam_role" "panic_button_on_execution" {
  name                  = "${var.resource_names.prefix}${var.resource_names.separator}panic-button-on"
  description           = "Role for executing the bastion panic button switch off"
  assume_role_policy    = data.aws_iam_policy_document.panic_button_on_assume_role.json
  force_detach_policies = true

  tags = var.tags
}

data "aws_iam_policy_document" "panic_button_on_assume_role" {
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

data "aws_iam_policy_document" "panic_button_on" {
  statement {
    sid="UpdateASG"
    actions = ["autoscaling:UpdateAutoScalingGroup", "autoscaling:DeleteScheduledAction"]
    resources = [local.auto_scaling_group.arn]
    effect = "Allow"
  }

  statement {
    sid="DescribeASG"
    actions = ["autoscaling:DescribeScheduledActions"]
    resources = ["*"]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "panic_button_on" {
  name   = "${var.resource_names.prefix}${var.resource_names.separator}switch-on"
  policy = data.aws_iam_policy_document.panic_button_on.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "panic_button_on" {
  role       = aws_iam_role.panic_button_on_execution.name
  policy_arn = aws_iam_policy.panic_button_on.arn
}

resource "aws_iam_role_policy_attachment" "panic_button_on_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.panic_button_on_execution.id
}

resource "aws_iam_role_policy_attachment" "panic_button_on_x_ray" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.panic_button_on_execution.id
}

data "archive_file" "panic_button_on_package" {
  type        = "zip"
  source_file = local.panic_button_switch_on_lambda_source
  output_path = "${path.root}/builds/${local.panic_button_switch_on_lambda_source_file_name}.zip"
}

resource "aws_lambda_function" "panic_button_on" {
  architectures    = ["arm64"]
  description      = "Start all bastion hosts immediately"
  filename         = data.archive_file.panic_button_on_package.output_path
  source_code_hash = data.archive_file.panic_button_on_package.output_base64sha256
  function_name    = local.panic_button_switch_on_lambda_name
  handler          = "panic_button_switch_on.handler"
  timeout          = 30
  memory_size      = 256
  package_type     = "Zip"
  publish          = true
  role             = aws_iam_role.panic_button_on_execution.arn
  runtime          = "python3.9"

  environment {
    variables = {
      AUTO_SCALING_GROUP_NAME = local.auto_scaling_group.name
      AUTO_SCALING_GROUP_MIN_SIZE = local.auto_scaling_group.min_size
      AUTO_SCALING_GROUP_MAX_SIZE = local.auto_scaling_group.max_size
      AUTO_SCALING_GROUP_DESIRED_CAPACITY = local.auto_scaling_group.desired_capacity

      LOG_LEVEL = "info"
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags

  # otherwise the Lambda auto-creates the group which conflicts with Terraform
  depends_on = [aws_cloudwatch_log_group.panic_button_on]
}

resource "aws_cloudwatch_log_group" "panic_button_on" {
  name              = "/aws/lambda/${local.panic_button_switch_on_lambda_name}"
  retention_in_days = 3

  kms_key_id = var.kms_key_arn

  tags = var.tags
}
