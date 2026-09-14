resource "oci_kms_vault" "vault" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id
  display_name   = "vault"
  vault_type     = "DEFAULT"
}

resource "local_file" "vault" {
  filename        = "${path.root}/k8s/infrastructure/configs/external-secrets/clustersecretstore_oci.yaml"
  file_permission = "0644"
  content         = <<-EOT
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: oci
spec:
  provider:
    oracle:
      vault: ${oci_kms_vault.vault.id}
      region: uk-london-1
      principalType: InstancePrincipal
EOT
}

resource "oci_kms_key" "primary" {
  compartment_id      = data.oci_identity_availability_domains.ad.compartment_id
  management_endpoint = oci_kms_vault.vault.management_endpoint
  display_name        = "primary"
  key_shape {
    algorithm = "AES"
    length    = 32
  }
  protection_mode = "SOFTWARE"
}

resource "tailscale_oauth_client" "operator" {
  description = "oke"
  scopes      = ["devices:core", "auth_keys", "services"]
  tags        = ["tag:k8s-operator"]
}

resource "oci_vault_secret" "tailscale_operator" {
  compartment_id = oci_kms_vault.vault.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.primary.id
  secret_name    = "tailscale_operator"

  secret_content {
    content_type = "BASE64"
    content = base64encode(jsonencode({
      client_id     = tailscale_oauth_client.operator.id
      client_secret = tailscale_oauth_client.operator.key
    }))
  }
}

resource "local_file" "operator-oauth" {
  filename        = "${path.root}/k8s/infrastructure/controllers/tailscale-operator/externalsecret_operator-oauth.yaml"
  file_permission = "0644"
  content         = <<-EOT
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  namespace: tailscale
  name: operator-oauth
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: oci
  target:
    name: operator-oauth
  dataFrom:
  - extract:
      key: ${oci_vault_secret.tailscale_operator.secret_name}
EOT
}
