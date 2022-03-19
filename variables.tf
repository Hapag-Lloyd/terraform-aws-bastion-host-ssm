variable "resource_prefix" {
  type = string
  description = "The prefix used for all resource to make them unique."
}

variable "tags" {
  type = list(map())
  description = "A list of tags to add to all resources."
}
