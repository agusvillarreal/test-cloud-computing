# Simple EC2 Instance
# This creates a basic EC2 instance using the default VPC

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0b967c22fe917319b"  # Amazon Linux 2 AMI in us-east-1
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "simple-ec2-instance"
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create Security Group for EC2 Instance
resource "aws_security_group" "simple_ec2" {
  name_prefix = "simple-ec2-"
  description = "Security group for simple EC2 instance"

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "simple-ec2-sg"
  }
}

# Create EC2 Instance
resource "aws_instance" "simple" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.simple_ec2.id]

  # User data to install Apache web server
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Simple EC2 Instance!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = var.instance_name
  }
}

# Output the public IP address
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.simple.public_ip
}

# Output the instance ID
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.simple.id
}
