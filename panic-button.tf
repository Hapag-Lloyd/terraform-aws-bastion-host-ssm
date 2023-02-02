resource "aws_iam_role" "lambda" {
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

data "archive_file" "panic_button_lambda_switch_off" {
  type        = "zip"
  source_file = local.panic_button_switch_off_lambda_source
  output_path = "builds/lambda_function_${local.panic_button_switch_off_lambda_source_sha256}.zip"
}

resource "aws_lambda_function" "panic_button_switch_off" {
  architectures    = ["arm64"]
  description      = "Terminates all bastion hosts forever"
  filename         = data.archive_file.panic_button_lambda_switch_off.output_path
  source_code_hash = data.archive_file.panic_button_lambda_switch_off.output_base64sha256
  function_name    = "${var.resource_names.prefix}${var.resource_names.separator}switch-off"
  handler          = "panic_button_switch_off.handler"
  memory_size      = 128
  package_type     = "Zip"
  publish          = true
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.8"
  timeout          = 30

  environment {
    variables = {
      BASTION_HOST_NAME = local.bastion_host_name
    }
  }

  tags = var.tags
}
