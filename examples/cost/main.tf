# don't do this in your module! Just to get an AMI id for the example. I don't want to update it every time.
# use a hardcoded AMI id in your module, place it in `var.ami.id/region` and update it when you need to. This way you have an
# immutable infrastructure and you can always roll back to the previous version of the AMI if something goes wrong.
data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

module "bastion_host" {
  source = "../../"

  egress_open_tcp_ports = [3306, 5432]

  iam_user_arns = [module.bastion_user.iam_user_arn]

  instance = {
    type              = "t3.nano"
    desired_capacity  = 2
    root_volume_size  = 8
    enable_monitoring = false
    enable_spot       = true
    profile_name      = ""
  }

  ami_id            = data.aws_ami.latest_amazon_linux.id

  instances_distribution = {
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 0
    spot_allocation_strategy                 = "lowest-price"
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  resource_names = {
    prefix    = local.resource_prefix
    separator = "-"
  }
}

module "bastion_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.32.1"

  name = "${local.resource_prefix}-bastion"

  password_reset_required       = false
  create_iam_user_login_profile = false
  force_destroy                 = true
}
