# Variables for Simple VPC

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "my-simple-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

