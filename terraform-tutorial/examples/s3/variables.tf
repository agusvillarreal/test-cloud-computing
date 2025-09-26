# Variables for S3 Configuration

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

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
  
  validation {
    condition = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be 3-63 characters long, contain only lowercase letters, numbers, and hyphens, and start/end with alphanumeric characters."
  }
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "encryption_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "AES256"
  
  validation {
    condition = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be either AES256 or aws:kms."
  }
}

variable "bucket_key_enabled" {
  description = "Enable bucket key for S3 Bucket Keys with SSE-KMS"
  type        = bool
  default     = false
}

variable "block_public_acls" {
  description = "Block public ACLs for the bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs for the bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Enable lifecycle configuration for the bucket"
  type        = bool
  default     = true
}

variable "enable_bucket_policy" {
  description = "Enable bucket policy to enforce SSL"
  type        = bool
  default     = true
}

variable "enable_notifications" {
  description = "Enable bucket notifications"
  type        = bool
  default     = false
}

variable "notification_filter_prefix" {
  description = "Filter prefix for bucket notifications"
  type        = string
  default     = ""
}

variable "notification_filter_suffix" {
  description = "Filter suffix for bucket notifications"
  type        = string
  default     = ""
}

variable "create_iam_user" {
  description = "Create IAM user for S3 access"
  type        = bool
  default     = false
}

variable "sample_files" {
  description = "Map of sample files to upload to the bucket"
  type        = map(string)
  default     = {}
}
