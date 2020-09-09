data "okta_everyone_group" "everyone" {}

resource "okta_auth_server" "vault" {
  audiences   = ["api://default"]
  description = "Vault authorization server with custom group claims"
  name        = "Vault"
  issuer_mode = "ORG_URL"
  status      = "ACTIVE"
}

resource "okta_auth_server_policy" "default" {
  auth_server_id   = okta_auth_server.vault.id
  status           = "ACTIVE"
  name             = "Default"
  description      = "Default authorization server policy"
  priority         = 1
  client_whitelist = ["ALL_CLIENTS"]
}

resource "okta_auth_server_policy_rule" "allow_all" {
  auth_server_id       = okta_auth_server.vault.id
  policy_id            = okta_auth_server_policy.default.id
  status               = "ACTIVE"
  name                 = "allow all"
  priority             = 1
  group_whitelist      = [okta_group.engineering.id]
  scope_whitelist      = ["openid", "profile", okta_auth_server_scope.groups.name]
  grant_type_whitelist = ["authorization_code"]
}

resource "okta_auth_server_scope" "groups" {
  auth_server_id   = okta_auth_server.vault.id
  metadata_publish = "ALL_CLIENTS"
  name             = "groups"
  consent          = "IMPLICIT"
  default          = true
}

resource "okta_auth_server_claim" "department" {
  auth_server_id = okta_auth_server.vault.id
  name           = "department"
  status         = "ACTIVE"
  claim_type     = "IDENTITY"
  value_type     = "EXPRESSION"
  value          = "user.department"
  scopes         = [okta_auth_server_scope.groups.name]
}

resource "okta_auth_server_claim" "division" {
  auth_server_id = okta_auth_server.vault.id
  name           = "division"
  status         = "ACTIVE"
  claim_type     = "IDENTITY"
  value_type     = "EXPRESSION"
  value          = "user.division"
  scopes         = [okta_auth_server_scope.groups.name]
}
