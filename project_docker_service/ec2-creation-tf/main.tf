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
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "availability_zone_HK" {
  type    = list(string)
  default = ["ap-east-1a"]
} 

variable "image_name" {
  type    = string
  default = "ami-0e91a3e208f2ff02e"
}

variable "image_type" {
  type    = string
  default = "t3.micro"
}
# ========== 香港 VPC ==========
module "vpc_hk" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc-HK"
  cidr = var.vpc_cidr

  azs             = var.availability_zone_HK
  public_subnets  = var.public_subnets
  map_public_ip_on_launch = true
}
locals {
  ports = [22, 80, 8080]
}
resource "aws_security_group" "ansible_sg" {
  name   = "ansible_sg"
  vpc_id = module.vpc_hk.vpc_id

  dynamic "ingress"{
    for_each = local.ports
    content {
      from_port   = ingress.value  
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  ingress {
    from_port   = -1            # -1 代表所有 ICMP 类型
    to_port     = -1            # -1 代表所有 ICMP 代码
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ========== 香港 EC2 ==========
module "ec2_instance_hk" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"
  count = 2
  name = "instance-${count.index}"
  ami = var.image_name
  instance_type = var.image_type
  key_name      = "rsa"
  monitoring    = true
  subnet_id = element(module.vpc_hk.public_subnets, count.index)
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
}
## 在 tf中， 执行 Ansible Playbook
resource "null_resource" "ssh_operation" {
  triggers = {
    trigger = join(",", module.ec2_instance_hk[*].public_ip)
  }
  provisioner "local-exec" {
    working_dir = "/Users/yiran/Documents/Learning/Ansible/project_docker_service"
    command = "ansible-playbook -i ${join(",", module.ec2_instance_hk[*].public_ip)} -u ec2-user --private-key /Users/yiran/.ssh/id_rsa docker-service-playbook.yaml"
  }
}

output "instance_public_ip_hk" {
  value = module.ec2_instance_hk[*].public_ip
}

