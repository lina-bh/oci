locals {
  availability_domains = {
    "1" = data.oci_identity_availability_domains.ad.availability_domains[0].name
    "3" = data.oci_identity_availability_domains.ad.availability_domains[2].name
  }

  security_list_protocol = {
    ICMP    = "1"
    TCP     = "6"
    UDP     = "17"
    ICMPSIX = "58"
  }

  vm_ipv4cidr = cidrsubnet(var.subnet, 8, 0)
  vm_ipv6cidr = cidrsubnet(oci_core_vcn.vcn.ipv6cidr_blocks[0], 8, 0)

  apiserver4 = cidrsubnet(var.subnet, 8, 1)
  apiserver6 = cidrsubnet(oci_core_vcn.vcn.ipv6cidr_blocks[0], 8, 1)

  worker4 = cidrsubnet(var.subnet, 8, 2)

  pod_subnet = "10.244.0.0/16"
}
