# RDS Example - Basic RDS Database Setup
# This example creates an RDS PostgreSQL instance with security groups and parameter groups

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

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC for RDS
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create private subnets for RDS
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
  }
}

# Create DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create security group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = aws_vpc.main.id

  # Allow PostgreSQL access from specified CIDR blocks
  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Allow access from security group (if specified)
  dynamic "ingress" {
    for_each = var.allowed_security_groups
    content {
      description     = "PostgreSQL from security group"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create DB parameter group
resource "aws_db_parameter_group" "main" {
  family = var.parameter_group_family
  name   = "${var.project_name}-db-params"

  # Example parameters for PostgreSQL
  parameter {
    name  = "log_statement"
    value = var.log_statement
  }

  parameter {
    name  = "log_min_duration_statement"
    value = var.log_min_duration_statement
  }

  parameter {
    name  = "shared_preload_libraries"
    value = var.shared_preload_libraries
  }

  tags = {
    Name        = "${var.project_name}-db-params"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create DB option group (for MySQL/MariaDB)
resource "aws_db_option_group" "main" {
  count = var.engine == "mysql" || var.engine == "mariadb" ? 1 : 0

  name                 = "${var.project_name}-db-options"
  option_group_description = "Option group for ${var.project_name}"
  engine_name          = var.engine
  major_engine_version = var.major_engine_version

  tags = {
    Name        = "${var.project_name}-db-options"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create random password for master user
resource "random_password" "master_password" {
  length  = 16
  special = true
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "rds_password" {
  count = var.store_password_in_secrets_manager ? 1 : 0

  name                    = "${var.project_name}-rds-password"
  description             = "Password for RDS instance ${var.project_name}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-rds-password"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  count = var.store_password_in_secrets_manager ? 1 : 0

  secret_id     = aws_secretsmanager_secret.rds_password[0].id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master_password.result
  })
}

# Create RDS instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id           = var.kms_key_id

  # Database configuration
  db_name  = var.database_name
  username = var.master_username
  password = var.store_password_in_secrets_manager ? null : random_password.master_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible
  port                   = var.port

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name    = var.engine == "mysql" || var.engine == "mariadb" ? aws_db_option_group.main[0].name : null

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  copy_tags_to_snapshot  = true

  # Monitoring and logging
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Performance Insights
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Multi-AZ deployment
  multi_az = var.multi_az

  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
    Project     = var.project_name
    Engine      = var.engine
  }
}

# Create IAM role for Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-rds-monitoring-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach policy to monitoring role
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
