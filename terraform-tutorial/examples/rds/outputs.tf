# Outputs for RDS Configuration

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "Master username for the database"
  value       = aws_db_instance.main.username
}

output "db_instance_password" {
  description = "Master password for the database (if not stored in Secrets Manager)"
  value       = var.store_password_in_secrets_manager ? null : aws_db_instance.main.password
  sensitive   = true
}

output "db_instance_engine" {
  description = "Database engine"
  value       = aws_db_instance.main.engine
}

output "db_instance_engine_version" {
  description = "Database engine version"
  value       = aws_db_instance.main.engine_version
}

output "db_instance_class" {
  description = "RDS instance class"
  value       = aws_db_instance.main.instance_class
}

output "db_instance_status" {
  description = "RDS instance status"
  value       = aws_db_instance.main.status
}

output "db_instance_allocated_storage" {
  description = "Allocated storage in GB"
  value       = aws_db_instance.main.allocated_storage
}

output "db_instance_storage_encrypted" {
  description = "Whether storage is encrypted"
  value       = aws_db_instance.main.storage_encrypted
}

output "db_instance_multi_az" {
  description = "Whether Multi-AZ is enabled"
  value       = aws_db_instance.main.multi_az
}

output "db_instance_publicly_accessible" {
  description = "Whether the instance is publicly accessible"
  value       = aws_db_instance.main.publicly_accessible
}

output "db_instance_backup_retention_period" {
  description = "Backup retention period in days"
  value       = aws_db_instance.main.backup_retention_period
}

output "db_instance_backup_window" {
  description = "Backup window"
  value       = aws_db_instance.main.backup_window
}

output "db_instance_maintenance_window" {
  description = "Maintenance window"
  value       = aws_db_instance.main.maintenance_window
}

output "db_instance_performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = aws_db_instance.main.performance_insights_enabled
}

output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.main.arn
}

output "db_parameter_group_id" {
  description = "ID of the DB parameter group"
  value       = aws_db_parameter_group.main.id
}

output "db_parameter_group_arn" {
  description = "ARN of the DB parameter group"
  value       = aws_db_parameter_group.main.arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.rds.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret (if created)"
  value       = var.store_password_in_secrets_manager ? aws_secretsmanager_secret.rds_password[0].arn : null
}

output "connection_string" {
  description = "Database connection string"
  value       = "postgresql://${aws_db_instance.main.username}:<password>@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

output "connection_command" {
  description = "Command to connect to the database"
  value       = "psql -h ${aws_db_instance.main.address} -p ${aws_db_instance.main.port} -U ${aws_db_instance.main.username} -d ${aws_db_instance.main.db_name}"
}
