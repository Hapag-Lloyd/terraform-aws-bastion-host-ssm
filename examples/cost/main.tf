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

resource "aws_security_group" "this" {
  vpc_id = module.vpc.vpc_id

  name        = "bastion-host"
  description = "Securing the bastion host"
}

resource "aws_iam_role" "access_bastion" {
  name        = "connect-bastion"
  description = "Role used to connect to the bastion instance."

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "sts:AssumeRole",
        Principal = { "AWS" : module.bastion_user.iam_user_arn }
    }]
  })
}

module "bastion_host" {
  source = "../../"

  security_group_id     = aws_security_group.this.id
  egress_open_tcp_ports = [3306, 5432]

  connect_bastion_role_name = aws_iam_role.access_bastion.name

  instance = {
    type              = "t3.nano"
    desired_capacity  = 2
    root_device_name  = "/dev/xvda"
    root_volume_size  = 8
    enable_monitoring = false
    enable_spot       = true
    profile_name      = ""
  }

  ami_id = data.aws_ami.latest_amazon_linux.id

  instances_distribution = {
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 0
    spot_allocation_strategy                 = "lowest-price"
  }

  subnet_ids = module.vpc.private_subnets

  resource_names = {
    prefix    = local.resource_prefix
    separator = "-"
  }
}

module "bastion_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = ">= 6.0.0"

  name = "${local.resource_prefix}-bastion"

  password_reset_required = false
  create_login_profile    = false
  force_destroy           = true
}
