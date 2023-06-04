locals {
  vms = {
    "homeassistant" = {
      vmid = 6000
      target_node = "deimos"
      clone = "template-haos"
      memory = 2048
      cores = 2
      macaddr = ""
      bios = "ovmf"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  for_each = local.vms

  name = each.key
  target_node = each.value.target_node
  vmid = each.value.vmid
  clone = each.value.clone
  full_clone = true
  memory = each.value.memory
  cores = each.value.cores
  bios = lookup(each.value, "bios", "seabios")
  scsihw = "virtio-scsi-pci"
  
  network {
    model = "virtio"
    macaddr = each.value.macaddr
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
