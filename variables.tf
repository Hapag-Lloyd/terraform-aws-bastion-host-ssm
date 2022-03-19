variable "iam_role_path" {
  type        = string
  description = "Role path for the created bastion instance profile."

  default = "/"
}

variable "bastion_access_tag_value" {
  type        = string
  description = "Value added as tag 'bastion-access' of the launched EC2 instance to be used to restrict access to the machine vie IAM."

  default = "developer"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type of the bastion"

  default = "t3.nano"
}

variable "root_volume_size" {
  type        = number
  description = "Size of the root volume in GB"

  default = 8
}

variable "egress_open_tcp_ports" {
  type        = list(number)
  description = "The list of TCP ports to open for outgoing traffic."
}

variable "vpc_id" {
  type        = string
  description = "The bastion host resides in this VPC."
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnets to place the bastion in."
}

variable "resource_prefix" {
  type        = string
  description = "The prefix used for all resources to make them unique."
}

variable "tags" {
  type        = map(string)
  description = "A list of tags to add to all resources."
}
