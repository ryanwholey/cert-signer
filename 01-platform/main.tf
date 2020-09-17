data "aws_availability_zones" "available" {
  state = "available"
}

module "network" {
  source = "./modules/network"

  cidr   = "10.0.0.0/16"
  prefix = var.name
  azs    = slice([for az in data.aws_availability_zones.available.names : az], 0, 2)
}

module "vault" {
  source = "./modules/vault-coreos"

  name        = var.name
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.public_subnet_ids
  hosted_zone = var.hosted_zone

  is_public = true

  trusted_services = ["ec2.amazonaws.com"]

  ssh_user                       = var.ssh_user
  s3_authorized_keys_bucket_path = var.ssh_authorized_keys_bucket_path

  cert_organization = var.organization

  server_count = 1

  client_ingress_cidrs = ["0.0.0.0/0"]
  ssh_ingress_cidrs    = ["0.0.0.0/0"]
  peer_ingress_cidrs   = [module.network.cidr_block]
}
