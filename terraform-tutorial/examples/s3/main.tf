# S3 Example - Basic S3 Bucket Setup
# This example creates an S3 bucket with versioning, encryption, and lifecycle policies

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "terraform-tutorial"
  }
}

# Configure bucket versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Configure bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.encryption_algorithm
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}

# Configure bucket website
resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Configure bucket public access block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Configure bucket lifecycle configuration
# resource "aws_s3_bucket_lifecycle_configuration" "main" {
#   count  = var.enable_lifecycle ? 1 : 0
#   bucket = aws_s3_bucket.main.id
#
#   rule {
#     id     = "lifecycle_rule"
#     status = "Enabled"
#
#     # Transition to IA after 30 days
#     transition {
#       days          = 30
#       storage_class = "STANDARD_IA"
#     }
#
#     # Transition to Glacier after 90 days
#     transition {
#       days          = 90
#       storage_class = "GLACIER"
#     }
#
#     # Delete old versions after 365 days
#     noncurrent_version_transition {
#       noncurrent_days = 30
#       storage_class   = "STANDARD_IA"
#     }
#
#     noncurrent_version_transition {
#       noncurrent_days = 90
#       storage_class   = "GLACIER"
#     }
#
#     noncurrent_version_expiration {
#       noncurrent_days = 365
#     }
#
#     # Delete incomplete multipart uploads after 7 days
#     abort_incomplete_multipart_upload {
#       days_after_initiation = 7
#     }
#   }
# }

# Create bucket policy (optional)
resource "aws_s3_bucket_policy" "main" {
  count  = var.enable_bucket_policy ? 1 : 0
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSSLRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Create IAM user for S3 access (optional)
resource "aws_iam_user" "s3_user" {
  count = var.create_iam_user ? 1 : 0
  name  = "${var.bucket_name}-s3-user"

  tags = {
    Name        = "${var.bucket_name}-s3-user"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create IAM access key for the S3 user
resource "aws_iam_access_key" "s3_user_key" {
  count = var.create_iam_user ? 1 : 0
  user  = aws_iam_user.s3_user[0].name
}

# Create IAM policy for S3 access
resource "aws_iam_policy" "s3_user_policy" {
  count = var.create_iam_user ? 1 : 0
  name  = "${var.bucket_name}-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.bucket_name}-s3-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "s3_user_policy_attachment" {
  count      = var.create_iam_user ? 1 : 0
  user       = aws_iam_user.s3_user[0].name
  policy_arn = aws_iam_policy.s3_user_policy[0].arn
}

# Upload sample files to the bucket
resource "aws_s3_object" "sample_files" {
  for_each = var.sample_files

  bucket = aws_s3_bucket.main.id
  key    = each.key
  source = each.value
  etag   = filemd5(each.value)

  tags = {
    Name        = each.key
    Environment = var.environment
    Project     = var.project_name
  }
}
