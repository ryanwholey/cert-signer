locals {
  subnet_id_list = [for id in var.subnet_ids: id]
  instance_meta = { for i in range(var.server_count): "vault-${i}" => {
    subnet_id = local.subnet_id_list[i % length(local.subnet_id_list)]
  }}
}