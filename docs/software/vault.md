# Vault

Some notes on setting up and using [Vault](https://developer.hashicorp.com/vault) in my homelab.

## Ansible
There is an ansible role that will setup a `kv` secrets engine and client key signing for SSH access.

## Access
Vault is accessed using the root token for any configuration and a user account for secrets.

### Root
When running commands that require root privileges, I'll export `VAULT_TOKEN` and execute the command. This will prevent the creation of `~/.vault-token` and accidental exposure of the token.
```
export VAULT_TOKEN=<token>
```
### User
User/pass authentication is enabled with the following command:

Documentation can be found [here](https://developer.hashicorp.com/vault/docs/auth/userpass)
```
vault auth enable userpass
```

Creating a user can be done with the `write` command.
```
vault write auth/userpass/users/<username> password=<password>
```

## Creating a secrets engine
This will create a new version 2 secrets engine at the `homelab` path.

Documentation can be found [here](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2#kv-secrets-engine-version-2)
```
vault secrets enable -path=homelab kv-v2
```

### Creating a secret
The following will create a secret under the homelab path containing the key/value pair.
```
vault kv put -mount=homelab <secret_path> <key>=<value>
```

## Policies
To limit the scope of a user to the `homelab` path, a policy can be created and applied to the user.

Documentation can be found [here](https://developer.hashicorp.com/vault/docs/concepts/policies#policies)
```
cat << EOF >> homelab.hcl
path "homelab" {
	capabilities = ["create", "read", "update", "patch", "delete", "list"]
}
EOF
```

The policy can be applied to the user using the same `write` command but providing the `policies` argument.
```
vault policy write homelab homelab.hcl

vault write auth/userpass/users/<username> password=<password> policies="homelab"
```
