.PHONY: ansible-init
ansible-init:
	. $(PWD)/setup.sh && \
		cd ansible/ && \
		ansible-playbook -i hosts.yaml init.yaml

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

.PHONY: ubuntu-focal-cloudimg
ubuntu-focal-cloudimg: public-key
	test -e ubuntu-20.04-server-cloudimg-amd64.img || \
		curl -LO http://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img
	test -e ubuntu-20.04-cloudimg.img || rm ubuntu-20.04-cloudimg.img
	cp ubuntu-20.04-server-cloudimg-amd64.img ubuntu-20.04-cloudimg.img
	sudo virt-customize -a ubuntu-20.04-cloudimg.img --install qemu-guest-agent
	sudo virt-customize -a ubuntu-20.04-cloudimg.img --upload ssh_ca.pub:/etc/ssh/ssh_ca.pub
	sudo virt-customize -a ubuntu-20.04-cloudimg.img --run-command "echo 'TrustedUserCAKeys /etc/ssh/ssh_ca.pub' >> /etc/ssh/sshd_config"
	sudo virt-customize -a ubuntu-20.04-cloudimg.img --run-command "echo 'Acquire::http::Proxy \"http://192.168.55.53:3142\";' >> /etc/apt/apt.conf.d/proxy.conf"
	scp ubuntu-20.04-cloudimg.img root@charon.angrydonkey.io:/mnt/user/proxmox-backup/template/iso

.PHONY: proxmox-cloudimg-template-destroy
proxmox-cloudimg-template-destroy:
	ssh root@blackhole.angrydonkey.io qm destroy 9000

.PHONY: proxmox-cloudimg-template
proxmox-cloudimg-template: TARGET=blackhole
proxmox-cloudimg-template: ID=9000
proxmox-cloudimg-template:
	ssh root@$(TARGET).angrydonkey.io qm create $(ID) \
		--name ubuntu-focal-template
	ssh root@$(TARGET).angrydonkey.io qm importdisk $(ID) \
		/mnt/pve/backup/template/iso/ubuntu-20.04-cloudimg.img local-lvm
	ssh root@$(TARGET).angrydonkey.io qm set $(ID) \
		--net0 virtio,bridge=vmbr0
	ssh root@$(TARGET).angrydonkey.io qm set $(ID) \
		--scsihw virtio-scsi-pci \
		--virtio0 local-lvm:vm-$(ID)-disk-0
	ssh root@$(TARGET).angrydonkey.io qm set $(ID) \
		--boot order=virtio0 \
		--agent 1 \
		--machine q35 \
		--cpu host
	ssh root@$(TARGET).angrydonkey.io qm template $(ID)
