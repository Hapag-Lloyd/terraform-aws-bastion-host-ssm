module "bastion_host" {
  source = "../../"

  egress_open_tcp_ports = [3306, 5432]

  iam_user_arns = [module.bastion_user.iam_user_arn]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}



module "bastion_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "4.15.1"

  name = "bastion"

  password_reset_required       = false
  create_iam_user_login_profile = false
  force_destroy                 = true
}
