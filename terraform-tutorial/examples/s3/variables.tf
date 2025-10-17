# Variables for S3 Configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-1"
}

variable "project_name" {
  description = "uag-cloud-computing"
  type        = string
  default     = "uag-cloud-computing"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "avillarreal-uag-26092025"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = false
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
