output "vpc_id" {
  value = aws_vpc.network.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "cidr_block" {
  value = aws_vpc.network.cidr_block
}
