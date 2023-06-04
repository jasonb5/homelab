terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.15.2"
    }
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.14"
    }
  }

  backend "s3" {
    bucket = "homelab"
    key = "state.tf"
    region = "minio"
    endpoint = "https://minio.angrydonkey.io"
    force_path_style = true
    skip_credentials_validation = true
    skip_region_validation = true
    skip_metadata_api_check = true
  }
}
