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