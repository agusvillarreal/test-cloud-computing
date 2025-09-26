# Outputs for S3 Configuration

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = aws_s3_bucket.main.website_endpoint
}

output "bucket_website_domain" {
  description = "Website domain of the S3 bucket"
  value       = aws_s3_bucket.main.website_domain
}

output "bucket_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the S3 bucket"
  value       = aws_s3_bucket.main.hosted_zone_id
}

output "bucket_region" {
  description = "AWS region of the S3 bucket"
  value       = aws_s3_bucket.main.region
}

output "versioning_status" {
  description = "Versioning status of the S3 bucket"
  value       = aws_s3_bucket_versioning.main.versioning_configuration[0].status
}

output "encryption_algorithm" {
  description = "Encryption algorithm used for the S3 bucket"
  value       = aws_s3_bucket_server_side_encryption_configuration.main.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
}

output "public_access_block_status" {
  description = "Public access block configuration"
  value = {
    block_public_acls       = aws_s3_bucket_public_access_block.main.block_public_acls
    block_public_policy     = aws_s3_bucket_public_access_block.main.block_public_policy
    ignore_public_acls      = aws_s3_bucket_public_access_block.main.ignore_public_acls
    restrict_public_buckets = aws_s3_bucket_public_access_block.main.restrict_public_buckets
  }
}

output "lifecycle_enabled" {
  description = "Whether lifecycle configuration is enabled"
  value       = var.enable_lifecycle
}

output "bucket_policy_enabled" {
  description = "Whether bucket policy is enabled"
  value       = var.enable_bucket_policy
}

output "iam_user_name" {
  description = "Name of the IAM user (if created)"
  value       = var.create_iam_user ? aws_iam_user.s3_user[0].name : null
}

output "iam_user_arn" {
  description = "ARN of the IAM user (if created)"
  value       = var.create_iam_user ? aws_iam_user.s3_user[0].arn : null
}

output "access_key_id" {
  description = "Access key ID for the IAM user (if created)"
  value       = var.create_iam_user ? aws_iam_access_key.s3_user_key[0].id : null
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret access key for the IAM user (if created)"
  value       = var.create_iam_user ? aws_iam_access_key.s3_user_key[0].secret : null
  sensitive   = true
}

output "sample_files_uploaded" {
  description = "List of sample files uploaded to the bucket"
  value       = keys(var.sample_files)
}

output "bucket_url" {
  description = "URL to access the S3 bucket"
  value       = "https://${aws_s3_bucket.main.bucket_domain_name}"
}
