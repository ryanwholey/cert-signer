# Vault SSH Certs

## Setup

This projet uses env vars to set a few variables across the projects. Copy `.env-example` to `.env` and fill out the required fields.

You can add them to your shell by running . ./env

## 01-platform

This project creates the public Vault cluster.

terraform init and apply project `01-*`

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

## 02-terraform-user

This project creates the terraform user we will use to provision the third project.

terraform init and apply


## 03-instances

This project creates a public bastion asg and an instance in the private subnet to. You can also uncomment the rds code to create a small database.

terraform init and apply


## CLI

The logs into Vault, requests a signed client certificate and stores it in ~/.ssh/id_rsa-cert.pub, and requests the host ca public key and stores it ~/.ssh/known-hosts.

### Getting started

```sh
cd cli
npm install
./bin/cli \
  --role platform \       # platform or engineer, engineer won't be able to reach the private instance
  --host <host> \         # host or bastion
  --environment staging   # any env will target the same bastion at the momment
```
