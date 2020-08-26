data "aws_availability_zones" "available" {
  state = "available"
}

module "network" {
  source = "../terraform/network"

  cidr = "10.0.0.0/16"
  prefix = var.name
  azs = slice([for az in data.aws_availability_zones.available.names : az], 0, 2)
}

module "bastion" {
  source = "../terraform/bastion"

  vpc_id           = module.network.vpc_id
  name             = var.name
  hosted_zone      = var.hosted_zone
  public_subnet_id = [for subnet_id in module.network.public_subnet_ids : subnet_id][0]
}

module "vault" {
  source = "../terraform/vault-coreos"

  trusted_services = ["ec2.amazonaws.com"]  
  vpc_id = module.network.vpc_id  
  client_ingress_cidrs = [module.network.cidr]
  name = var.name
  private_subnet_ids = module.network.private_subnet_ids
  cert_organization = var.organization
  ssh_ingress_cidrs = [module.network.cidr]
  peer_ingress_cidrs = [module.network.cidr]
  ssh_user = var.ssh_user
  s3_authorized_keys_bucket_path = var.ssh_authorized_keys_bucket_path
  hosted_zone = var.hosted_zone
}