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
