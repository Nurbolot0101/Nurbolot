terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.51.0"
    }
  }
}
provider "aws" {
  region     = "ap-southeast-1"
}

module "vpc-dev" {
    source = "../../moduls/networking"
}
 module "autoscaling"{
  source = "../../moduls/autoscaling" 
 vpc_id = module.vpc-dev.vpc_id
 subnet_ids = module.vpc-dev.public_subnet_ids
 env = "Nur"
 instance_count = 2
 max_size = 3
 }

 


