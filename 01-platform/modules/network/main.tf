locals {
  cidr_map = zipmap(["public", "private"], cidrsubnets(var.cidr, 1, 1))
}

resource "aws_vpc" "network" {
  cidr_block = var.cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.prefix
  }
}


