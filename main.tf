data "aws_region" "this" {
}

resource "aws_ami_copy" "latest_amazon_linux" {
  name        = var.resource_names["prefix"]
  description = "Copy of ${local.ami_id}"

  source_ami_id     = local.ami_id
  source_ami_region = data.aws_region.this.name

  encrypted  = true
  kms_key_id = var.kms_key_arn

  tags = var.tags
}

# allow outgoing traffic to the user defined ports
resource "aws_security_group_rule" "egress_open_ports" {
  count = length(local.clean_egress_open_tcp_ports)

  security_group_id = var.security_group_id
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
  security_group_id = var.security_group_id
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
  version = "5.52.2"

  count = var.instance["profile_name"] != "" ? 0 : 1

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

resource "aws_launch_template" "this" {
  name        = var.resource_names.prefix
  description = "Launches a bastion host"

  image_id      = aws_ami_copy.latest_amazon_linux.id
  instance_type = var.instance.type

  vpc_security_group_ids = [var.security_group_id]

  update_default_version = true

  iam_instance_profile {
    name = local.bastion_instance_profile_name
  }

  monitoring {
    enabled = var.instance.enable_monitoring
  }

  # use IMDSv2 to avoid warnings in Security Hub
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = var.instance.root_device_name

    ebs {
      volume_size = var.instance.root_volume_size
      volume_type = "gp3"
      iops        = 3000
      encrypted   = true
      kms_key_id  = var.kms_key_arn
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = local.bastion_runtime_tags
  }

  tags = var.tags
}
