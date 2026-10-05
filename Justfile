[no-cd]
[no-exit-message]
@kube-linter path:
	kube-linter --config {{justfile_directory()}}/.kube-linter.yaml lint "{{path}}"
