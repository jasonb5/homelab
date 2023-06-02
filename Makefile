CACHE_DIR ?= $(PWD)/cache

.PHONY: bootstrap
bootstrap:
	ansible-playbook -i ansible/hosts.yaml ansible/bootstrap.yaml -e vault_username=$(VAULT_USERNAME) -e vault_password=$(VAULT_PASSWORD)

.PHONY: blackhole.angrydonkey.io-9000-ubuntu-jammy
blackhole.angrydonkey.io-9000-ubuntu-jammy:
	$(MAKE) CALLING=$@ $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$@)))

.PHONY: deimos.angrydonkey.io-9001-ubuntu-jammy
deimos.angrydonkey.io-9001-ubuntu-jammy:
	$(MAKE) CALLING=$@ $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$@)))

.PHONY: deimos.angrydonkey.io-9002-haos
deimos.angrydonkey.io-9002-haos:
	$(MAKE) CALLING=$@ $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$@)))

ubuntu-jammy haos proxmox-template: TARGET_HOST = $(word 1, $(subst -, ,$(CALLING)))
ubuntu-jammy haos proxmox-template: ID = $(word 2, $(subst -, ,$(CALLING)))

.PHONY: ubuntu-jammy
ubuntu-jammy: URL = https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
ubuntu-jammy: MODIFY = base-
ubuntu-jammy: download modify-image upload proxmox-template
	ssh root@$(TARGET_HOST) qm set $(ID) --ide2 local-lvm:cloudinit
	ssh root@$(TARGET_HOST) qm set $(ID) --serial0 socket --vga serial0

.PHONY: haos
haos: URL = https://github.com/home-assistant/operating-system/releases/download/10.2/haos_ova-10.2.qcow2.xz
haos: BIOS := ovmf
haos: RENAME_EXT = .qcow2 .img
haos: download upload proxmox-template
	ssh root@$(TARGET_HOST) qm set $(ID) --efidisk0 local-lvm:0,efitype=4m,pre-enrolled-keys=0

.PHONY: proxmox-template
proxmox-template: TEMPLATE_NAME = $(subst $() $(),-,$(wordlist 3,20,$(subst -, ,$(CALLING))))
proxmox-template:
	ssh root@$(TARGET_HOST) qm create $(ID) --name template-$(TEMPLATE_NAME)
	ssh root@$(TARGET_HOST) qm importdisk $(ID) /mnt/pve/iso/template/iso/$(FILENAME) local-lvm
	ssh root@$(TARGET_HOST) qm set $(ID) --memory $(if $(MEMORY),$(MEMORY),1024) --cores $(if $(CORES),$(CORES),1) --cpu host
	ssh root@$(TARGET_HOST) qm set $(ID) --net0 virtio,bridge=vmbr0
	ssh root@$(TARGET_HOST) qm set $(ID) --scsihw virtio-scsi-pci --virtio0 local-lvm:vm-$(ID)-disk-0
	ssh root@$(TARGET_HOST) qm set $(ID) --boot order=virtio0 --agent enabled=1 --bios $(if $(BIOS),$(BIOS),seabios)
	ssh root@$(TARGET_HOST) qm template $(ID)

.PHONY: modify-image
modify-image:
	[ -e "$(OUTPUT_FILE)" ] || \
		(cp $(CACHE_FILE) $(OUTPUT_FILE) && \
			sudo virt-customize -a $(OUTPUT_FILE) --copy-in ansible/artifacts/trusted-user-ca-keys.pem:/etc/ssh/ && \
			sudo virt-customize -a $(OUTPUT_FILE) --run-command 'chmod 0600 /etc/ssh/trusted-user-ca-keys.pem' && \
			sudo virt-customize -a $(OUTPUT_FILE) --install qemu-guest-agent && \
			sudo virt-customize -a $(OUTPUT_FILE) --append-line '/etc/ssh/sshd_config:TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem')

remove_ext = $(subst $(suffix $(1)),,$(1))
find_ext = $(foreach EXT,.xz .tar,$(findstring $(EXT),$(1)))
parse_filename = $(if $(or $(strip $(call find_ext,$(1)))),$(call remove_ext,$(1)),$(1))
rename_ext = $(if $(findstring $(firstword $(1)),$(2)),$(subst $(firstword $(1)),$(lastword $(1)),$(2)),$(2))

download upload modify-image proxmox-template: _URL_FILENAME = $(lastword $(subst /, ,$(URL)))
download upload modify-image proxmox-template: _FILENAME = $(call parse_filename,$(_URL_FILENAME))
download upload modify-image proxmox-template: FILENAME = $(if $(RENAME_EXT),$(call rename_ext,$(RENAME_EXT),$(_FILENAME)),$(_FILENAME))
download upload modify-image proxmox-template: CACHE_FILE = $(CACHE_DIR)/$(if $(MODIFY),$(MODIFY)$(_URL_FILENAME),$(_URL_FILENAME))
download upload modify-image proxmox-template: OUTPUT_FILE = $(CACHE_DIR)/$(_FILENAME)

.PHONY: upload
upload:
	[ -z "$(shell ssh root@blackhole.angrydonkey.io ls /mnt/pve/iso/template/iso | grep $(FILENAME))" ] && \
		scp $(OUTPUT_FILE) root@blackhole.angrydonkey.io:/mnt/pve/iso/template/iso/$(FILENAME) || true

.PHONY: download
download:
	[ -e "$(CACHE_DIR)" ] || mkdir -p $(CACHE_DIR)
	[ -e "$(CACHE_FILE)" ] || curl -L -o $(CACHE_FILE) $(URL)
	[ -n "$(shell echo $(CACHE_FILE) | grep .xz)" ] && xz -dk $(CACHE_FILE) || true
