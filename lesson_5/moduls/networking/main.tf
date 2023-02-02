

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  
  tags = {
    Name = "${var.env}-vpc"
  }
}
data "aws_availability_zones" "available"{

}

resource "aws_subnet" "public_subnets" {
  count       = length(var.public_subnet_cidrs)
  vpc_id      = aws_vpc.main.id
  cidr_block  = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.env}-public-${count.index }"
  }
}
resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  

  tags = {
    Name = "${var.env}-route-public-subnets"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}
resource "aws_route_table_association" "a" { 
    count=length(aws_subnet.public_subnets[*].id)
  subnet_id      =aws_subnet.public_subnets.*.id[count.index]
  route_table_id = aws_route_table.public_subnets.id
}

