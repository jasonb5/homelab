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

  backend "s3" {
    bucket = "homelab"
    key = "terraform.tfstate"
    region = "us-east-1"
    force_path_style = true
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_region_validation = true
  }
}
