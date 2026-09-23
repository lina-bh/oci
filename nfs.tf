resource "tailscale_tailnet_key" "nfs" {
  description   = "oci-nfs"
  ephemeral     = false
  preauthorized = true
  reusable      = false
  tags          = ["tag:oci"]
  expiry        = 60 * 20
}

module "cloudinit-tailscale" {
  source  = "tailscale/tailscale/cloudinit"
  version = "0.0.12"

  accept_dns          = false
  advertise_connector = true
  advertise_tags      = ["tag:oci"]
  advertise_routes    = [var.subnet, oci_core_vcn.vcn.ipv6cidr_blocks[0]]
  auth_key            = tailscale_tailnet_key.nfs.key
  hostname            = "oci-nfs1"
  additional_parts = [
    {
      filename     = "ssh.yaml"
      content_type = "text/cloud-config"
      content      = <<-EOT
#cloud-config
ssh_authorized_keys:
  - "${trimspace(tls_private_key.oci.public_key_openssh)}"
EOT
    },
    {
      filename     = "upgrade.yaml"
      content_type = "text/cloud-config"
      content      = <<-EOT
#cloud-config
package_update: true
runcmd:
- ["apt-mark", "manual", "initramfs-tools-core"]
- ["apt-get", "--yes", "purge", "snapd", "modemmanager", "nvme-cli", "lxd-agent-loader", "lxd-installer", "uuid-runtime", "fwupd", "ubuntu-pro-client", "ubuntu-drivers-common"]
- ["apt-get", "--yes", "autoremove"]
package_upgrade: true
EOT
    }
  ]
}

data "oci_core_images" "resolute" {
  compartment_id = oci_core_subnet.vm.compartment_id

  operating_system         = "Canonical Ubuntu"
  operating_system_version = "26.04 Minimal"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "nfs" {
  lifecycle {
    ignore_changes = [metadata, source_details]
  }

  compartment_id      = oci_core_subnet.vm.compartment_id
  availability_domain = local.availability_domains["3"]

  shape = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    assign_public_ip = true
    assign_ipv6ip    = true
    subnet_id        = oci_core_subnet.vm.id
    private_ip       = cidrhost(oci_core_subnet.vm.ipv4cidr_blocks[0], 251)
    nsg_ids          = [oci_core_network_security_group.vm.id]
    hostname_label   = "nfs"
  }

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.resolute.images[0].id

    is_preserve_boot_volume_enabled = false

    boot_volume_size_in_gbs = 50
    boot_volume_vpus_per_gb = 20
  }

  preserve_boot_volume                = false
  is_pv_encryption_in_transit_enabled = true

  display_name = "nfs"

  metadata = {
    "user_data" = module.cloudinit-tailscale.rendered
  }
}
