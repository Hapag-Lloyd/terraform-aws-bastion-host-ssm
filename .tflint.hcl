plugin "aws" {
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
    version = "0.32.0"

    enabled = true

    deep_check = false
}

rule "aws_resource_missing_tags" {
    enabled = true

    tags = []
    exclude = []
}

rule "aws_s3_bucket_name" {
    enabled = true

    regex = "^[0-9]+[a-z\\-]+$"
    }