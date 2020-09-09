resource "vault_mount" "ssh_host" {
  path = "ssh-host-signer"
  type = "ssh"
}

resource "vault_ssh_secret_backend_ca" "host_ca" {
  backend              = vault_mount.ssh_host.path
  generate_signing_key = true
}

data "vault_auth_backend" "approle" {
  path = "approle"
}

resource "vault_approle_auth_backend_role" "instance" {
  backend        = data.vault_auth_backend.approle.path
  role_name      = "instance"
  token_policies = ["default", vault_policy.instance.name]
}

resource "vault_approle_auth_backend_role_secret_id" "instance" {
  backend   = data.vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.instance.role_name
}

data "vault_policy_document" "instance" {
  rule {
    path         = "ssh-host-signer/sign/instance"
    capabilities = ["update"]
    description  = "Allow hosts to sign their own certs"
  }
}

resource "vault_policy" "instance" {
  name   = "instance"
  policy = data.vault_policy_document.instance.hcl
}

resource "vault_ssh_secret_backend_role" "instance" {
  name     = "instance"
  backend  = vault_mount.ssh_host.path
  key_type = "ca"

  allow_host_certificates = true
  allowed_domains         = "bastion.${var.hosted_zone}"
  allow_subdomains        = true # maybe remove?
}

output "approle" {
  value = {
    id     = vault_approle_auth_backend_role.instance.id
    role   = vault_approle_auth_backend_role.instance.role_id
    secret = vault_approle_auth_backend_role_secret_id.instance.secret_id
  }
}
