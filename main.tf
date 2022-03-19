# find the latest Amazon Linux AMI and create a copy to be sure that is it present
data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_ami_copy" "latest_amazon_linux" {
  name              = "${var.resource_prefix}-${data.aws_ami.latest_amazon_linux.name}"
  description       = "Copy of ${data.aws_ami.latest_amazon_linux.name}"

  source_ami_id     = data.aws_ami.latest_amazon_linux.id
  source_ami_region = data.caller.region

  encrypted         = true

  tags = var.tags
}
