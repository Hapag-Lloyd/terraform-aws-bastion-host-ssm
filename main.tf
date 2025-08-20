data "aws_region" "this" {}

data "aws_default_tags" "this" {}

resource "aws_ami_copy" "latest_amazon_linux" {
  name        = var.resource_names["prefix"]
  description = "Copy of ${var.ami_id}"

  source_ami_id     = var.ami_id
  source_ami_region = data.aws_region.this.name

  encrypted  = true
  kms_key_id = var.kms_key_arn

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "user_defined_ports_ipv4" {
  for_each = toset(local.clean_egress_open_tcp_ports)

  security_group_id = var.security_group_id
  description       = format("all IPv4 hosts on port %s", each.key)

  ip_protocol = "tcp"
  from_port   = each.key
  to_port     = each.key
  cidr_ipv4   = "0.0.0.0/0"

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "user_defined_ports_ipv6" {
  for_each = toset(local.clean_egress_open_tcp_ports)

  security_group_id = var.security_group_id
  description       = format("all IPv6 hosts on port %s", each.key)

  ip_protocol = "tcp"
  from_port   = each.key
  to_port     = each.key
  cidr_ipv6   = "::/0"

  tags = var.tags
}

# need for SSM connection
resource "aws_vpc_security_group_egress_rule" "ssm" {
  security_group_id = var.security_group_id
  description       = "all IPv4 hosts on port 443"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  # TODO should be changed to the actual AWS CIDR block
  cidr_ipv4 = "0.0.0.0/0"

  tags = var.tags
}

module "instance_profile_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.2"

  count = var.instance["profile_name"] != "" ? 0 : 1

  name        = "${var.resource_names["prefix"]}${var.resource_names.separator}profile"
  description = "Instance profile for the bastion host to be able to connect to the machine"
  path        = var.iam_role_path

  create                  = true
  create_instance_profile = true

  trust_policy_permissions = {
    "ec2" = {
      actions = ["sts:AssumeRole"]
      principals = [
        {
          "type" : "Service"
          "identifiers" : ["ec2.amazonaws.com"]
      }]
      effect = "Allow"
    }
  }

  policies = {
    "AmazonSSMManagedInstanceCore" : "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "EC2InstanceConnect" : "arn:aws:iam::aws:policy/EC2InstanceConnect",
  }

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

  tag_specifications {
    resource_type = "volume"

    tags = local.bastion_runtime_tags
  }

  tag_specifications {
    resource_type = "network-interface"

    tags = local.bastion_runtime_tags
  }

  dynamic "tag_specifications" {
    # ASG fails tagging if there are no spot instances created
    for_each = var.instance.enable_spot && var.instances_distribution.on_demand_base_capacity == 0 && var.instances_distribution.on_demand_percentage_above_base_capacity == 0 ? [1] : []

    content {
      resource_type = "spot-instances-request"

      tags = local.bastion_runtime_tags
    }
  }

  tags = var.tags
}
