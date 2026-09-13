resource "oci_containerengine_cluster" "oke" {
  compartment_id = oci_core_subnet.api.compartment_id

  name = "oke"
  type = "BASIC_CLUSTER"

  vcn_id = oci_core_subnet.api.vcn_id
  endpoint_config {
    is_public_ip_enabled = false
    subnet_id            = oci_core_subnet.api.id
    nsg_ids              = [oci_core_network_security_group.api.id]
  }

  kubernetes_version = "v1.36.1"
}

data "cloudinit_config" "worker" {
  part {
    filename     = "ssh.yaml"
    content_type = "text/cloud-config"
    content      = <<-EOT
#cloud-config
ssh_authorized_keys:
  - "${tls_private_key.oci.public_key_openssh}"
EOT
  }
}

data "oci_containerengine_node_pool_option" "aarch64" {
  node_pool_option_id   = oci_containerengine_cluster.oke.id
  node_pool_k8s_version = "v1.36.1"
  node_pool_os_arch     = "aarch64"
}

resource "oci_containerengine_node_pool" "vm_standard_a1_flex" {
  compartment_id = oci_containerengine_cluster.oke.compartment_id
  cluster_id     = oci_containerengine_cluster.oke.id

  node_shape = "VM.Standard.A1.Flex"
  name       = "vm_standard_a1_flex"

  node_shape_config {
    memory_in_gbs = 2
    ocpus         = 1
  }

  node_config_details {
    placement_configs {
      availability_domain = local.availability_domains["1"]
      subnet_id           = oci_core_subnet.node.id
    }

    placement_configs {
      availability_domain = local.availability_domains["3"]
      subnet_id           = oci_core_subnet.node.id
    }

    is_pv_encryption_in_transit_enabled = true

    node_pool_pod_network_option_details {
      cni_type = oci_containerengine_cluster.oke.cluster_pod_network_options[0].cni_type
    }

    nsg_ids = [oci_core_network_security_group.node.id]

    size = 1
  }

  node_source_details {
    source_type             = "image"
    image_id                = data.oci_containerengine_node_pool_option.aarch64.sources[0].image_id
    boot_volume_size_in_gbs = 50
  }

  # node_metadata = { "user_data" = data.cloudinit_config.worker.rendered }
  ssh_public_key = tls_private_key.oci.public_key_openssh

  kubernetes_version = "v1.36.1"
}
