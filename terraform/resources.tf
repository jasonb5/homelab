locals {
  vms = {
    k3s-node1 = {
      target_node = "blackhole" 
      desc = "k3s server"
      memory = 16384
      cores = 6
      macaddr = "ca:10:3f:9a:2b:f6"
      disk_size = "512G"
    }
    k3s-node2 = {
      target_node = "hyperion"
      desc = "k3s agent"
      memory = 16384
      cores = 30
      macaddr = "4e:58:39:92:c1:fb"
      disk_size = "512G"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  for_each = local.vms

  name = each.key
  target_node = each.value.target_node
  vmid = 500 + index(keys(local.vms), each.key)
  desc = each.value.desc
  startup = "order=2"
  oncreate = false
  agent = 1
  clone = "ubuntu-focal-template"
  full_clone = true
  memory = each.value.memory
  cores = each.value.cores
  os_type = "cloud-init"
  ciuser = data.vault_kv_secret_v2.homelab.data.user
  cipassword = data.vault_kv_secret_v2.homelab.data.password
  ipconfig0 = "ip=dhcp"
  cloudinit_cdrom_storage = "local-lvm"

  network {
    model = "virtio"
    macaddr = each.value.macaddr
    bridge = "vmbr0"
    firewall = true
  }

  disk {
    type = "virtio"
    storage = "proxmox-cache"
    size = each.value.disk_size
    slot = 0
  }
}
