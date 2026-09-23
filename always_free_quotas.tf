resource "oci_limits_quota" "always_free_quotas" {
  compartment_id = var.compartment_ocid

  name        = "always_free_quotas"
  description = "Block creation of resources above Always Free limits"

  statements = [
    "set block-storage quota total-storage-gb to 200 in tenancy",
    "set compute-core quota standard-a1-core-count to 2 in tenancy",
    "set compute-memory quota standard-a1-memory-count to 12 in tenancy",
    "set object-storage quota storage-bytes to ${30 * pow(1024, 4)} in tenancy"
  ]
}
