output "vault_addr" {
  value = "https://${aws_route53_record.vault.name}"
}
