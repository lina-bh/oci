[script]
tfstate-key:
	user_id="$(tofu output -raw terraform_user_id)"
	oci iam customer-secret-key list --user-id "$user_id" | jq -r '.data[].id' | xargs -r -I{} oci iam customer-secret-key delete --force --user-id "$user_id" --customer-secret-key-id {}
	out="$(oci iam customer-secret-key create --display-name terraform --user-id "$user_id")"
	sed -Ei '/AWS_ACCESS_KEY_ID=.*/cAWS_ACCESS_KEY_ID='"$(jq -r .data.id <<< "$out")" .env.local
	sed -Ei '/AWS_SECRET_ACCESS_KEY=.*/cAWS_SECRET_ACCESS_KEY='"$(jq -r .data.key <<< "$out")" .env.local

[script('sh', '-eu')]
kubeconfig:
	tmp="$(mktemp)"
	trap "rm -f "$tmp"" EXIT
	KUBECONFIG="$tmp" tailscale configure kubeconfig oke
	yq -i '.contexts[].name = "oke" | .current-context = "oke"' "$tmp"
	tmp1="$(mktemp)"
	trap "rm -f "$tmp1"" EXIT
	KUBECONFIG="${HOME}/.kube/config:$tmp" kubectl config view --flatten >"$tmp1"
	cat "$tmp1" > "${HOME}/.kube/config"
