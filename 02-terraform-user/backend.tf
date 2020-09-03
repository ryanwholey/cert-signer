data "terraform_remote_state" "platform" {
  backend = "local"

  config = {
    path = "../01-platform/terraform.tfstate"
  }
}
