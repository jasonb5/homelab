locals {
  vms = {
    "homeassistant" = {
      vmid = 6000
      desc = "Home Assistant OS"
      target_node = "deimos"
      clone = "template-haos"
      memory = 2048
      cores = 2
      macaddr = "7a:1d:0e:8d:7f:59"
      bios = "ovmf"
    }
  }
  cloud-vms = {
    "k8s-01" = {
      vmid = 6001
      desc = "Kubernetes control plane"
      target_node = "deimos"
      clone = "template-ubuntu-jammy"
      memory = 8192
      cores = 4
      macaddr = "02:06:24:ba:26:f0"
      disk1 = {
        size = "192G" 
      }
    }
    "k8s-02" = {
      vmid = 6002
      desc = "Kubernetes worker"
      target_node = "blackhole"
      clone = "template-ubuntu-jammy"
      memory = 8192
      cores = 8
      macaddr = "02:b2:e2:13:6d:ac"
      disk1 = {
        size = "192G" 
      }
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  for_each = local.vms

  name = each.key
  target_node = each.value.target_node
  vmid = each.value.vmid
  desc = each.value.desc
  clone = each.value.clone
  full_clone = true
  memory = each.value.memory
  cores = each.value.cores
  bios = lookup(each.value, "bios", "seabios")
  scsihw = "virtio-scsi-pci"
  agent = lookup(each.value, "agent", 1)
  
  network {
    model = "virtio"
    macaddr = each.value.macaddr
    bridge = "vmbr0"
    firewall = true
  }

  dynamic "disk" {
    for_each = (lookup(each.value, "disk1", "false") != "false") ? { enabled = true } : {}

    content {
      type = "virtio"
      storage = "local-lvm"
      size = each.value.disk1.size
      file = "vm-${each.value.vmid}-disk-0"
    }
  }

  dynamic "disk" {
    for_each = (lookup(each.value, "disk2", "false") != "false") ? { enabled = true } : {}

    content {
      type = "virtio"
      storage = "local-lvm"
      size = each.value.disk2.size
      file = "vm-${each.value.vmid}-disk-1"
    }
  }
}

resource "proxmox_vm_qemu" "cloud-vm" {
  for_each = local.cloud-vms

  name = each.key
  target_node = each.value.target_node
  vmid = each.value.vmid
  desc = each.value.desc
  clone = each.value.clone
  full_clone = true
  memory = each.value.memory
  cores = each.value.cores
  bios = lookup(each.value, "bios", "seabios")
  scsihw = "virtio-scsi-pci"
  agent = lookup(each.value, "agent", 1)

  os_type = "cloud-init"
  ipconfig0 = "ip=dhcp"
  
  network {
    model = "virtio"
    macaddr = each.value.macaddr
    bridge = "vmbr0"
    firewall = true
  }

  dynamic "disk" {
    for_each = (lookup(each.value, "disk1", "false") != "false") ? { enabled = true } : {}

    content {
      type = "virtio"
      storage = "local-lvm"
      size = each.value.disk1.size
      file = "vm-${each.value.vmid}-disk-0"
    }
  }

  dynamic "disk" {
    for_each = (lookup(each.value, "disk2", "false") != "false") ? { enabled = true } : {}

    content {
      type = "virtio"
      storage = "local-lvm"
      size = each.value.disk2.size
      file = "vm-${each.value.vmid}-disk-1"
    }
  }
}
