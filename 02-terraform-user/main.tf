data "vault_policy_document" "terraform" {
  # Additional capabilities needed to modify system paths
  # See 'sudo' descrption here https://www.vaultproject.io/docs/concepts/policies#capabilities
  rule {
    path         = "*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    description  = "Allows Terraform to manage paths broadly across Vault."
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
