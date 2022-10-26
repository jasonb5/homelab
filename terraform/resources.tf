locals {
  vms = {
    k3s-node1 = {
      target_node = "blackhole" 
      desc = "k3s server"
      memory = 16384
      cores = 6
      macaddr = "ca:10:3f:9a:2b:f6"
      disk_size = "512G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
    }
    k3s-node2 = {
      target_node = "hyperion"
      desc = "k3s agent"
      memory = 16384
      cores = 30
      macaddr = "4e:58:39:92:c1:fb"
      disk_size = "512G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
    }
    omada = {
      target_node = "hyperion"
      desc = "Omada SDN controller"
      memory = 1024
      cores = 1
      macaddr = "be:b5:4d:f3:74:0c"
      disk_size = "16G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
    }
    pihole = {
      target_node = "hyperion"
      desc = "Pi-hole"
      memory = 1024
      cores = 1
      macaddr = "fe:b5:3d:a3:10:1c"
      disk_size = "16G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
    }
    homeassistant = {
      target_node = "blackhole"
      desc = "home assistant"
      memory = 2048
      cores = 2
      macaddr = "1a:03:1b:0c:70:05"
      disk_size = "32G"
      clone = "haos-template"
      disk_type = "scsi"
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
  clone = each.value.clone
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
    type = each.value.disk_type
    storage = "local-lvm"
    size = each.value.disk_size
    slot = 0
  }
}
