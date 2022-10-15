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
		vault read -field=public_key ssh/config/ca >$(PWD)/ssh_ca.pub

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
	cp ubuntu-20.04-server-cloudimg-amd64.img ubuntu-20.04-cloudimg.img
	sudo virt-customize -a ubuntu-20.04-cloudimg.img --install qemu-guest-agent
	sudo virt-customize -a ubuntu-20.04-cloudimg.img --upload ssh_ca.pub:/etc/ssh/ssh_ca.pub
	sudo virt-customize -a ubuntu-20.04-cloudimg.img --run-command "echo 'TrustedUserCAKeys /etc/ssh/ssh_ca.pub' >> /etc/ssh/sshd_config"

.PHONY: proxmox-cloudimg-template
proxmox-cloudimg-template:
	ssh root@blackhole.angrydonkey.io qm destroy 9000
	ssh root@blackhole.angrydonkey.io qm create 9000 \
		--name ubuntu-focal-template
	ssh root@blackhole.angrydonkey.io qm importdisk 9000 \
		/mnt/pve/proxmox-backup/template/iso/ubuntu-20.04-cloudimg.img proxmox-cache
	ssh root@blackhole.angrydonkey.io qm set 9000 \
		--net0 virtio,bridge=vmbr0
	ssh root@blackhole.angrydonkey.io qm set 9000 \
		--scsihw virtio-scsi-pci \
		--virtio0 proxmox-cache:9000/vm-9000-disk-0.raw
	ssh root@blackhole.angrydonkey.io qm set 9000 \
		--boot order=virtio0 \
		--agent 1 \
		--machine q35 \
		--cpu host
	ssh root@blackhole.angrydonkey.io qm template 9000
