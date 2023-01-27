terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.51.0"
    }
  }
}
provider "aws" {
  region     = "eu-west-2"
}

resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  
  tags = {
    Name = "vpc"
  }
}
data "aws_availability_zones" "available"{

}

resource "aws_subnet" "subnet" {
    count = "${length(local.name)}"
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  tags = {
    Name = "subnet${count.index}"
  }
}
resource "aws_route_table" "nur_rt" {
    count=3
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  

  tags = {
    Name = "example${count.index}"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "vpc"
  }
}
resource "aws_route_table_association" "a" { 
    count=length(local.name)
  subnet_id      = aws_subnet.subnet.*.id[count.index]
  route_table_id = aws_route_table.nur_rt.*.id[count.index]
}

output "vpc_ids"{
    value = aws_vpc.vpc.id
}
output "subnet_ids"{
    value = aws_subnet.subnet.*.id
}