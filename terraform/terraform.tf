terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.20.1"
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
    endpoints = {
      s3 = "https://s3.angrydonkey.io"
    }
    use_path_style = true
    skip_credentials_validation = true
    skip_region_validation = true
    skip_metadata_api_check = true
    skip_requesting_account_id = true
  }
}
