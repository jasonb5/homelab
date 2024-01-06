.PHONY: bootstrap
bootstrap:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" ansible/bootstrap.yaml -e ansible_user=root --ask-pass

.PHONY: proxmox
proxmox:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" ansible/proxmox.yaml -e ansible_user=root

.PHONY: proxmox-destroy
proxmox-destroy:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" -e proxmox_destroy=true ansible/proxmox.yaml

.PHONY: kubespray
kubespray:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" ansible/kubespray/cluster.yml --become --become-user=root -e ansible_user=titters $(ARGS)

.PHONY: kubespray-reset
kubespray-reset:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" ansible/kubespray/reset.yml --become

.PHONY: kubeconfig
kubeconfig:
	ansible-playbook -i ansible/hosts.yaml -e @"secrets.yaml" -t client ansible/kubespray/cluster.yml --become && \
		cp ansible/artifacts/admin.conf ~/.kube/config
