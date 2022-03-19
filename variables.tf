variable "egress_open_tcp_ports" {
  type        = list(number)
  description = "The list of TCP ports to open for outgoing traffic."
}

variable "vpc_id" {
  type        = string
  description = "The bastion host resides in this VPC."
}

variable "iam_role_path" {
  type        = string
  description = "Role path for the created bastion instance profile."
}

variable "resource_prefix" {
  type        = string
  description = "The prefix used for all resource to make them unique."
}

variable "tags" {
  type        = map(string)
  description = "A list of tags to add to all resources."
}
