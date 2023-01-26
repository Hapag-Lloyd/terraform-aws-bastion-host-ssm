module "bastion_host" {
  source = "../../"

  egress_open_tcp_ports = [3306, 5432]

  iam_user_arns = [module.bastion_user.iam_user_arn]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70"

  name = "my-vpc"
  cidr = "10.214.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.214.1.0/24", "10.214.2.0/24", "10.214.3.0/24"]

  map_public_ip_on_launch = false
}

module "bastion_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "4.15.1"

  name = "bastion"

  password_reset_required       = false
  create_iam_user_login_profile = false
  force_destroy                 = true
}

data "aws_region" "current" {}

resource "aws_security_group" "ssm" {
  name        = "ssm"
  description = "SSM SG"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "ssm"
  }
}
# need for incoming connection to SSM
resource "aws_security_group_rule" "ingress_ssm" {
  security_group_id = aws_security_group.ssm.id
  type              = "ingress"
  description       = "allow HTTPS traffic"

  from_port   = 443
  to_port        = 443
  protocol      = "tcp"
  cidr_blocks = module.vpc.private_subnets_cidr_blocks
}

resource "aws_vpc_endpoint" "bastion_host" {
  for_each                   = toset(["ssm", "ssmmessages", "ec2messages"])
  vpc_id                       = module.vpc.vpc_id
  service_name          = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  subnet_ids               = module.vpc.private_subnets
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.ssm.id]
  tags = {
    Name = "bastion-host-${each.key}"
  }
}