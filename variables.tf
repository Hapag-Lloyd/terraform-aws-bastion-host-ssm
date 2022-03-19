variable "iam_role_path" {
  type = string
  description = "Role path for the created bastion instance profile."
}

variable "resource_prefix" {
  type = string
  description = "The prefix used for all resource to make them unique."
}

variable "tags" {
  type = list(map())
  description = "A list of tags to add to all resources."
}
