module "e2_1_micro" {
  count = 1

  source = "./e2_1_micro"

  compartment_id      = oci_core_subnet.vm0.compartment_id
  availability_domain = local.availability_domains["3"]

  subnet_id = oci_core_subnet.vm0.id
  nsg_id    = oci_core_network_security_group.vm0.id

  ssh_public_key = trimspace(tls_private_key.oci.public_key_openssh)

  subnet_router = [
    var.subnet,
    oci_core_vcn.vcn.ipv6cidr_blocks[0]
  ]

  ipv4 = cidrhost(var.subnet, 253 - count.index)
}
