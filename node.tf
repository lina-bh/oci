resource "oci_core_route_table" "node" {
  compartment_id = oci_core_vcn.vcn.compartment_id

  vcn_id = oci_core_vcn.vcn.id

  route_rules {
    network_entity_id = oci_core_nat_gateway.nat.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.svc.id
    destination       = "all-lhr-services-in-oracle-services-network"
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "node" {
  compartment_id             = oci_core_vcn.vcn.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  ipv4cidr_blocks            = [local.worker4]
  display_name               = "worker"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.node.id
}

resource "oci_core_network_security_group" "node" {
  compartment_id = oci_core_vcn.vcn.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  display_name = "node"
}

resource "oci_core_network_security_group_security_rule" "node_from_node" {
  network_security_group_id = oci_core_network_security_group.node.id

  direction   = "INGRESS"
  source      = oci_core_network_security_group.node.id
  source_type = "NETWORK_SECURITY_GROUP"
  protocol    = "all"
}

resource "oci_core_network_security_group_security_rule" "node_kubelet_from_api" {
  network_security_group_id = oci_core_network_security_group.node.id

  direction   = "INGRESS"
  source      = oci_core_network_security_group.api.id
  source_type = "NETWORK_SECURITY_GROUP"
  protocol    = local.security_list_protocol.TCP
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "node_to_node" {
  network_security_group_id = oci_core_network_security_group.node.id

  direction        = "EGRESS"
  destination      = oci_core_network_security_group.node.id
  destination_type = "NETWORK_SECURITY_GROUP"
  protocol         = "all"
}

resource "oci_core_network_security_group_security_rule" "node_to_api" {
  for_each                  = { api_server = 6443, oke_agent = 12250 }
  network_security_group_id = oci_core_network_security_group.node.id

  direction        = "EGRESS"
  destination      = oci_core_network_security_group.api.id
  destination_type = "NETWORK_SECURITY_GROUP"
  protocol         = local.security_list_protocol.TCP
  stateless        = false

  tcp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

resource "oci_core_network_security_group_security_rule" "worker_to_node_ssh" {
  network_security_group_id = oci_core_network_security_group.node.id

  direction   = "INGRESS"
  source      = oci_core_network_security_group.vm.id
  source_type = "NETWORK_SECURITY_GROUP"
  protocol    = local.security_list_protocol.TCP

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "node_tcp_to_inet" {
  for_each = { for port in var.node_tcp_out : "${port}" => port }

  network_security_group_id = oci_core_network_security_group.node.id

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

resource "oci_core_network_security_group_security_rule" "node_udp_to_inet" {
  for_each = { for port in var.node_udp_out : "${port}" => port }

  network_security_group_id = oci_core_network_security_group.node.id

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

resource "oci_core_network_security_group_security_rule" "node_to_svc" {
  network_security_group_id = oci_core_network_security_group.node.id

  direction        = "EGRESS"
  destination      = "all-lhr-services-in-oracle-services-network"
  destination_type = "SERVICE_CIDR_BLOCK"
  protocol         = local.security_list_protocol.TCP
  stateless        = false
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "node_mtu4_in" {
  network_security_group_id = oci_core_network_security_group.node.id

  direction   = "INGRESS"
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.ICMP
  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "node_mtu4_out" {
  network_security_group_id = oci_core_network_security_group.node.id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.ICMP
  icmp_options {
    type = 3
    code = 4
  }
}
