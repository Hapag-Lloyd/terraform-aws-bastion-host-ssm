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

  subnet_ids = module.vpc.private_subnets

  iam_role_path             = "/${local.resource_prefix}/"
  connect_bastion_role_name = aws_iam_role.access_bastion.name

  kms_key_arn = module.kms_key.key_arn

  bastion_access_tag_value = "developers"

  instance = {
    type              = "t3.nano"
    desired_capacity  = 2
    root_device_name  = "/dev/xvda"
    root_volume_size  = 8
    enable_monitoring = false
    enable_spot       = false
    profile_name      = "AmazonSSMRoleForInstancesQuickSetup"
  }

  ami_id = data.aws_ami.latest_amazon_linux.id

  resource_names = {
    prefix    = local.resource_prefix
    separator = "-"
  }

  security_group_id     = aws_security_group.this.id
  egress_open_tcp_ports = [3306, 5432]

  schedule = {
    start = "0 9 * * MON-FRI"
    stop  = "0 17 * * MON-FRI"

    time_zone = "Europe/Berlin"
  }

  tags = { "env" : "oss" }
}

module "kms_key" {
  source  = "cloudposse/kms-key/aws"
  version = ">= 0.12.2"

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
  version = ">= 5.48.0"

  name = "${local.resource_prefix}-bastion"

  password_reset_required       = false
  create_iam_user_login_profile = false
  force_destroy                 = true
}
