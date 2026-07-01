terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-east-1"
}
variable vpc_cidr {
  default = "10.0.0.0/16"
}
variable public_subnets {
  default = ["10.0.1.0/24"]
}
variable availability_zone_HK {
  default = ["ap-east-1a"]
} 
variable "private_subnets" {
  default = ["10.0.11.0/24"]
}
variable env_prefix {
  default = "ansible"
}
variable public_key {
  default = "/Users/yiran/.ssh/id_rsa.pub"
}
variable image_name {
  default = "ami-0e91a3e208f2ff02e"
}
variable image_type {
  default = "t3.micro"
}
# ========== 香港 VPC ==========
module "vpc_hk" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc-HK"
  cidr = var.vpc_cidr

  azs             = var.availability_zone_HK
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = true
  map_public_ip_on_launch = true
}
# ========== 香港 EC2 ==========
module "ec2_instance_hk" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"
  count = 2
  name = "instance-${count.index}"
  ami = var.image_name
  instance_type = var.image_type
  key_name      = "id-rsa"
  monitoring    = true
  subnet_id = element(module.vpc_hk.public_subnets, count.index)
  associate_public_ip_address = true
}

output "instance_public_ip_hk" {
  value = module.ec2_instance_hk[*].public_ip
}
