module "bastion_host" {
  source = "../../"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  iam_role_path = "/instances/"
  iam_user_arn  = module.bastion_user.iam_user_arn

  kms_key_id = module.kms_key.key_id

  bastion_access_tag_value = "developers"

  instance = {
    type              = "t3.nano"
    desired_capacity  = 2
    root_volume_size  = 8
    enable_monitoring = false

    enable_spot = false
  }

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

module "kms_key" {
  source  = "cloudposse/kms-key/aws"
  version = "0.12.1"

  namespace               = "eg"
  stage                   = "test"
  name                    = "chamber"
  description             = "KMS key for chamber"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/parameter_store_key"
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
