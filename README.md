# Homelab
This project contains everything I use to manage my homelab.

I will aim to document everything in my journey to manage my homelab.
# Setup
The current setup consists of two servers running [Proxmox][1] and a handful of [Raspberry Pi 4's][2].

For storage I'm running [Unraid][3] in a VM. 

The Unraid server is running a few docker containers.
* [apt-cacher-ng][4]
* [gitea][5]
* [minio][6]
* [traefik][7]
* [vault][8]
# Preparing cloud images
The VMs provisioned on Proxmox are using cloud images, to prepare these images I'm using [virt-customize][9] from `libguestfs`.
# Software
I'm using [Ansible][10] to automate deploying software on to the VMs and rpi4s.

* [K3S][12]
* [Pi-hole][13]
* [Home Assistant][14]
* [Omada][15]
# Apps
The rest of the apps are running on [K3S][12], managed using [Helmfile][16].

[1]: <https://www.proxmox.com/en/> "Proxmox"
[2]: <https://www.raspberrypi.com/products/raspberry-pi-4-model-b/> "Raspberry Pi 4"
[3]: <https://unradi.net/> "Unraid"
[4]: <https://www.unix-ag.uni-kl.de/~bloch/acng/html/index.html> "Apt-Cacher-NG"
[5]: <https://gitea.io/en-us/> "Gitea"
[6]: <https://min.io/docs/minio/kubernetes/upstream/> "Minio"
[7]: <https://doc.traefik.io/traefik/> "Traefik"
[8]: <https://www.vaultproject.io/> "HashiCorp Vault"
[9]: <https://libguestfs.org/virt-customize.1.html> "virt-customize"
[10]: <https://www.ansible.com/> "Ansible"
[11]: <https://pawa.lt/posts/2019/07/automating-k3s-deployment-on-proxmox/> "Automating k3s Deployment on Proxmox"
[12]: <https://k3s.io/> "K3S"
[13]: <https://pi-hole.net/> "Pi-hole"
[14]: <https://www.home-assistant.io/> "Home Assistant"
[15]: <https://www.tp-link.com/us/support/download/omada-software-controller/> "Omada Software Controller"
[16]: <https://helmfile.readthedocs.io/en/latest/> "Helmfile"
