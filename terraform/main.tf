terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

resource "aws_security_group" "novashop_sg" {
  name        = "novashop-preprod-sg"
  description = "NovaShop PREPROD - HTTP et SSH"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (lab uniquement)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project     = "NovaShop"
    Environment = "PREPROD"
  }
}

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.novashop_sg.id]

  tags = {
    Name        = "SRV-WEB-PREPROD-01"
    Environment = "PREPROD"
    Project     = "NovaShop"
  }
}
