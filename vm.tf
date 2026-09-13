resource "oci_core_route_table" "vm0" {
  compartment_id = oci_core_vcn.vcn.compartment_id

  vcn_id = oci_core_vcn.vcn.id

  route_rules {
    network_entity_id = oci_core_internet_gateway.inet.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_internet_gateway.inet.id
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "vm0" {
  compartment_id             = oci_core_vcn.vcn.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  dns_label                  = "vm0"
  ipv4cidr_blocks            = [local.vm_ipv4cidr]
  ipv6cidr_blocks            = [local.vm_ipv6cidr]
  display_name               = "vm0"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.vm0.id
}

resource "oci_core_network_security_group" "vm0" {
  compartment_id = oci_core_subnet.vm0.compartment_id
  vcn_id         = oci_core_subnet.vm0.vcn_id

  display_name = "vm0"
}

module "vm_nsl" {
  source = "./nsl"

  network_security_group_id = oci_core_network_security_group.vm0.id

  tcp_out = { http = 80, https = 443, }
  udp_out = { stun = 3478, tailscale = 41641 }
}

resource "oci_core_network_security_group_security_rule" "vm_from_inet_ts" {
  for_each = toset(["4", "6"])

  network_security_group_id = oci_core_network_security_group.vm0.id

  direction   = "INGRESS"
  source      = each.value == "4" ? "0.0.0.0/0" : "::/0"
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.UDP
  stateless   = false
  udp_options {
    destination_port_range {
      min = 41641
      max = 41641
    }
  }
}

resource "oci_core_network_security_group_security_rule" "vm_to_api" {
  network_security_group_id = oci_core_network_security_group.vm0.id

  direction        = "EGRESS"
  destination      = oci_core_network_security_group.api.id
  destination_type = "NETWORK_SECURITY_GROUP"
  protocol         = local.security_list_protocol.TCP
  stateless        = false
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "vm_to_node_ssh" {
  network_security_group_id = oci_core_network_security_group.vm0.id

  direction        = "EGRESS"
  destination      = oci_core_network_security_group.node.id
  destination_type = "NETWORK_SECURITY_GROUP"
  protocol         = local.security_list_protocol.TCP
  stateless        = false
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}
