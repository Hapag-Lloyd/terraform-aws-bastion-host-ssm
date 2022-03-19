locals {
  # remove port 443. We add it by default as needed for SSM communication
  clean_egress_open_tcp_ports = compact([for x in var.egress_open_tcp_ports : x == 443 ? "" : x])

  asg_tags = merge(
    var.tags,
    {
      "Name"           = var.resource_prefix
      "bastion-access" = var.bastion_access_tag_value
  })
}
