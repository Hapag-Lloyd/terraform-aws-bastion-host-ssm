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
  name              = var.resource_prefix
  description       = "Copy of ${data.aws_ami.latest_amazon_linux.name}"

  source_ami_id     = data.aws_ami.latest_amazon_linux.id
  source_ami_region = data.caller.region

  encrypted         = true

  tags = var.tags
}

resource "aws_security_group" "this" {
  name        = var.resource_prefix
  description = "Securing the bastion host"
  vpc_id      = var.vpc_id

  tags = var.tags
}

# allow outgoing traffic to the user defined ports
resource "aws_security_group_rule" "egress_open_ports" {
  count             = length(local.clean_open_port_list)

  security_group_id = aws_security_group.sg_bastion.id
  type              = "egress"

  from_port         = local.clean_open_port_list[count.index]
  to_port           = local.clean_open_port_list[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# need for SSM connection
resource "aws_security_group_rule" "egress_ssm" {
  security_group_id = aws_security_group.sg_bastion.id
  type              = "egress"
  description       = "allow HTTPS traffic"

  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

module "instance_profile_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 3.0"

  role_name               = var.resource_prefix
  role_description = "Instance profile for the bastion host to be able to connect to the machine"
  role_path = var.iam_role_path

  create_role             = true
  create_instance_profile = true
  # MFA makes no sense here. It's used for EC2 instances.
  role_requires_mfa       = false

  trusted_role_services = ["ec2.amazonaws.com"]
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/EC2InstanceConnect",
  ]

  tags = var.tags
}
