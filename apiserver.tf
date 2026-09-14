resource "oci_core_route_table" "api" {
  compartment_id = oci_core_vcn.vcn.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  route_rules {
    network_entity_id = oci_core_service_gateway.svc.id
    destination       = "all-lhr-services-in-oracle-services-network"
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "api" {
  compartment_id  = oci_core_vcn.vcn.compartment_id
  vcn_id          = oci_core_vcn.vcn.id
  dns_label       = "apiserver"
  ipv4cidr_blocks = [local.apiserver4]
  ipv6cidr_block  = local.apiserver6
  display_name    = "api"
  route_table_id  = oci_core_route_table.api.id
}

resource "oci_core_network_security_group" "api" {
  compartment_id = oci_core_vcn.vcn.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  display_name = "api"
}

resource "oci_core_network_security_group_security_rule" "api_api" {
  for_each = toset([
    oci_core_network_security_group.vm0.id,
    oci_core_network_security_group.node.id
  ])

  network_security_group_id = oci_core_network_security_group.api.id

  direction   = "INGRESS"
  source      = each.value
  source_type = "NETWORK_SECURITY_GROUP"
  protocol    = local.security_list_protocol.TCP
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_agent_from_node" {
  network_security_group_id = oci_core_network_security_group.api.id

  direction   = "INGRESS"
  source      = oci_core_network_security_group.node.id
  source_type = "NETWORK_SECURITY_GROUP"
  protocol    = local.security_list_protocol.TCP
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 12250
      max = 12250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "api_icmp_from_worker" {
  network_security_group_id = oci_core_network_security_group.api.id

  direction   = "INGRESS"
  source      = oci_core_network_security_group.node.id
  source_type = "NETWORK_SECURITY_GROUP"
  protocol    = local.security_list_protocol.ICMP
  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "api_icmp_to_worker" {
  network_security_group_id = oci_core_network_security_group.api.id

  direction        = "EGRESS"
  destination      = oci_core_network_security_group.node.id
  destination_type = "NETWORK_SECURITY_GROUP"
  protocol         = local.security_list_protocol.ICMP
  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "api_to_svc" {
  network_security_group_id = oci_core_network_security_group.api.id

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

resource "oci_core_network_security_group_security_rule" "api_to_worker_kubelet" {
  network_security_group_id = oci_core_network_security_group.api.id

  direction        = "EGRESS"
  destination      = oci_core_network_security_group.node.id
  destination_type = "NETWORK_SECURITY_GROUP"
  protocol         = local.security_list_protocol.TCP
  stateless        = false

  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}
