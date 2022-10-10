# Homelab
This project contains everything I use to manage my homelab.

I will aim to document everything in my journey to manage my homelab.
# Setup
The current setup consists of two servers running [Proxmox](https://www.proxmox.com/en/) and a handful of [Raspberry Pi 4's](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/).

For storage I'm running [Unraid](https://unraid.net/) in a VM on one of the Proxmox servers. This Unraid server is also running a few services near the data:
* apt-cacher-ng
* minio
* vault
# Preparing cloud images
To prepare cloud images for provisioning on Proxmox, I am using [virt-customize](https://libguestfs.org/virt-customize.1.html) from `libguestfs`.

I would like to look into using pure [cloud-init](https://cloudinit.readthedocs.io/en/latest/) via [Terraform](https://www.terraform.io/) or [Packer](https://www.packer.io/).
# References
[1] <https://pawa.lt/posts/2019/07/automating-k3s-deployment-on-proxmox/> "Automating k3s Deployment on Proxmox"
