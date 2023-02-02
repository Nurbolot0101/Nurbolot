/*LAUNCH_TEMPLATE
provider "aws"{
   region     = "eu-west-2"
}
resource "aws_launch_template" "nur_template" {
  name = "nur_template"
  image_id           = "ami-0d09654d0a20d3ae2"
  instance_type = "t2.micro"
  user_data =base64encode(file("user_data.sh"))
 network_interfaces {
    device_index                = 0
    associate_public_ip_address = true 
    security_groups             = ["${aws_security_group.allow_all.id}"]
  }
  
  #key_name      = aws_key_pair.demo_roza.key_name
 
   tags = {
    Name = "nur-templete"
   }

  }
  resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow All inbound traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_ids

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
    launch_template_id   = "${aws_launch_template.nur_template.id}"
      }
    }
   }

    target_group_arns = [aws_lb_target_group.nur_target.arn]
  vpc_zone_identifier  = data.terraform_remote_state.network.outputs.subnet_ids
}
//TARGET
resource "aws_lb_target_group" "nur_target" {
  name     = "target-nur"
  port     = 80
  protocol = "HTTP"
  vpc_id     = data.terraform_remote_state.network.outputs.vpc_ids
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
  subnets = data.terraform_remote_state.network.outputs.subnet_ids
  enable_http2       = false
  enable_deletion_protection = false
}

data "terraform_remote_state" "network"{
    backend = "local"
    config={
        path = "../lesson_3/terraform.tfstate"
    }
}
*/

#========================================================================
#
#
#
#========================================================================


//SECURITY_GROUP
resource "aws_security_group" "security" {
  name        = "${var.env}-security-group"
  description = "Allow TLS inbound traffic"
   vpc_id      = var.vpc_id



dynamic "ingress" {
  for_each = var.ingress_ports
  content {
        from_port   = ingress.value
        to_port     = ingress.value
        protocol    = "tcp"
        cidr_blocks = var.egress_cidr
  }

}
egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = var.egress_cidr
        ipv6_cidr_blocks = ["::/0"]
  
}
}



data "aws_ami" "latest_ubuntu" {
 owners           = ["099720109477"]
 most_recent      = true
 filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230115*"]
  }
}

//LAUNCH_TEMPLATE
resource "aws_launch_template" "templete" {
  name = "${var.env}-template"
  image_id           = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type

 network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = ["${aws_security_group.security.id}"]
  }
  
 
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.env}-Nurbolot"
    }
  }
user_data = base64encode("#!/bin/bash \n sudo su \n apt update -y \n apt install apache2 -y \n apt install wget -y \n apt install unzip -y \n systemctl enable apache2 \n systemctl start apache2  \n wget https://github.com/ra1mova/portfolio/archive/refs/heads/main.zip \n unzip main.zip \n A \n cd portfolio-main \n mv README.md css/ fetch.html image/ index.html js/ shop.html /var/www/html/ \nnohup python -m SimpleHTTPServer 80 &")
}

resource "aws_autoscaling_group" "example" {
  launch_template {
    id = aws_launch_template.templete.id
  }
  name = "${var.env}-autoscale"

  min_size = var.instance_count
  max_size = var.max_size
  desired_capacity = 2

  vpc_zone_identifier = var.subnet_ids
}
# //loadbalancer
resource "aws_lb" "nurbolot" {
  name            = "${var.env}-lb"
  internal        = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.security.id]
  subnets         = var.subnet_ids
}
//listener
resource "aws_lb_listener" "nurbolot" {
  load_balancer_arn = aws_lb.nurbolot.arn
  port              = 80
  protocol          = "HTTP"

  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}
//target group
resource "aws_lb_target_group" "target" {
  name     = "target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}
