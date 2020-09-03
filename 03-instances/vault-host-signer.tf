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
    id     = vault_approle_auth_backend_role.instance.id                  // auth/approle/role/instance
    role   = vault_approle_auth_backend_role.instance.role_id             // 4fd9e19e-b058-1d81-65a0-508d65d6c0c4
    secret = vault_approle_auth_backend_role_secret_id.instance.secret_id // d49a09c6-fd56-54e2-5b8b-a6328ff82dc1
  }
}
