terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.51.0"
    }
  }
}
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "My VPC"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "main"
  }
}
resource "aws_subnet" "main" {
  count = 3
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.${count.index}.0/24"

  tags = {
    Name = "Mysubnet"
  }
}

resource "aws_route_table" "myRT" {
  count = 3
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


    tags = {
    Name = "myRT"
  }
}