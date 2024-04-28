.PHONY: deploy
deploy:
	ansible-playbook \
		-i ansible/hosts.yaml \
		-e @"secrets.yaml" \
		ansible/deploy.yaml \
		--ask-pass $(ARGS)

.PHONY: apps
apps:
	ansible-playbook \
		-i ansible/hosts.yaml \
		-e @"secrets.yaml" \
		ansible/deploy.yaml \
		-t apps \
		--ask-pass $(ARGS)

.PHONY: kubespray
kubespray:
	ansible-playbook \
		-i ansible/hosts.yaml \
		-e @"secrets.yaml" \
		ansible/kubespray/cluster.yml \
		--become \
		--become-user=root \
		-e ansible_user=titters $(ARGS)

.PHONY: kubeconfig
kubeconfig:
	ansible-playbook \
		-i ansible/hosts.yaml \
		-e @"secrets.yaml" \
		-t client \
		ansible/kubespray/cluster.yml --become && \
			cp ansible/artifacts/admin.conf ~/.kube/config
