provider "vault" {
  address = data.terraform_remote_state.platform.outputs.vault_addr

  auth_login {
    path = "auth/${data.terraform_remote_state.terraform_user.outputs.approle_path}/login"

    parameters = data.terraform_remote_state.terraform_user.outputs.credentials
  }
}

provider "okta" {}
