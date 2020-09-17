module "private_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = local.cidr_map.private

  networks = [for az in var.azs :
    {
      name     = az
      new_bits = 6
    }
  ]
}

resource "aws_subnet" "private" {
  for_each = module.private_cidrs.network_cidr_blocks

  vpc_id     = aws_vpc.network.id
  cidr_block = each.value

  availability_zone = each.key

  tags = {
    Name = "${var.prefix}-private-${each.key}"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = [for subnet in aws_subnet.public: subnet.id][0]

  depends_on = [aws_internet_gateway.gateway]

  tags = {
    Name = var.prefix
  }
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.network.id

  tags = {
    Name = "${var.prefix}-private-${each.key}"
  }
}

resource "aws_route" "private" {
  for_each = aws_subnet.private

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private[each.key].id
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
