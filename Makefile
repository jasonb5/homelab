.PHONY: bootstrap
bootstrap:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" ansible/bootstrap.yaml --ask-pass $(ARGS)

.PHONY: apps
apps:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" ansible/apps.yaml $(ARGS)

.PHONY: proxmox
proxmox:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" ansible/proxmox.yaml $(ARGS)

.PHONY: proxmox-update
proxmox-update:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" -e update=true ansible/proxmox.yaml $(ARGS)

.PHONY: proxmox-destroy
proxmox-destroy:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" -e destroy=true ansible/proxmox.yaml $(ARGS)

.PHONY: kubespray
kubespray:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" ansible/kubespray/cluster.yml --become --become-user=root -e ansible_user=titters $(ARGS)

.PHONY: kubespray-reset
kubespray-reset:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" ansible/kubespray/reset.yml --become $(ARGS)

.PHONY: kubeconfig
kubeconfig:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" -t client ansible/kubespray/cluster.yml --become && \
		cp ansible/artifacts/admin.conf ~/.kube/config
