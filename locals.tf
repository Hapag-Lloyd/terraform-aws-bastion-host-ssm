locals {
  # remove port 443. We add it by default as needed for SSM communication
  clean_open_port_list = compact([for x in var.open_ports : x == 443 ? "" : x])
}
