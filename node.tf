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

# resource "oci_core_network_security_group_security_rule" "pod_from_pod" {
#   network_security_group_id = oci_core_network_security_group.node.id

#   direction        = "INGRESS"
#   source           = local.pod_subnet
#   source_type      = "CIDR_BLOCK"
#   destination      = local.pod_subnet
#   destination_type = "CIDR_BLOCK"
#   protocol         = "all"
# }

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

# resource "oci_core_network_security_group_security_rule" "pod_to_pod" {
#   network_security_group_id = oci_core_network_security_group.node.id

#   direction        = "EGRESS"
#   source           = local.pod_subnet
#   source_type      = "CIDR_BLOCK"
#   destination      = local.pod_subnet
#   destination_type = "CIDR_BLOCK"
#   protocol         = "all"
# }

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
  source      = oci_core_network_security_group.vm0.id
  source_type = "NETWORK_SECURITY_GROUP"
  protocol    = local.security_list_protocol.TCP

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

module "nsl_node" {
  source = "./nsl"

  network_security_group_id = oci_core_network_security_group.node.id

  tcp_out   = { http = 80, https = 443, ssh = 22, dns = 53 }
  udp_out   = { dns = 53 }
  tailscale = false
  services  = "all-lhr-services-in-oracle-services-network"
}
