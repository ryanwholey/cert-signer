output "vault_addr" {
  value = module.vault.vault_addr
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}


output "cidr_block" {
  value = module.network.cidr_block
}
