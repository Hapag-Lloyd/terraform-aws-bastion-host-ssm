resource "aws_iam_role" "panic_button_on_execution" {
  count = var.enable_panic_switches ? 1 : 0

  name                  = "${var.resource_names.prefix}${var.resource_names.separator}panic-button-on"
  description           = "Role for executing the bastion panic button switch off"
  assume_role_policy    = data.aws_iam_policy_document.panic_button_on_assume_role[0].json
  force_detach_policies = true

  tags = var.tags
}

data "aws_iam_policy_document" "panic_button_on_assume_role" {
  count = var.enable_panic_switches ? 1 : 0

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
  count = var.enable_panic_switches ? 1 : 0

  statement {
    sid       = "UpdateASG"
    actions   = ["autoscaling:UpdateAutoScalingGroup", "autoscaling:BatchDeleteScheduledAction"]
    resources = [aws_autoscaling_group.this.arn]
    effect    = "Allow"
  }

  statement {
    sid       = "DescribeASG"
    actions   = ["autoscaling:DescribeScheduledActions"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "panic_button_on" {
  count = var.enable_panic_switches ? 1 : 0

  name   = "${var.resource_names.prefix}${var.resource_names.separator}switch-on"
  policy = data.aws_iam_policy_document.panic_button_on[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "panic_button_on" {
  count = var.enable_panic_switches ? 1 : 0

  role       = aws_iam_role.panic_button_on_execution[0].name
  policy_arn = aws_iam_policy.panic_button_on[0].arn
}

resource "aws_iam_role_policy_attachment" "panic_button_on_basic_execution" {
  count = var.enable_panic_switches ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.panic_button_on_execution[0].id
}

resource "aws_iam_role_policy_attachment" "panic_button_on_x_ray" {
  count = var.enable_panic_switches ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.panic_button_on_execution[0].id
}

data "archive_file" "panic_button_on_package" {
  count = var.enable_panic_switches ? 1 : 0

  type        = "zip"
  source_file = local.panic_button_switch_on_lambda_source
  output_path = "${path.root}/builds/${local.panic_button_switch_on_lambda_source_file_name}.zip"
}

resource "aws_lambda_function" "panic_button_on" {
  count = var.enable_panic_switches ? 1 : 0

  architectures    = ["arm64"]
  description      = "Start all bastion hosts immediately"
  filename         = data.archive_file.panic_button_on_package[0].output_path
  source_code_hash = data.archive_file.panic_button_on_package[0].output_base64sha256
  function_name    = local.panic_button_switch_on_lambda_name
  handler          = "panic_button_switch_on.handler"
  timeout          = 30
  memory_size      = 256
  package_type     = "Zip"
  publish          = true
  role             = aws_iam_role.panic_button_on_execution[0].arn
  runtime          = "python3.13"

  environment {
    variables = {
      AUTO_SCALING_GROUP_NAME             = aws_autoscaling_group.this.name
      AUTO_SCALING_GROUP_MIN_SIZE         = aws_autoscaling_group.this.min_size
      AUTO_SCALING_GROUP_MAX_SIZE         = aws_autoscaling_group.this.max_size
      AUTO_SCALING_GROUP_DESIRED_CAPACITY = aws_autoscaling_group.this.desired_capacity

      LOG_LEVEL = "info"
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags

  # otherwise the Lambda auto-creates the group which conflicts with Terraform
  depends_on = [aws_cloudwatch_log_group.panic_button_on[0]]
}

resource "aws_cloudwatch_log_group" "panic_button_on" {
  count = var.enable_panic_switches ? 1 : 0

  name              = "/aws/lambda/${local.panic_button_switch_on_lambda_name}"
  retention_in_days = var.log_group_retention_days

  kms_key_id = var.kms_key_arn

  tags = var.tags
}
