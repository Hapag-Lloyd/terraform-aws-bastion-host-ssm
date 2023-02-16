module "bastion_host" {
  source = "../../"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  iam_role_path = "/${local.resource_prefix}/"
  iam_user_arns = [module.bastion_user.iam_user_arn]

  kms_key_arn = module.kms_key.key_arn

  bastion_access_tag_value = "developers"

  instance = {
    type              = "t3.nano"
    desired_capacity  = 2
    root_volume_size  = 8
    enable_monitoring = false

    enable_spot = false

    profile_name = "AmazonSSMRoleForInstancesQuickSetup"
  }

  resource_names = {
    prefix    = local.resource_prefix
    separator = "-"
  }

  egress_open_tcp_ports = [3306, 5432]

  schedule = {
    start = "0 9 * * MON-FRI"
    stop  = "0 17 * * MON-FRI"

    time_zone = "Europe/Berlin"
  }

  ami_name_filter = "amzn2-ami-hvm-*-x86_64-ebs"

  tags = { "env" : "oss" }
}

module "kms_key" {
  source  = "cloudposse/kms-key/aws"
  version = "0.12.1"

  namespace               = "eg"
  stage                   = "test"
  name                    = "${local.resource_prefix}-chamber"
  description             = "KMS key for bastion host"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  alias                   = "alias/parameter_store_key"
}

module "bastion_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.11.2"

  name = "${local.resource_prefix}-bastion"

  password_reset_required       = false
  create_iam_user_login_profile = false
  force_destroy                 = true
}
