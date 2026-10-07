resource "oci_bastion_bastion" "api" {
  compartment_id = oci_core_subnet.api.compartment_id

  name             = "api"
  bastion_type     = "STANDARD"
  target_subnet_id = oci_core_subnet.api.id

  client_cidr_block_allow_list = [
    var.home_prefix
  ]
}
