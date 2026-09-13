terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}
