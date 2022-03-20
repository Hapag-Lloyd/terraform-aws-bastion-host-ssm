module "bastion_host" {
  source = "../../"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  iam_role_path            = "/instances/"
  bastion_access_tag_value = "developers"

  instance_type    = "t3.nano"
  root_volume_size = 8

  resource_names = {
    prefix    = "bastion"
    separator = "-"
  }

  egress_open_tcp_ports = [3306, 5432]

  schedule = {
    start = "0 9 * * MON-FRI"
    stop  = "0 17 * * MON-FRI"

    time_zone = "Europe/Berlin"
  }

  tags = { "env" : "deve" }
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
