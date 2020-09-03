locals {
  redirect_uri = "http://localhost:8250/oidc/callback"
  redirect_uris = [
    # "https://vault.vault-ssh.ryanwholey.com/ui/vault/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback"
  ]
}

data "aws_route53_zone" "primary" {
  name = var.hosted_zone
}

data "aws_ami" "fedora_coreos" {
  most_recent = true
  owners      = ["125523088429"] # Fedora

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "description"
    values = ["Fedora CoreOS stable *"]
  }
}
