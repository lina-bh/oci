resource "oci_core_network_security_group_security_rule" "tcp4_out" {
  for_each = var.tcp_out

  network_security_group_id = var.network_security_group_id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.TCP
  stateless        = false
  tcp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

resource "oci_core_network_security_group_security_rule" "tcp6_out" {
  for_each = var.tcp_out

  network_security_group_id = var.network_security_group_id

  direction        = "EGRESS"
  destination      = "::/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.TCP
  stateless        = false
  tcp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

resource "oci_core_network_security_group_security_rule" "udp4_out" {
  for_each = var.udp_out

  network_security_group_id = var.network_security_group_id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.UDP
  stateless        = false
  udp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

resource "oci_core_network_security_group_security_rule" "udp6_out" {
  for_each = var.udp_out

  network_security_group_id = var.network_security_group_id

  direction        = "EGRESS"
  destination      = "::/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.UDP
  stateless        = false
  udp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

resource "oci_core_network_security_group_security_rule" "tailscale_out" {
  for_each = var.tailscale ? { ipv4 = "0.0.0.0/0", ipv6 = "::/0" } : {}

  network_security_group_id = var.network_security_group_id

  direction        = "EGRESS"
  destination      = each.value
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.UDP
  stateless        = false
  udp_options {
    source_port_range {
      min = 41641
      max = 41641
    }
  }
}

resource "oci_core_network_security_group_security_rule" "services_out" {
  count = var.services != null ? 1 : 0

  network_security_group_id = var.network_security_group_id

  direction        = "EGRESS"
  destination      = var.services
  destination_type = "SERVICE_CIDR_BLOCK"
  protocol         = local.security_list_protocol.TCP
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "mtu_in" {
  network_security_group_id = var.network_security_group_id

  direction   = "INGRESS"
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.ICMP
  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "mtu_out" {
  network_security_group_id = var.network_security_group_id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.ICMP
  icmp_options {
    type = 3
    code = 4
  }
}
