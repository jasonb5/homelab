# Ansible
# Playbooks
| Name | Description |
| ---- | ----------- |
| bootstrap.yaml | Bootstraps Hashicorp Vault and baremetal nodes. | 
# Roles
| Name | Description |
| ---- | ----------- |
| vault/ssh-client-signer | Configures Vault SSH [Client key signing](https://developer.hashicorp.com/vault/docs/secrets/ssh/signed-ssh-certificates#client-key-signing), creates user keypair and signs the public key. |
| bootstrap-os | Configure ssh and create users. |