output "cluster_id" {
  value = oci_containerengine_cluster.oke.id
}

output "compartment_id" {
  value = oci_core_vcn.vcn.compartment_id
}

output "node_pool_id" {
  value = oci_containerengine_node_pool.vm_standard_a1_flex.id
}

output "node_id" {
  value = {
    for node in oci_containerengine_node_pool.vm_standard_a1_flex.nodes :
    node.private_ip => node.id
  }
}

output "clustersecretstore_oci" {
  value = yamlencode({
    apiVersion = "external-secrets.io/v1",
    kind       = "ClusterSecretStore",
    metadata = {
      name = "oci",
    },
    spec = {
      provider = {
        oracle = {
          vault         = oci_kms_vault.vault.id
          region        = "uk-london-1"
          principalType = "InstancePrincipal"
        }
      }
    }
  })
}
