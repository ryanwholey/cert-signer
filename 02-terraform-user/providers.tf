provider "vault" {
  address = data.terraform_remote_state.platform.outputs.vault_addr
  token   = var.vault_root_token
}
