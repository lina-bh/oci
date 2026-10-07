# -*- mode: makefile; -*-
[no-cd]
[no-exit-message]
@kube-linter path:
	kube-linter --config {{justfile_directory()}}/.kube-linter.yaml lint "{{path}}"

[script]
tfstate-key:
	user_id="$(tofu output -raw terraform_user_id)"
	oci iam customer-secret-key list --user-id "$user_id" | jq -r '.data[].id' | xargs -r -I{} oci iam customer-secret-key delete --force --user-id "$user_id" --customer-secret-key-id {}
	out="$(oci iam customer-secret-key create --display-name terraform --user-id "$user_id")"
	sed -Ei '/AWS_ACCESS_KEY_ID=.*/cAWS_ACCESS_KEY_ID='"$(jq -r .data.id <<< "$out")" .env.local
	sed -Ei '/AWS_SECRET_ACCESS_KEY=.*/cAWS_SECRET_ACCESS_KEY='"$(jq -r .data.key <<< "$out")" .env.local
