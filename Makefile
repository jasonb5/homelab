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

.PHONY: homelab-env
homelab-env:
	mamba create -n homelab -y \
		'python<=3.11' hvac cryptography && \
		source $(join $(dir $(CONDA_EXE)), '/..')/etc/profile.d/conda.sh && \
		conda activate homelab && \
		pip install -r ansible/kubespray/requirements.txt && \
		pip install cryptography[ssh]
