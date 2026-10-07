resource "oci_identity_dynamic_group" "instances" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id
  name           = "instances"
  description    = "all instances in default compartment"
  matching_rule  = "instance.compartment.id = '${data.oci_identity_availability_domains.ad.compartment_id}'"
}

resource "oci_identity_policy" "instance_principal" {
  compartment_id = oci_identity_dynamic_group.instances.compartment_id
  name           = "instance_principal"
  description    = "permit instances to access oci"
  statements = [
    "Allow dynamic-group id ${oci_identity_dynamic_group.instances.id} to read vaults in tenancy where target.vault.id = '${oci_kms_vault.vault.id}'",
    "Allow dynamic-group id ${oci_identity_dynamic_group.instances.id} to read secret-family in tenancy"
  ]
}

resource "oci_identity_user" "terraform" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id
  name           = "terraform"
  description    = "Terraform service account"
}

resource "oci_identity_user_capabilities_management" "terraform" {
  user_id = oci_identity_user.terraform.id

  can_use_api_keys         = false
  can_use_auth_tokens      = false
  can_use_console_password = false
  can_use_smtp_credentials = false

  can_use_customer_secret_keys = true
}

resource "oci_identity_group" "terraform" {
  compartment_id = oci_identity_user.terraform.compartment_id
  name           = "terraform"
  description    = "Terraform service account"
}

resource "oci_identity_user_group_membership" "terraform" {
  user_id  = oci_identity_user.terraform.id
  group_id = oci_identity_group.terraform.id
}

resource "oci_identity_policy" "terraform" {
  compartment_id = oci_identity_group.terraform.compartment_id
  name           = "terraform"
  description    = "Terraform service account"
  statements = [
    "Allow group id ${oci_identity_group.terraform.id} to use objects in tenancy where all {target.bucket.name = '${oci_objectstorage_bucket.tfstate.name}' }"
  ]
}
