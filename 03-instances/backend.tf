data "terraform_remote_state" "platform" {
  backend = "local"

  config = {
    path = "../01-platform/terraform.tfstate"
  }
}

data "terraform_remote_state" "terraform_user" {
  backend = "local"

  config = {
    path = "../02-terraform-user/terraform.tfstate"
  }
}
