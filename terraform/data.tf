data "local_file" "hosts" {
  filename = var.host_config_file
}

data "vault_kv_secret_v2" "password" {
  mount = "homelab"
  name = "baremetal"
}
