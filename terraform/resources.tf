resource "proxmox_vm_qemu" "vm" {
  for_each = jsondecode(data.local_file.hosts.content).vm

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

resource "proxmox_vm_qemu" "cloud" {
  for_each = jsondecode(data.local_file.hosts.content).cloud

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
