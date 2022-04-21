data "aws_region" "this" {
}

# find the latest Amazon Linux AMI and create a copy to be sure that is it present
data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_ami_copy" "latest_amazon_linux" {
  name        = var.resource_names["prefix"]
  description = "Copy of ${data.aws_ami.latest_amazon_linux.name}"

  source_ami_id     = data.aws_ami.latest_amazon_linux.id
  source_ami_region = data.aws_region.this.name

  encrypted  = true
  kms_key_id = var.kms_key_id

  tags = var.tags
}

resource "aws_security_group" "this" {
  name        = var.resource_names["prefix"]
  description = "Securing the bastion host"
  vpc_id      = var.vpc_id

  tags = var.tags
}

# allow outgoing traffic to the user defined ports
resource "aws_security_group_rule" "egress_open_ports" {
  count = length(local.clean_egress_open_tcp_ports)

  security_group_id = aws_security_group.this.id
  type              = "egress"
  description       = "User defined rule to open the port"

  from_port = local.clean_egress_open_tcp_ports[count.index]
  to_port   = local.clean_egress_open_tcp_ports[count.index]
  protocol  = "tcp"
  # tfsec:ignore:aws-vpc-no-public-egress-sgr
  cidr_blocks = ["0.0.0.0/0"]
}

# need for SSM connection
resource "aws_security_group_rule" "egress_ssm" {
  security_group_id = aws_security_group.this.id
  type              = "egress"
  description       = "allow HTTPS traffic"

  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  # bastion host should be able to connect to all HTTPS sites
  # tfsec:ignore:aws-vpc-no-public-egress-sgr
  cidr_blocks = ["0.0.0.0/0"]
}

module "instance_profile_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "4.20.3"

  role_name        = "${var.resource_names["prefix"]}${var.resource_names.separator}profile"
  role_description = "Instance profile for the bastion host to be able to connect to the machine"
  role_path        = var.iam_role_path

  create_role             = true
  create_instance_profile = true
  # MFA makes no sense here. It's used for EC2 instances.
  role_requires_mfa = false

  trusted_role_services = ["ec2.amazonaws.com"]
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/EC2InstanceConnect",
  ]

  tags = var.tags
}

resource "aws_launch_configuration" "this" {
  name_prefix = var.resource_names["prefix"]

  image_id      = aws_ami_copy.latest_amazon_linux.id
  instance_type = var.instance.type

  iam_instance_profile = module.instance_profile_role.iam_role_name
  security_groups      = [aws_security_group.this.id]

  root_block_device {
    volume_size = var.instance.root_volume_size
    volume_type = "gp3"

    encrypted             = true
    delete_on_termination = true
  }

  # use IMDSv2 to avoid warnings in Security Hub
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    # if Docker container are used the hop limit should be at least 2
    http_put_response_hop_limit = 2
  }

  enable_monitoring = var.instance.enable_monitoring

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "manual_start" {
  name        = var.resource_names.prefix
  description = "Launches a bastion host"

  image_id      = aws_ami_copy.latest_amazon_linux.id
  instance_type = var.instance.type

  vpc_security_group_ids = [aws_security_group.this.id]

  update_default_version = true

  iam_instance_profile {
    name = module.instance_profile_role.iam_role_name
  }

  monitoring {
    # no monitoring for manual instances
    enabled = false
  }

  # use IMDSv2 to avoid warnings in Security Hub
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    # if Docker container are used the hop limit should be at least 2
    http_put_response_hop_limit = 2
  }
}
