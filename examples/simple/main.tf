module "bastion_host" {
  source = "../../"

  egress_open_tcp_ports = [3306, 5432]

  iam_user_arn = module.bastion_user.iam_user_arn

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
