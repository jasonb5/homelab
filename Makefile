CACHE_DIR ?= $(PWD)/cache

CONDA_DIR ?= $(HOME)/conda
CONDA_ENV_DIR = $(CONDA_DIR)/envs
CONDA_ACTIVATE = . $(CONDA_DIR)/etc/profile.d/conda.sh

.PHONY: terraform
terraform:
	terraform -chdir=terraform apply -var="host_config_file=$(PWD)/terraform/hosts.json"

.PHONY: create-env
create-env:
	name="$(word 1, $(subst -, ,$(NAME)))"; \
		[ -n "$$($(CONDA_ACTIVATE); conda env list | grep $${name})" ] || \
			mamba create -n $${name} --yes $(ARGS)

.PHONY: homelab-env
homelab-env:
	@make create-env NAME=$@ ARGS='"python<3.10" ansible hvac sshpass six bcrypt'

.PHONY: kubespray-env
kubespray-env:
ifeq ($(wildcard $(CONDA_ENV_DIR)/kubespray/*), "")
	@make create-env NAME=$@ ARGS='python'
	$(CONDA_ACTIVATE); \
		conda activate kubespray; \
		while read requirement; do mamba install --yes -q $$requirement; done < kubespray/kubespray/requirements.txt; \
		pip install -r kubespray/kubespray/requirements.txt
endif

.PHONY: run
run:
	$(CONDA_ACTIVATE); \
		conda activate $(ENV); \
		cd $(if $(WORKING_DIR),$(WORKING_DIR),"."); \
		$(CMD)

.PHONY: helm-check-updates
helm-check-updates: ENV = homelab
helm-check-updates: CMD = mamba install -y semver && python helm-check-updates.py -n $(NAMESPACE)
helm-check-updates: WORKING_DIR = helmfile
helm-check-updates: run

.PHONY: bootstrap
bootstrap: ENV = "homelab"
bootstrap: CMD = ansible-playbook -i ansible/hosts.yaml ansible/bootstrap.yaml -e vault_username=$(VAULT_USERNAME) -e vault_password=$(VAULT_PASSWORD) -e vault_token=$(VAULT_TOKEN)
bootstrap: homelab-env run

.PHONY: deploy
deploy: ENV = "homelab"
deploy: CMD = ansible-playbook -i ansible/hosts.yaml ansible/deploy.yaml -e vault_username=$(VAULT_USERNAME) -e vault_password=$(VAULT_PASSWORD)
deploy: homelab-env run

.PHONY: upgrade
upgrade: ENV = "homelab"
upgrade: CMD = ansible-playbook -i ansible/hosts.yaml ansible/upgrade.yaml -e vault_username=$(VAULT_USERNAME) -e vault_password=$(VAULT_PASSWORD)
upgrade: homelab-env run

.PHONY: kubeconfig
kubeconfig: ENV = "kubespray"
kubeconfig: WORKING_DIR = kubespray/kubespray
kubeconfig: CMD = ansible-playbook -i ../hosts.yaml -e @"../custom.yaml" -t client cluster.yml
kubeconfig: kubespray-env run
	[ -e "~/.kube" ] || mkdir -p ~/.kube
	cp kubespray/artifacts/admin.conf ~/.kube/config

.PHONY: k8s-deploy
k8s-deploy: ENV = "kubespray"
k8s-deploy: WORKING_DIR = kubespray/kubespray
k8s-deploy: CMD = ansible-playbook -i ../hosts.yaml -e @"../custom.yaml" cluster.yml
k8s-deploy: kubeconfig kubespray-env run

.PHONY: k8s-scale
k8s-scale: ENV = "kubespray"
k8s-scale: WORKING_DIR = kubespray/kubespray
k8s-scale: CMD = ansible-playbook -i ../hosts.yaml -e @"../custom.yaml" playbooks/facts.yaml; \
	ansible-playbook -i ../hosts.yaml -e @"../custom.yaml" --limit=$(NODE) scale.yml
k8s-scale: kubeconfig kubespray-env run

.PHONY: k8s-upgrade
k8s-upgrade: ENV = "kubespray"
k8s-upgrade: WORKING_DIR = kubespray/kubespray
k8s-upgrade: CMD = ansible-playbook -i ../hosts.yaml -e @"../custom.yaml" -e k8s_cluster_setup=true cluster.yml
k8s-upgrade: kubeconfig kubespray-env run

.PHONY: k8s-destroy
k8s-destroy: ENV = "kubespray"
k8s-destroy: WORKING_DIR = kubespray/kubespray
k8s-destroy: CMD = ansible-playbook -i ../hosts.yaml -e @"../custom.yaml" reset.yml
k8s-destroy: kubeconfig kubespray-env run

.PHONY: ubuntu-jammy-upload
ubuntu-jammy-upload:
	@make callisto.angrydonkey.io-9000-ubuntu-jammy || exit 0
	@make deimos.angrydonkey.io-9001-ubuntu-jammy || exit 0
	@make ceres.angrydonkey.io-9003-ubuntu-jammy || exit 0

.PHONY: callisto.angrydonkey.io-9000-ubuntu-jammy
callisto.angrydonkey.io-9000-ubuntu-jammy:
	$(MAKE) CALLING=$@ $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$@)))

.PHONY: deimos.angrydonkey.io-9001-ubuntu-jammy
deimos.angrydonkey.io-9001-ubuntu-jammy:
	$(MAKE) CALLING=$@ $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$@)))

.PHONY: ceres.angrydonkey.io-9003-ubuntu-jammy
ceres.angrydonkey.io-9003-ubuntu-jammy:
	$(MAKE) CALLING=$@ $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$@)))

ubuntu-jammy proxmox-vm: TARGET_HOST = $(word 1, $(subst -, ,$(CALLING)))
ubuntu-jammy proxmox-vm: ID = $(word 2, $(subst -, ,$(CALLING)))

.PHONY: ubuntu-jammy
ubuntu-jammy: URL = https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
ubuntu-jammy: MODIFY = base-
ubuntu-jammy: download modify-image upload proxmox-vm proxmox-template
	ssh root@$(TARGET_HOST) qm set $(ID) --ide2 local-lvm:cloudinit
	ssh root@$(TARGET_HOST) qm set $(ID) --serial0 socket --vga serial0

.PHONY: proxmox-vm
proxmox-vm: TEMPLATE_NAME = $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$(CALLING))))
proxmox-vm:
	ssh root@$(TARGET_HOST) qm create $(ID) --name template-$(TEMPLATE_NAME)
	ssh root@$(TARGET_HOST) qm importdisk $(ID) /mnt/pve/iso/template/iso/$(FILENAME) local-lvm
	ssh root@$(TARGET_HOST) qm set $(ID) --memory $(if $(MEMORY),$(MEMORY),1024) --cores $(if $(CORES),$(CORES),1) $(if $(CPU),--cpu $(CPU),) $(if $(MACHINE),--machine $(MACHINE),)
	ssh root@$(TARGET_HOST) qm set $(ID) --net0 virtio,bridge=vmbr0
	ssh root@$(TARGET_HOST) qm set $(ID) --scsihw virtio-scsi-pci --$(if $(DISK_DRIVER),$(DISK_DRIVER),virtio0) local-lvm:vm-$(ID)-disk-0
	ssh root@$(TARGET_HOST) qm set $(ID) --boot order=$(if $(DISK_DRIVER),$(DISK_DRIVER),virtio0) $(if $(AGENT),--agent enabled=$(AGENT),) $(if $(BIOS),--bios $(BIOS),) --tablet 0 --localtime 1 --ostype l26

.PHONY: proxmox-template
proxmox-template:
	ssh root@$(TARGET_HOST) qm template $(ID)

.PHONY: modify-image
modify-image:
	[ -e "$(OUTPUT_FILE)" ] || \
		(cp $(CACHE_FILE) $(OUTPUT_FILE) && \
			sudo virt-customize -a $(OUTPUT_FILE) --copy-in ansible/artifacts/trusted-user-ca-keys.pem:/etc/ssh/ \
				--run-command 'chmod 0600 /etc/ssh/trusted-user-ca-keys.pem' \
				--update --install qemu-guest-agent \
				--append-line '/etc/ssh/sshd_config:TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem')

remove_ext = $(subst $(suffix $(1)),,$(1))
find_ext = $(foreach EXT,.xz .tar,$(findstring $(EXT),$(1)))
parse_filename = $(if $(or $(strip $(call find_ext,$(1)))),$(call remove_ext,$(1)),$(1))
rename_ext = $(if $(findstring $(firstword $(1)),$(2)),$(subst $(firstword $(1)),$(lastword $(1)),$(2)),$(2))

download upload modify-image proxmox-vm: _URL_FILENAME = $(lastword $(subst /, ,$(URL)))
download upload modify-image proxmox-vm: _FILENAME = $(call parse_filename,$(_URL_FILENAME))
download upload modify-image proxmox-vm: FILENAME = $(if $(RENAME_EXT),$(call rename_ext,$(RENAME_EXT),$(_FILENAME)),$(_FILENAME))
download upload modify-image proxmox-vm: CACHE_FILE = $(CACHE_DIR)/$(if $(MODIFY),$(MODIFY)$(_URL_FILENAME),$(_URL_FILENAME))
download upload modify-image proxmox-vm: DOWNLOAD_FILE = $(CACHE_DIR)/$(_FILENAME)
download upload modify-image proxmox-vm: OUTPUT_FILE = $(CACHE_DIR)/$(FILENAME)

.PHONY: upload
upload:
	[ -e "$(OUTPUT_FILE)" ] || cp $(DOWNLOAD_FILE) $(OUTPUT_FILE)
	[ -z "$(shell ssh root@callisto.angrydonkey.io ls /mnt/pve/iso/template/iso | grep $(FILENAME))" ] && \
		scp $(OUTPUT_FILE) root@callisto.angrydonkey.io:/mnt/pve/iso/template/iso/ || true

.PHONY: download
download:
	[ -e "$(CACHE_DIR)" ] || mkdir -p $(CACHE_DIR)
	[ -e "$(CACHE_FILE)" ] || curl -L -o $(CACHE_FILE) $(URL)
	[ -n "$(shell echo $(CACHE_FILE) | grep .zip)" ] && sudo unzip $(CACHE_FILE) $(if $(OUTPUT_DIR),-d $(OUTPUT_DIR)) || true
	[ -n "$(shell echo $(CACHE_FILE) | grep .tar.xz)" ] && sudo tar -xJf $(CACHE_FILE) $(TAR_ARGS) $(if $(OUTPUT_DIR),-C $(OUTPUT_DIR),) || true
	[ -n "$(shell echo $(CACHE_FILE) | grep -E '\/[^.]*\.xz')" ] && xz -dk $(CACHE_FILE) || true
	[ -n "$(shell echo $(CACHE_FILE) | grep .tar.gz)" ] && sudo tar -xvf $(CACHE_FILE) $(TAR_ARGS) $(if $(OUTPUT_DIR),-C $(OUTPUT_DIR),) || true
