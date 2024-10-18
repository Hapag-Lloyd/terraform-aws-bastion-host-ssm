data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.14"

  name = "${local.resource_prefix}-my-vpc"
  cidr = "10.214.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.214.1.0/24", "10.214.2.0/24", "10.214.3.0/24"]

  map_public_ip_on_launch = false
}

resource "aws_security_group" "endpoint" {
  name        = "${local.resource_prefix}-ssm"
  description = "VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "ssm"
  }
}

resource "aws_security_group_rule" "ingress_ssm" {
  security_group_id = aws_security_group.endpoint.id

  type        = "ingress"
  description = "allow HTTPS traffic from AWS"

  protocol    = "tcp"
  cidr_blocks = module.vpc.private_subnets_cidr_blocks
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_endpoint" "endpoints" {
  for_each = toset(["ssm", "ssmmessages", "ec2messages"])

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.endpoint.id]

  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  tags = {
    Name = "${local.resource_prefix}-${each.key}"
  }
}