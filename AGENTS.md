# AGENTS.md

## OCI Instance Console History

Capture the latest serial console history snapshot and print content to stdout:

```sh
oci compute console-history capture \
  --instance-id <instance-ocid> \
  --wait-for-state SUCCEEDED \
  --query 'data.id' --raw-output 2>/dev/null | \
  xargs -I{} oci compute console-history get-content \
    --instance-console-history-id {} \
    --file -
```

Or using command substitution:

```sh
oci compute console-history get-content \
  --file - \
  --instance-console-history-id "$(oci compute console-history capture \
    --instance-id <instance-ocid> \
    --wait-for-state SUCCEEDED \
    --query 'data.id' --raw-output 2>/dev/null)"
```

## Networking: intentional lack of dual-stack for OKE

* The VCN (`vcn`) and the `vm0` bastion subnet are dual-stack (IPv4 + IPv6) by
  design; the bastion's IPv6 egress goes through the internet gateway
  (`::/0` route on `oci_core_route_table.vm0`).
* **OKE and the `node` (worker) subnet are intentionally IPv4-only.** OCI NAT
  Gateways carry IPv4 traffic only — per the OCI IPv6 docs, "IPv6 traffic is
  supported only with these gateways: internet gateway, local peering gateway,
  and DRG." Workers egress via the NAT gateway
  (`oci_core_route_table.node`), so a dual-stack worker subnet would have no
  usable IPv6 egress path. Do not add `ipv6cidr_blocks` to
  `oci_core_subnet.node`, a `::/0` route to `oci_core_route_table.node`, or
  IPv6/protocol-58 rules to the `node` NSG; their absence is deliberate.
* **`ipv6cidr_block` on `oci_core_subnet.api` (`local.apiserver6`) cannot be
  removed without recreating the subnet and all dependent resources.** OCI
  requires that a subnet with an IPv6 prefix assigned always keep at least
  one, and the `api` subnet has exactly one — so the API offers no removal
  path for it. Terraform must destroy and recreate the subnet, which cascades
  to the OKE cluster endpoint (`endpoint_config.subnet_id` in
  `kubernetes.tf`) and any other resources referencing the subnet. Treat
  removing it as a migration, not a cleanup.
