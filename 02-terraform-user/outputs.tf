output "credentials" {
  value = {
    role_id   = vault_approle_auth_backend_role.terraform.role_id
    secret_id = vault_approle_auth_backend_role_secret_id.terraform.secret_id
  }
}

output "approle_path" {
  value = vault_auth_backend.approle.path
}
