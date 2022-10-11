data "vault_kv_secret_v2" "homelab" {
  mount = "homelab"
  name = "host"
}
