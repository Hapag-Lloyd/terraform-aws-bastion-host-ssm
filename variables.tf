variable "vpc_id" {
  type        = string
  description = "The bastion host resides in this VPC."
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnets to place the bastion in."
}

variable "iam_role_path" {
  type        = string
  description = "Role path for the created bastion instance profile. Must end with '/'"

  default = "/"
}

variable "iam_user_arns" {
  type        = list(string)
  description = "ARNs of the user who are allowed to assume the role giving access to the bastion host."
}

variable "schedule" {
  type = object({
    start     = string
    stop      = string
    time_zone = string
  })
  description = "Defines when to start and stop the instances. Use 'start' and 'stop' with a cron expression and add the 'time_zone'."

  default = null
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key used to encrypt the resources."

  default = null
}

variable "bastion_access_tag_value" {
  type        = string
  description = "Value added as tag 'bastion-access' of the launched EC2 instance to be used to restrict access to the machine vie IAM."

  default = "developer"
}

variable "egress_open_tcp_ports" {
  type        = list(number)
  description = "The list of TCP ports to open for outgoing traffic."
}


variable "resource_names" {
  type = object({
    prefix    = string
    separator = string
  })
  description = "Settings for generating resource names. Set the prefix and the separator according to your company style guide."

  default = {
    "prefix" : "bastion"
    "separator" : "-"
  }
}

variable "instance" {
  type = object({
    type              = string # EC2 instance type
    desired_capacity  = number # number of EC2 instances to run
    root_volume_size  = number # in GB
    enable_monitoring = bool

    enable_spot = bool
  })
  description = "Defines the basic parameters for the EC2 instance used as Bastion host"

  default = {
    type              = "t3.nano"
    desired_capacity  = 1
    root_volume_size  = 8
    enable_monitoring = false

    enable_spot = false
  }
}

variable "tags" {
  type        = map(string)
  description = "A list of tags to add to all resources."

  default = {}
}
