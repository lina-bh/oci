resource "tls_private_key" "oci" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "tls_private_key_oci" {
  content              = tls_private_key.oci.private_key_openssh
  filename             = "${path.root}/.ssh/oci"
  directory_permission = "0700"
  file_permission      = "0400"
}
