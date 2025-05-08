variable "subnet_ids" {
  type        = list(string)
  description = "The subnets to place the bastion in."
}

variable "iam_role_path" {
  type        = string
  description = "Role path for the created bastion instance profile. Must end with '/'. Not used if instance[\"profile_name\"] is set."

  default = "/"
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
    root_device_name  = string
    root_volume_size  = number # in GB
    enable_monitoring = bool
    enable_spot       = bool
    profile_name      = string
  })

  description = "Defines the basic parameters for the EC2 instance used as Bastion host"

  default = {
    type              = "t3.nano"
    desired_capacity  = 1
    root_device_name  = "/dev/xvda"
    root_volume_size  = 8
    enable_monitoring = false
    enable_spot       = false
    profile_name      = ""
  }
}

variable "instances_distribution" {
  type = object({
    on_demand_base_capacity                  = number # absolute minimum amount of on_demand instances
    on_demand_percentage_above_base_capacity = number # percentage split between on-demand and Spot instances
    spot_allocation_strategy                 = string
  })

  description = "Defines the parameters for mixed instances policy auto scaling"

  default = {
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
    spot_allocation_strategy                 = "lowest-price"
  }
}

variable "tags" {
  type        = map(string)
  description = "A list of tags to add to all resources."

  default = {}
}

variable "ami_id" {
  type        = string
  description = "The AMI ID to use for the bastion host. If not set a default AMI is used which is updated regularly"
  default     = null
}

variable "log_group_retention_days" {
  type        = number
  description = "Number of days for the Cloudwatch Log-Group retention period"
  default     = 5
}

variable "security_group_id" {
  type        = string
  description = "The security group ID to use for the bastion host."
}

variable "connect_bastion_role_name" {
  type        = string
  description = "The name of the role to assume to connect to the bastion host."
}

variable "enable_panic_switches" {
  type        = bool
  description = "If true, create the panic button Lambda switches to turn on/off the bastion host immediately."
  default     = true
}
