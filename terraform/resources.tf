locals {
  vms = {
    k3s-node1 = {
      vmid = 500
      target_node = "blackhole" 
      desc = "k3s server"
      bios = "ovmf"
      memory = 16384
      cores = 6
      macaddr = "ca:10:3f:9a:2b:f6"
      disk_size = "128G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
      bridge = "vmbr0"
    }
    dev = {
      vmid = 501
      target_node = "blackhole" 
      desc = "development machine"
      bios = "seabios"
      memory = 8192
      cores = 4
      macaddr = "62:79:ea:72:e7:32"
      disk_size = "64G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
      bridge = "vmbr0"
    }
    k3s-node2 = {
      vmid = 600
      target_node = "hyperion"
      desc = "k3s agent"
      bios = "seabios"
      memory = 16384
      cores = 30
      macaddr = "4e:58:39:92:c1:fb"
      disk_size = "128G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
      bridge = "vmbr0"
    }
    pihole1 = {
      vmid = 601
      target_node = "hyperion"
      desc = "Pi-hole"
      bios = "seabios"
      memory = 1024
      cores = 1
      macaddr = "fe:b5:3d:a3:10:1c"
      disk_size = "16G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
      bridge = "vmbr0"
    }
    homeassistant = {
      vmid = 602
      target_node = "hyperion"
      desc = "home assistant"
      bios = "ovmf"
      memory = 2048
      cores = 2
      macaddr = "1a:03:1b:0c:70:05"
      disk_size = "32G"
      clone = "haos-template"
      disk_type = "virtio"
      bridge = "vmbr1"
    }
    k3s-node3 = {
      vmid = 700
      target_node = "deimos"
      desc = "k3s agent"
      bios = "seabios"
      memory = 3072
      cores = 3
      macaddr = "16:16:5d:a8:b9:d6"
      disk_size = "128G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
      bridge = "vmbr0"
    }
    omada = {
      vmid = 701
      target_node = "deimos"
      desc = "Omada SDN controller"
      bios = "seabios"
      memory = 3072
      cores = 2
      macaddr = "be:b5:4d:f3:74:0c"
      disk_size = "16G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
      bridge = "vmbr0"
    }
    pihole2 = {
      vmid = 702
      target_node = "deimos"
      desc = "Pi-hole"
      bios = "seabios"
      memory = 1024
      cores = 1
      macaddr = "f2:15:38:bd:74:f9"
      disk_size = "16G"
      clone = "ubuntu-focal-template"
      disk_type = "virtio"
      bridge = "vmbr0"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  for_each = local.vms

  name = each.key
  target_node = each.value.target_node
  vmid = each.value.vmid
  desc = each.value.desc
  bios = each.value.bios
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
    bridge = each.value.bridge
    firewall = true
  }

  disk {
    type = each.value.disk_type
    storage = "local-lvm"
    size = each.value.disk_size
    slot = 0
  }
}
