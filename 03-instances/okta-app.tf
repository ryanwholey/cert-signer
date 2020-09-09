resource "okta_group" "engineering" {
  name        = "engineering"
  description = "Engineering users"

  users = [
    for user in data.okta_user.engineering :
    user.id
  ]
}

data "okta_users" "engineering_search" {
  search {
    name       = "profile.department"
    value      = "Engineering"
    comparison = "sw"
  }
}

data "okta_user" "engineering" {
  for_each = toset([for user in data.okta_users.engineering_search.users : user.email])

  search {
    name  = "profile.email"
    value = each.value
  }
}

resource "okta_app_oauth" "vault" {
  label                      = "Vault"
  type                       = "web"
  token_endpoint_auth_method = "client_secret_post"
  login_uri                  = local.redirect_uri
  redirect_uris              = local.redirect_uris

  grant_types    = ["authorization_code"]
  response_types = ["code"]

  lifecycle {
    ignore_changes = [groups]
  }
}

resource "okta_app_group_assignment" "assign_engineering" {
  app_id   = okta_app_oauth.vault.id
  group_id = okta_group.engineering.id
}
