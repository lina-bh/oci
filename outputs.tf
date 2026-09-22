output "oke" {
  value = oci_containerengine_cluster.oke.id
}

output "nfs_instance_id" {
  value = oci_core_instance.nfs.id
}

output "compartment_id" {
  value = oci_core_vcn.vcn.compartment_id
}
