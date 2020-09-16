resource "vault_mount" "ssh_client" {
  path = "ssh-client-signer"
  type = "ssh"
}

resource "vault_ssh_secret_backend_ca" "client_ca" {
  backend              = vault_mount.ssh_client.path
  generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "engineer" {
  name          = "engineer"
  backend       = vault_mount.ssh_client.path
  key_type      = "ca"
  default_user  = "engineer"
  allowed_users = "engineer"

  allowed_extensions = "permit-port-forwarding,permit-tunnel"
  default_extensions = {
    "permit-port-forwarding" = ""
    "permit-tunnel"          = ""
  }

  allow_user_certificates = true

  ttl     = "60"
  max_ttl = "60"
}

resource "vault_ssh_secret_backend_role" "platform" {
  name          = "platform"
  backend       = vault_mount.ssh_client.path
  key_type      = "ca"
  default_user  = "platform"
  allowed_users = "engineer,platform"

  allowed_extensions = "permit-pty,permit-port-forwarding,permit-tunnel"
  default_extensions = {
    "permit-pty"             = ""
    "permit-port-forwarding" = ""
    "permit-tunnel"          = ""
  }

  allow_user_certificates = true

  ttl     = "60"
  max_ttl = "60"
}
