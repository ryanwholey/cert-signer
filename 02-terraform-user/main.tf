data "vault_policy_document" "terraform" {
  # Additional capabilities needed to modify system paths
  # See 'sudo' descrption here https://www.vaultproject.io/docs/concepts/policies#capabilities
  rule {
    path         = "*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    description  = "Allows Terraform to manage paths broadly across Vault."
  }

  rule {
    path         = "auth/*"
    capabilities = ["create", "update", "delete", "read", "sudo"]
    description  = "Manage authentication backends broadly across Vault"
  }

  rule {
    path         = "sys/auth/*"
    capabilities = ["create", "update", "delete", "sudo"]
    description  = "Create, modify, and delete authentication backends"
  }

  rule {
    path         = "sys/mounts/*"
    capabilities = ["create", "read", "update", "delete", "sudo"]
    description  = "Mount and manage secret backends broadly across Vault"
  }

  rule {
    path         = "auth/token/create"
    capabilities = ["create", "update", "delete", "sudo"]
    description  = "Allow terraform role to create short-lived tokens, used as an automatic process by the Vault provider."
  }

  rule {
    path         = "auth/token/lookup"
    capabilities = ["create", "read", "update", "delete"]
    description  = "Allow terraform role to create short-lived tokens, used as an automatic process by the Vault provider."
  }

  rule {
    path         = "auth/token/lookup-self"
    capabilities = ["read"]
    description  = "Allow terraform role to read information about its token."
  }

  rule {
    path         = "sys/capabilities-self"
    capabilities = ["read", "update"]
    description  = "Allow checking the capabilities of terraform role token."
  }
}

resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_policy" "terraform" {
  name   = "terraform"
  policy = data.vault_policy_document.terraform.hcl
}

resource "vault_approle_auth_backend_role" "terraform" {
  backend        = vault_auth_backend.approle.path
  role_name      = "terraform"
  token_policies = [vault_policy.terraform.name]
}

resource "vault_approle_auth_backend_role_secret_id" "terraform" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.terraform.role_name
}
