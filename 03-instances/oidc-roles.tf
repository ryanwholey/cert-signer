resource "vault_jwt_auth_backend" "okta_oidc" {
  description = "Vault authorization backend using Okta as OIDC provider for human users."
  path        = "oidc"
  type        = "oidc"

  oidc_discovery_url = okta_auth_server.vault.issuer
  oidc_client_id     = okta_app_oauth.vault.client_id
  oidc_client_secret = okta_app_oauth.vault.client_secret

  default_role = "engineer"
  tune {
    listing_visibility = "unauth"
    default_lease_ttl  = "768h"
    max_lease_ttl      = "768h"
    token_type         = "default-service"
  }
}

resource "vault_jwt_auth_backend_role" "engineer" {
  backend               = vault_jwt_auth_backend.okta_oidc.path
  oidc_scopes           = ["openid", "profile", okta_auth_server_scope.groups.name]
  allowed_redirect_uris = local.redirect_uris
  role_type             = "oidc"
  role_name             = "engineer"
  token_policies        = [vault_policy.engineer.name]
  user_claim            = "sub"

  bound_claims = {
    department = "Engineering"
  }
}

data "vault_policy_document" "engineer" {
  rule {
    path         = "ssh-client-signer/sign/engineer"
    capabilities = ["update"]
    description  = "Allow engineers to sign their own certs"
  }

  rule {
    path         = "ssh-host-signer/config/ca"
    capabilities = ["read"]
    description  = "Allow engineers to read the public host key"
  }
}

resource "vault_policy" "engineer" {
  name   = "engineer"
  policy = data.vault_policy_document.engineer.hcl
}

resource "vault_jwt_auth_backend_role" "platform" {
  backend = vault_jwt_auth_backend.okta_oidc.path

  oidc_scopes           = ["openid", "profile", okta_auth_server_scope.groups.name]
  allowed_redirect_uris = local.redirect_uris
  role_type             = "oidc"
  role_name             = "platform"
  token_policies        = [vault_policy.admin.name]
  user_claim            = "sub"

  bound_claims = {
    department = "Engineering"
    division   = "Platform"
  }
}

data "vault_policy_document" "admin" {
  rule {
    path         = "*"
    capabilities = ["create", "read", "update", "list", "delete", "sudo"]
    description  = "Admin role policy"
  }
}

resource "vault_policy" "admin" {
  name   = "admin"
  policy = data.vault_policy_document.admin.hcl
}
