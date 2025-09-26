# Variables for EC2 Configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "terraform-tutorial"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition = can(regex("^t[0-9]+\\.[a-z]+$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type (e.g., t2.micro, t3.small)."
  }
}

variable "public_key" {
  description = "Public key for EC2 instance access"
  type        = string
  
  validation {
    condition = can(regex("^ssh-rsa", var.public_key))
    error_message = "Public key must be a valid SSH RSA public key."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "volume_type" {
  description = "Type of EBS volume"
  type        = string
  default     = "gp3"
  
  validation {
    condition = contains(["gp2", "gp3", "io1", "io2", "st1", "sc1"], var.volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2, st1, sc1."
  }
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 8
  
  validation {
    condition = var.volume_size >= 8 && var.volume_size <= 1000
    error_message = "Volume size must be between 8 and 1000 GB."
  }
}

variable "encrypt_volume" {
  description = "Whether to encrypt the EBS volume"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for the instance"
  type        = bool
  default     = false
}

variable "allocate_eip" {
  description = "Whether to allocate an Elastic IP for the instance"
  type        = bool
  default     = false
}
