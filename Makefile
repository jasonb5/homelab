SHELL = /bin/bash

CURL_CMD = curl -sSLO

.PHONY: terraform-init
terraform-init:
	. $(PWD)/setup.sh && \
		terraform -chdir=terraform/ init

.PHONY: terraform-plan
terraform-plan:
	. $(PWD)/setup.sh && \
		terraform -chdir=terraform/ plan

.PHONY: terraform-apply
terraform-apply:
	. $(PWD)/setup.sh && \
		terraform -chdir=terraform/ apply

.PHONY: terraform-destroy
terraform-destroy:
	. $(PWD)/setup.sh && \
		terraform -chdir=terraform/ destroy

.PHONY: public-key
public-key:
	. $(PWD)/setup.sh && \
		test -e $(PWD)/ssh_ca.pub || vault read -field=public_key ssh/config/ca >$(PWD)/ssh_ca.pub

.PHONY: renew-cert
renew-cert:
	. $(PWD)/setup.sh && \
		unset VAULT_TOKEN && \
		vault login -method=userpass username=$(VAULT_USERNAME) password=$(VAULT_PASSWORD) && \
		vault write -field=signed_key ssh/sign/ssh-user public_key=@/home/titters/.ssh/id_homelab.pub valid_principals="root,$(VAULT_USERNAME)" >/home/titters/.ssh/id_homelab-cert.pub && \
		ssh-add -D && \
		ssh-add ~/.ssh/id_homelab

.PHONY: proxmox-template
proxmox-template: USER=root
proxmox-template: DOMAIN?=angrydonkey.io
proxmox-template: TARGET?=blackhole
proxmox-template: HOST?=$(TARGET).$(DOMAIN)
proxmox-template: ID?=9000
proxmox-template: FILENAME?=ubuntu-20.04-cloudimg.img
proxmox-template: TEMPLATE_NAME?=ubuntu-focal-20.04
proxmox-template:
	ssh $(USER)@$(HOST) qm create $(ID) \
		--name $(TEMPLATE_NAME)
	ssh $(USER)@$(HOST) qm importdisk $(ID) \
		/mnt/pve/backup/template/iso/$(FILENAME) local-lvm
	ssh $(USER)@$(HOST) qm set $(ID) \
		--net0 virtio,bridge=vmbr0
	ssh $(USER)@$(HOST) qm set $(ID) \
		--scsihw virtio-scsi-single \
		--scsi0 local-lvm:vm-$(ID)-disk-0
	ssh $(USER)@$(HOST) qm set $(ID) \
		--boot order=scsi0 \
		--tablet 0 \
		--bios ovmf \
		--agent 1 \
		--machine q35 \
		--cpu host
	ssh $(USER)@$(HOST) qm template $(ID)

.PHONY: ubuntu-focal-cloudimg
ubuntu-focal-cloudimg: FLAVOR?=focal
ubuntu-focal-cloudimg: VERSION?=20.04
ubuntu-focal-cloudimg: FILENAME=ubuntu-$(VERSION)-server-cloudimg-amd64.img
ubuntu-focal-cloudimg: CUSTOMIZED_FILENAME=ubuntu-$(VERSION)-cloudimg.img
ubuntu-focal-cloudimg: URL=https://cloud-images.ubuntu.com/releases/$(FLAVOR)/release/$(FILENAME)
ubuntu-focal-cloudimg: APT_PROXY?=http://10.50.20.181:3142
ubuntu-focal-cloudimg: USER?=root
ubuntu-focal-cloudimg: TARGET?=charon.angrydonkey.io
ubuntu-focal-cloudimg: public-key
	set +x
	test -e $(FILENAME) || \
		$(CURL_CMD) $(URL)
	test ! -e $(CUSTOMIZED_FILENAME) || \
		rm $(CUSTOMIZED_FILENAME)
	cp $(FILENAME) $(CUSTOMIZED_FILENAME)
	sudo virt-customize -a $(CUSTOMIZED_FILENAME) --install qemu-guest-agent
	sudo virt-customize -a $(CUSTOMIZED_FILENAME) --upload ssh_ca.pub:/etc/ssh/ssh_ca.pub
	sudo virt-customize -a $(CUSTOMIZED_FILENAME) --run-command "echo 'TrustedUserCAKeys /etc/ssh/ssh_ca.pub' >> /etc/ssh/sshd_config"
	sudo virt-customize -a $(CUSTOMIZED_FILENAME) --run-command "echo 'Acquire::http::Proxy \"$(APT_PROXY)\";' >> /etc/apt/apt.conf.d/proxy.conf"
	scp $(CUSTOMIZED_FILENAME) $(USER)@$(TARGET):/mnt/user/proxmox-backup/template/iso

.PHONY: proxmox-ubuntu-focal
proxmox-ubuntu-focal:
	$(MAKE) proxmox-template

.PHONY: haos
haos-image: VERSION=9.3
haos-image: ARCHIVED_FILENAME=haos_ova-$(VERSION).qcow2.xz
haos-image: FILENAME=$(basename $(ARCHIVED_FILENAME))
haos-image: FILENAME_IMG=$(basename $(FILENAME)).img
haos-image: URL=https://github.com/home-assistant/operating-system/releases/download/$(VERSION)/$(ARCHIVED_FILENAME)
haos-image: USER?=root
haos-image: TARGET?=charon.angrydonkey.io
haos-image: public-key
	test -e $(FILENAME_IMG) || \
		$(CURL_CMD) $(URL) && \
		7z x $(ARCHIVED_FILENAME) && \
		rm $(ARCHIVED_FILENAME) && \
		mv $(FILENAME) $(FILENAME_IMG)
	scp $(FILENAME_IMG) $(USER)@$(TARGET):/mnt/user/proxmox-backup/template/iso

PHONY: proxmox-haos
proxmox-haos: ID?=9001
proxmox-haos: FILENAME=haos_ova-9.3.img
proxmox-haos: TEMPLATE_NAME=haos-template
proxmox-haos:
	$(MAKE) proxmox-ubuntu-focal \
		ID=$(ID) \
		FILENAME=$(FILENAME) \
		TEMPLATE_NAME=$(TEMPLATE_NAME)
