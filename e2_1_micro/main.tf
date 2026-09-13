resource "tailscale_tailnet_key" "auth" {
  lifecycle {
    replace_triggered_by = [random_pet.hostname]
  }

  ephemeral     = false
  preauthorized = true
  reusable      = false
  tags          = ["tag:oci"]
  expiry        = 60 * 60
}

module "cloudinit-tailscale" {
  source  = "tailscale/tailscale/cloudinit"
  version = "0.0.12"

  accept_dns          = false
  advertise_connector = true
  advertise_tags      = ["tag:oci"]
  advertise_routes    = var.subnet_router
  auth_key            = tailscale_tailnet_key.auth.key
  additional_parts = [
    {
      filename     = "ssh.yaml"
      content_type = "text/cloud-config"
      content      = <<-EOT
#cloud-config
ssh_authorized_keys:
  - "${var.ssh_public_key}"
EOT
    }
  ]
}

data "oci_core_images" "ol10" {
  compartment_id = var.compartment_id

  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  shape                    = local.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

/*
data "oci_core_images" "resolute" {
  compartment_id = var.compartment_id

  operating_system         = "Canonical Ubuntu"
  operating_system_version = "26.04 Minimal"
  shape                    = local.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}
*/

resource "random_pet" "hostname" {
  separator = ""
}

resource "oci_core_instance" "vm" {
  lifecycle {
    ignore_changes       = [metadata, source_details]
    replace_triggered_by = [random_pet.hostname]
  }

  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain

  async = true

  shape = local.shape

  create_vnic_details {
    assign_public_ip = true
    assign_ipv6ip    = true
    subnet_id        = var.subnet_id
    private_ip       = var.ipv4
    nsg_ids          = [var.nsg_id]
    hostname_label   = random_pet.hostname.id
  }

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ol10.images[0].id

    boot_volume_size_in_gbs = 50
    boot_volume_vpus_per_gb = 20
  }

  preserve_boot_volume                = false
  is_pv_encryption_in_transit_enabled = true

  display_name = random_pet.hostname.id

  metadata = {
    "user_data" = module.cloudinit-tailscale.rendered
  }
}
