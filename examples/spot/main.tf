module "bastion_host" {
  source = "../../"

  egress_open_tcp_ports = [3306, 5432]

  iam_user_arn = module.bastion_user.iam_user_arn

  instance = {
    type              = "t3.nano"
    desired_capacity  = 3
    root_volume_size  = 8
    enable_monitoring = false

    enable_spot = false
  }

  resource_names = {
    prefix    = "x-bastion"
    separator = "-"
  }

  vpc_id     = "vpc-074e65ead9562b449"
  subnet_ids = ["subnet-027a1bd83096fc772", "subnet-06421c0d85479a548", "subnet-070d97f015402e473"]
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
