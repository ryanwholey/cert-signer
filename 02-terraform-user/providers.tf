provider "vault" {
  address = data.terraform_remote_state.platform.outputs.vault_addr

  token = var.vault_root_token

  # auth_login {
  #   path = "auth/approle/login"

  #   parameters = {
  #     role_id   = var.role_id
  #     secret_id = var.secret_id
  #   }
  # }
}
