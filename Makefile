CACHE_DIR ?= $(PWD)/cache

CONDA_DIR ?= $(HOME)/conda
CONDA_ENV_DIR = $(CONDA_DIR)/envs
CONDA_ACTIVATE = . $(CONDA_DIR)/etc/profile.d/conda.sh

.PHONY: new-template
new-template:
	@make -C charts/ new-template OUTPUT_DIR=$(PWD)/charts/charts

.PHONY: new-private-template
new-private-template:
	@make -C charts/ new-template OUTPUT_DIR=$(PWD)/private/charts

.PHONY: bootstrap
bootstrap:
	[ -n "$$($(CONDA_ACTIVATE); conda env list | grep ansible)" ] || \
		mamba create -n ansible "python<=3.10"

	$(CONDA_ACTIVATE); \
		conda activate ansible; \
		mamba install -y ansible hvac sshpass; \
		ansible-playbook -i ansible/hosts.yaml ansible/bootstrap.yaml -e vault_username=$(VAULT_USERNAME) -e vault_password=$(VAULT_PASSWORD)

.PHONY: deploy-kubernetes
deploy-kubernetes:
	[ -n "$$($(CONDA_ACTIVATE); conda env list | grep kubespray)" ] || \
		mamba create -n kubespray "python<=3.10"

	$(CONDA_ACTIVATE); \
		conda activate kubespray; \
		pip install -r kubespray/kubespray/requirements-2.12.txt; \
		cd kubespray/kubespray; \
		ansible-playbook -i ../hosts.yaml -e @"../custom.yaml" cluster.yml

.PHONY: upgrade-kubernetes
upgrade-kubernetes:
	[ -n "$$($(CONDA_ACTIVATE); conda env list | grep kubespray)" ] || \
		mamba create -n kubespray "python<=3.10"

	$(CONDA_ACTIVATE); \
		conda activate kubespray; \
		pip install -r kubespray/kubespray/requirements-2.12.txt; \
		cd kubespray/kubespray; \
		ansible-playbook -i ../hosts.yaml -e @"../custom.yaml" -e upgrade_cluster_setup=true cluster.yml

.PHONY: destroy-kubernetes
destroy-kubernetes:
	[ -n "$$($(CONDA_ACTIVATE); conda env list | grep kubespray)" ] || \
		mamba create -n kubespray "python<=3.10"

	$(CONDA_ACTIVATE); \
		conda activate kubespray; \
		pip install -r kubespray/kubespray/requirements-2.12.txt; \
		cd kubespray/kubespray; \
		ansible-playbook -i ../hosts.yaml -e @"../custom.yaml" reset.yml

.PHONY: blackhole.angrydonkey.io-9000-ubuntu-jammy
blackhole.angrydonkey.io-9000-ubuntu-jammy:
	$(MAKE) CALLING=$@ $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$@)))

.PHONY: deimos.angrydonkey.io-9001-ubuntu-jammy
deimos.angrydonkey.io-9001-ubuntu-jammy:
	$(MAKE) CALLING=$@ $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$@)))

.PHONY: deimos.angrydonkey.io-9002-haos
deimos.angrydonkey.io-9002-haos:
	$(MAKE) CALLING=$@ $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$@)))

ubuntu-jammy haos proxmox-vm: TARGET_HOST = $(word 1, $(subst -, ,$(CALLING)))
ubuntu-jammy haos proxmox-vm: ID = $(word 2, $(subst -, ,$(CALLING)))

.PHONY: ubuntu-jammy
ubuntu-jammy: URL = https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
ubuntu-jammy: MODIFY = base-
ubuntu-jammy: download modify-image upload proxmox-vm proxmox-template
	ssh root@$(TARGET_HOST) qm set $(ID) --ide2 local-lvm:cloudinit
	ssh root@$(TARGET_HOST) qm set $(ID) --serial0 socket --vga serial0

.PHONY: haos
haos: URL = https://github.com/home-assistant/operating-system/releases/download/10.2/haos_ova-10.2.qcow2.xz
haos: BIOS := ovmf
haos: RENAME_EXT := .qcow2 .img
haos: DISK_DRIVER = scsi0
haos: CORES = 2
haos: MEMORY = 2048
haos: download upload proxmox-vm proxmox-template
	ssh root@$(TARGET_HOST) qm set $(ID) --efidisk0 local-lvm:0,efitype=4m,pre-enrolled-keys=0

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
			sudo virt-customize -a $(OUTPUT_FILE) --copy-in ansible/artifacts/trusted-user-ca-keys.pem:/etc/ssh/ && \
			sudo virt-customize -a $(OUTPUT_FILE) --run-command 'chmod 0600 /etc/ssh/trusted-user-ca-keys.pem' && \
			sudo virt-customize -a $(OUTPUT_FILE) --install qemu-guest-agent && \
			sudo virt-customize -a $(OUTPUT_FILE) --append-line '/etc/ssh/sshd_config:TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem')

.PHONY: tool-vault
tool-vault: URL = https://releases.hashicorp.com/vault/1.13.3/vault_1.13.3_linux_amd64.zip
tool-vault: OUTPUT_DIR = /usr/local/bin/
tool-vault: download

.PHONY: tool-helm
tool-helm: URL = https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
tool-helm: OUTPUT_DIR = /usr/local/bin/
tool-helm: TAR_ARGS = --exclude='LICENSE' --exclude='README*' --strip-components 1 
tool-helm: download
	helm plugin install https://github.com/helm-unittest/helm-unittest.git || true
	helm plugin install https://github.com/jkroepke/helm-secrets || true
	helm plugin install https://github.com/databus23/helm-diff || true

.PHONY: tool-helmfile
tool-helmfile: URL = https://github.com/helmfile/helmfile/releases/download/v0.154.0/helmfile_0.154.0_linux_amd64.tar.gz
tool-helmfile: OUTPUT_DIR = /usr/local/bin/
tool-helmfile: TAR_ARGS = --exclude='LICENSE' --exclude='README*'
tool-helmfile: download

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
	[ -z "$(shell ssh root@blackhole.angrydonkey.io ls /mnt/pve/iso/template/iso | grep $(FILENAME))" ] && \
		scp $(OUTPUT_FILE) root@blackhole.angrydonkey.io:/mnt/pve/iso/template/iso/ || true

.PHONY: download
download:
	[ -e "$(CACHE_DIR)" ] || mkdir -p $(CACHE_DIR)
	[ -e "$(CACHE_FILE)" ] || curl -L -o $(CACHE_FILE) $(URL)
	[ -n "$(shell echo $(CACHE_FILE) | grep .zip)" ] && sudo unzip $(CACHE_FILE) $(if $(OUTPUT_DIR),-d $(OUTPUT_DIR)) || true
	[ -n "$(shell echo $(CACHE_FILE) | grep .tar.xz)" ] && sudo tar -xJf $(CACHE_FILE) $(TAR_ARGS) $(if $(OUTPUT_DIR),-C $(OUTPUT_DIR),) || true
	[ -n "$(shell echo $(CACHE_FILE) | grep -E '\/[^.]*\.xz')" ] && xz -dk $(CACHE_FILE) || true
	[ -n "$(shell echo $(CACHE_FILE) | grep .tar.gz)" ] && sudo tar -xvf $(CACHE_FILE) $(TAR_ARGS) $(if $(OUTPUT_DIR),-C $(OUTPUT_DIR),) || true
