module "public_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = local.cidr_map.public

  networks = [for az in var.azs :
    {
      name     = az
      new_bits = 6
    }
  ]
}

resource "aws_subnet" "public" {
  for_each = module.public_cidrs.network_cidr_blocks

  vpc_id     = aws_vpc.network.id
  cidr_block = each.value

  availability_zone = each.key

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-${each.key}"
    "kubernetes.io/cluster/${var.prefix}" = "shared"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.network.id

  tags = {
    Name = var.prefix
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.network.id

  tags = {
    Name = "${var.prefix}-public"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
