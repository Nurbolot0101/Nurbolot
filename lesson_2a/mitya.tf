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

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  
  tags = {
    Name = "main"
  }
}
data "aws_availability_zones" "available"{

}

resource "aws_subnet" "main" {
    count = "${length(local.name)}"
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  tags = {
    Name = "Main${count.index}"
  }
}
resource "aws_route_table" "example" {
    count=3
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  

  tags = {
    Name = "example${count.index}"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}
resource "aws_route_table_association" "a" { 
    count=length(local.name)
  subnet_id      = aws_subnet.main.*.id[count.index]
  route_table_id = aws_route_table.example.*.id[count.index]
}
//LAUNCH_TEMPLATE
resource "aws_launch_template" "templete" {
  name = "nur-template"
  image_id           = "ami-0d09654d0a20d3ae2"
  instance_type = "t2.micro"
  user_data =base64encode(file("user_data.sh"))
#  network_interfaces {
#     device_index                = 0
#     associate_public_ip_address = false
#     security_groups             = ["${aws_security_group.allow_all.id}"]
#   }
  
  #key_name      = aws_key_pair.demo_roza.key_name
 
   tags = {
    Name = "nur-templete"
   }

  }
  resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow All inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "all from internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
ingress {
    description      = "all from internet"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

//AUTO_SCALING
resource "aws_autoscaling_group" "nur_auto" {
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
   mixed_instances_policy {
    launch_template {
      launch_template_specification {
    launch_template_id   = "${aws_launch_template.templete.id}"
      }
    }
   }

    target_group_arns = [aws_lb_target_group.nur_target.arn]
  vpc_zone_identifier  = aws_subnet.main[*].id
}
//TARGET
resource "aws_lb_target_group" "nur_target" {
  name     = "target-nur"
  port     = 80
  protocol = "HTTP"
  vpc_id     = aws_vpc.main.id
}

//LISTENER
resource "aws_lb_listener" "nur_lb" {
  load_balancer_arn = aws_lb.nur_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nur_target.arn
  }
}
//LB
resource "aws_lb" "nur_lb" {
  name               = "nurlb"
  internal           = false
  load_balancer_type = "application"
  security_groups             = ["${aws_security_group.allow_all.id}"]
  subnets = aws_subnet.main.*.id
  enable_http2       = false
  enable_deletion_protection = false
}


