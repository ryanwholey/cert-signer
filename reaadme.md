# Vault SSH Certs

Init and apply project `01-*`

Unseal Vault:

```sh
name=<TF_VAR_name>
hosted_zone=<TF_VAR_hosted_zone>
curl \
  -XPUT \
  --data '{"recovery_shares": 1, "recovery_threshold": 1}' \
  https://vault.${name}.${hosted_zone}/v1/sys/init
```

Save the root token in your env file

```sh
TF_VAR_vault_root_token=<token>
```
