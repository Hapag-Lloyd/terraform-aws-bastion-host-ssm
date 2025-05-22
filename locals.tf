locals {
  # remove port 443. We add it by default as needed for SSM communication
  clean_egress_open_tcp_ports    = compact([for x in var.egress_open_tcp_ports : x == 443 ? "" : x])
  resource_prefix_with_separator = "${var.resource_names["prefix"]}${var.resource_names["separator"]}"

  bastion_runtime_tags = merge(
    var.tags,
    {
      "Name"                          = local.bastion_host_name
      (local.bastion_access_tag_name) = var.bastion_access_tag_value
  })

  bastion_host_name       = var.resource_names["prefix"]
  bastion_access_tag_name = "bastion-access"

  bastion_instance_profile_name = var.instance["profile_name"] != "" ? var.instance["profile_name"] : module.instance_profile_role[0].iam_role_name

  panic_button_switch_off_lambda_source_file_name = "panic_button_switch_off.py"
  panic_button_switch_off_lambda_source           = "${path.module}/lambda/${local.panic_button_switch_off_lambda_source_file_name}"
  panic_button_switch_off_lambda_name             = "${var.resource_names.prefix}${var.resource_names.separator}panic-button-off"

  panic_button_switch_on_lambda_source_file_name = "panic_button_switch_on.py"
  panic_button_switch_on_lambda_source           = "${path.module}/lambda/${local.panic_button_switch_on_lambda_source_file_name}"
  panic_button_switch_on_lambda_name             = "${var.resource_names.prefix}${var.resource_names.separator}panic-button-on"
}
