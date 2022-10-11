terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.11"
    }
    vault = {
      source = "hashicorp/vault"
      version = "3.9.1"
    }
  }
}
