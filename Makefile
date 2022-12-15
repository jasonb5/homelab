SHELL = /bin/bash

CURL_CMD = curl -sSLO

.PHONY: terraform-init
terraform-init:
	. $(PWD)/setup.sh && \
		terraform -chdir=terraform/ init -upgrade

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
proxmox-template: SSH_USER?=root
proxmox-template: SSH_HOST?=$(TARGET).$(DOMAIN)
proxmox-template: ID?=9000
proxmox-template: FILENAME?=ubuntu-20.04-cloudimg.img
proxmox-template: TEMPLATE_NAME?=ubuntu-focal-template
proxmox-template: BIOS?=seabios
proxmox-template:
	ssh $(SSH_USER)@$(SSH_HOST) qm create $(ID) \
		--name $(TEMPLATE_NAME)
	ssh $(SSH_USER)@$(SSH_HOST) qm importdisk $(ID) \
		/mnt/pve/backup/template/iso/$(FILENAME) local-lvm
	ssh $(SSH_USER)@$(SSH_HOST) qm set $(ID) \
		--net0 virtio,bridge=vmbr0
	ssh $(SSH_USER)@$(SSH_HOST) qm set $(ID) \
		--scsihw virtio-scsi-single \
		--virtio0 local-lvm:vm-$(ID)-disk-0
	ssh $(SSH_USER)@$(SSH_HOST) qm set $(ID) \
		--boot order=virtio0 \
		--tablet 0 \
		--bios $(BIOS) \
		--agent 1 \
		--machine q35 \
		--cpu host
	ssh $(SSH_USER)@$(SSH_HOST) qm template $(ID)

.PHONY: image-ubuntu-focal
image-ubuntu-focal: FLAVOR?=focal
image-ubuntu-focal: VERSION?=20.04
image-ubuntu-focal: FILENAME=ubuntu-$(VERSION)-server-cloudimg-amd64.img
image-ubuntu-focal: CUSTOMIZED_FILENAME=ubuntu-$(VERSION)-cloudimg.img
image-ubuntu-focal: URL=https://cloud-images.ubuntu.com/releases/$(FLAVOR)/release/$(FILENAME)
image-ubuntu-focal: SSH_USER?=root
image-ubuntu-focal: SSH_HOST?=charon.angrydonkey.io
image-ubuntu-focal: public-key
	set +x
	test -e $(FILENAME) || \
		$(CURL_CMD) $(URL)
	test ! -e $(CUSTOMIZED_FILENAME) || \
		rm $(CUSTOMIZED_FILENAME)
	cp $(FILENAME) $(CUSTOMIZED_FILENAME)
	sudo virt-customize -a $(CUSTOMIZED_FILENAME) --install qemu-guest-agent
	sudo virt-customize -a $(CUSTOMIZED_FILENAME) --upload ssh_ca.pub:/etc/ssh/ssh_ca.pub
	sudo virt-customize -a $(CUSTOMIZED_FILENAME) --run-command "echo 'TrustedUserCAKeys /etc/ssh/ssh_ca.pub' >> /etc/ssh/sshd_config"
	scp $(CUSTOMIZED_FILENAME) $(SSH_USER)@$(SSH_HOST):/mnt/user/proxmox-backup/template/iso

.PHONY: proxmox-template-ubuntu-focal
proxmox-template-ubuntu-focal:
	$(MAKE) proxmox-template

.PHONY: image-haos
image-haos: VERSION=9.3
image-haos: ARCHIVED_FILENAME=haos_ova-$(VERSION).qcow2.xz
image-haos: FILENAME=$(basename $(ARCHIVED_FILENAME))
image-haos: FILENAME_IMG=$(basename $(FILENAME)).img
image-haos: URL=https://github.com/home-assistant/operating-system/releases/download/$(VERSION)/$(ARCHIVED_FILENAME)
image-haos: SSH_USER?=root
image-haos: SSH_HOST?=charon.angrydonkey.io
image-haos: public-key
	test -e $(FILENAME_IMG) || \
		$(CURL_CMD) $(URL) && \
		7z x $(ARCHIVED_FILENAME) && \
		rm $(ARCHIVED_FILENAME) && \
		mv $(FILENAME) $(FILENAME_IMG)
	scp $(FILENAME_IMG) $(SSH_USER)@$(SSH_HOST):/mnt/user/proxmox-backup/template/iso

.PHONY: proxmox-template-haos
proxmox-template-haos: ID?=9001
proxmox-template-haos: FILENAME=haos_ova-9.3.img
proxmox-template-haos: TEMPLATE_NAME=haos-template
proxmox-template-haos:
	$(MAKE) proxmox-template \
		ID=$(ID) \
		FILENAME=$(FILENAME) \
		TEMPLATE_NAME=$(TEMPLATE_NAME) \
		BIOS=ovmf
