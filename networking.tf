data "aws_vpc" "default" {
  default = true
}


resource "aws_vpc" "custom" {
  cidr_block = "10.0.0.0/16"

  tags = local.common_tags
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.custom.id

  tags = merge(local.common_tags, { Name = "main-igw" })
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.custom.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "public-subnet" })
}


# Create a private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.custom.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags              = merge(local.common_tags, { Name = "private-subnet" })
}

# Create a private subnet
resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.custom.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags              = merge(local.common_tags, { Name = "private-subnet2" })
}

# Create a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.custom.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, { Name = "public-route-table" })
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a NAT Gateway in the public subnet
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = merge(local.common_tags, { Name = "main-nat-gateway" })
}

# Create a route table for the private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.custom.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(local.common_tags, { Name = "private-route-table", })
}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "source" {
  name = "source-sg"

  description = "SG from where connection are allowes into the DB"
  vpc_id      = aws_vpc.custom.id

  tags = local.common_tags
}


resource "aws_security_group" "compliant" {
  name = "compliant-sg"

  description = "Compliant sg"
  vpc_id      = aws_vpc.custom.id

  tags = local.common_tags
}


resource "aws_security_group" "non_compliant" {
  name = "non-compliant-sg"

  description = " Non compliant sg"

  vpc_id = aws_vpc.custom.id

  tags = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "db" {
  security_group_id = aws_security_group.compliant.id

  referenced_security_group_id = aws_security_group.source.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.non_compliant.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}
