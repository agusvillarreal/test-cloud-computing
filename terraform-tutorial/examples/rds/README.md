# RDS Example

This example demonstrates how to create a fully configured RDS PostgreSQL database instance with security groups, parameter groups, monitoring, and backup configurations.

## What This Example Creates

- **RDS Instance**: PostgreSQL database with comprehensive configuration
- **VPC and Subnets**: Private subnets for database isolation
- **Security Groups**: Database access control
- **Parameter Group**: Custom database parameters
- **Subnet Group**: Multi-AZ subnet configuration
- **Secrets Manager**: Secure password storage
- **Enhanced Monitoring**: Optional CloudWatch monitoring
- **Backup Configuration**: Automated backups and snapshots

## Architecture

```
VPC (10.0.0.0/16)
├── Private Subnet 1 (10.0.10.0/24) - AZ-a
│   └── RDS Instance (Primary)
├── Private Subnet 2 (10.0.20.0/24) - AZ-b
│   └── RDS Instance (Standby - if Multi-AZ)
└── Security Group
    └── PostgreSQL (5432) access
```

## Key Concepts Demonstrated

### 1. RDS Instance Configuration
- PostgreSQL engine with custom version
- Configurable instance class and storage
- Encryption at rest and in transit
- Multi-AZ deployment option

### 2. Security Configuration
- Private subnets for network isolation
- Security groups with restricted access
- Secrets Manager for password management
- Encryption using AWS KMS

### 3. Database Management
- Custom parameter groups for optimization
- Automated backup configuration
- Maintenance window scheduling
- Performance Insights integration

### 4. Monitoring and Logging
- Enhanced monitoring with CloudWatch
- CloudWatch logs export
- Performance Insights for query analysis

## Files Structure

- `main.tf`: Main configuration with all RDS resources
- `variables.tf`: Input variables with validation
- `outputs.tf`: Output values for database information
- `README.md`: This documentation

## Prerequisites

### 1. AWS Configuration
Ensure your AWS CLI is configured with appropriate credentials and permissions for:
- RDS instance creation
- VPC and subnet management
- Security group configuration
- Secrets Manager access

### 2. Required Permissions
Your AWS user/role needs permissions for:
- `rds:*`
- `ec2:*` (for VPC, subnets, security groups)
- `secretsmanager:*` (if using Secrets Manager)
- `iam:*` (for monitoring role)

## Usage

### Steps

1. **Navigate to the RDS example directory**:
   ```bash
   cd examples/rds
   ```

2. **Create a terraform.tfvars file**:
   ```hcl
   # terraform.tfvars
   project_name = "my-database"
   environment = "dev"
   engine = "postgres"
   engine_version = "15.4"
   instance_class = "db.t3.micro"
   allocated_storage = 20
   database_name = "myapp"
   master_username = "admin"
   store_password_in_secrets_manager = true
   backup_retention_period = 7
   monitoring_interval = 60
   performance_insights_enabled = true
   ```

3. **Initialize OpenTofu**:
   ```bash
   tofu init
   ```

4. **Review the plan**:
   ```bash
   tofu plan
   ```

5. **Apply the configuration**:
   ```bash
   tofu apply
   ```

6. **Get the database password**:
   ```bash
   # If using Secrets Manager
   aws secretsmanager get-secret-value --secret-id my-database-rds-password --query SecretString --output text | jq -r .password
   
   # Or get from outputs
   tofu output db_instance_password
   ```

7. **Test the connection**:
   ```bash
   # Install PostgreSQL client
   # macOS: brew install postgresql
   # Ubuntu: sudo apt-get install postgresql-client
   
   # Connect to database
   psql -h <endpoint> -p 5432 -U admin -d myapp
   ```

8. **View outputs**:
   ```bash
   tofu output
   ```

9. **Clean up when done**:
   ```bash
   tofu destroy
   ```

### Customization Options

You can customize the RDS instance by modifying variables:

```hcl
# terraform.tfvars
aws_region = "us-east-1"
project_name = "production-db"
environment = "production"
engine = "postgres"
engine_version = "15.4"
instance_class = "db.r6g.large"
allocated_storage = 100
max_allocated_storage = 1000
storage_type = "gp3"
storage_encrypted = true
database_name = "production_db"
master_username = "dbadmin"
store_password_in_secrets_manager = true
backup_retention_period = 30
monitoring_interval = 60
performance_insights_enabled = true
deletion_protection = true
multi_az = true
```

## Features

### 1. Security Best Practices
- **Network Isolation**: Database in private subnets
- **Access Control**: Security groups with minimal access
- **Encryption**: Storage and connection encryption
- **Password Management**: Secure storage in Secrets Manager

### 2. High Availability
- **Multi-AZ**: Optional synchronous replication
- **Automated Backups**: Point-in-time recovery
- **Maintenance Windows**: Scheduled maintenance
- **Failover**: Automatic failover in Multi-AZ

### 3. Performance Optimization
- **Parameter Groups**: Custom database settings
- **Performance Insights**: Query performance analysis
- **Enhanced Monitoring**: Detailed metrics
- **Storage Autoscaling**: Automatic storage scaling

### 4. Monitoring and Logging
- **CloudWatch Integration**: Metrics and logs
- **Performance Insights**: Query analysis
- **Enhanced Monitoring**: OS-level metrics
- **Log Exports**: Database logs to CloudWatch

## Important Notes

- **Cost**: RDS instances incur charges - monitor usage
- **Security**: Database is in private subnets by default
- **Backups**: Automated backups are enabled
- **Encryption**: Storage encryption is enabled by default
- **Passwords**: Use Secrets Manager for production

## Troubleshooting

### Common Issues

1. **Connection Timeout**:
   - Check security group allows access from your IP
   - Verify the instance is in a public subnet if accessing externally
   - Ensure the instance is running and available

2. **Authentication Failed**:
   - Verify the username and password
   - Check if password is stored in Secrets Manager
   - Ensure the database name is correct

3. **Instance Creation Failed**:
   - Check AWS service limits
   - Verify the instance class is available in your region
   - Ensure you have sufficient permissions

### Useful Commands

```bash
# Check instance status
aws rds describe-db-instances --db-instance-identifier my-database-db

# Get connection information
tofu output db_instance_endpoint
tofu output connection_command

# Check security groups
aws ec2 describe-security-groups --group-ids <security-group-id>

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/rds
```

## Database Operations

### Connecting to the Database

```bash
# Using psql
psql -h <endpoint> -p 5432 -U admin -d myapp

# Using connection string
postgresql://admin:<password>@<endpoint>:5432/myapp
```

### Common SQL Operations

```sql
-- Create a table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert data
INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');

-- Query data
SELECT * FROM users;

-- Create an index
CREATE INDEX idx_users_email ON users(email);
```

## Next Steps

After creating this RDS instance, you can:

1. **Connect Applications**: Use the connection string in your applications
2. **Set up Monitoring**: Configure CloudWatch alarms
3. **Implement Backup Strategy**: Set up automated snapshots
4. **Scale the Database**: Modify instance class or enable read replicas
5. **Set up Read Replicas**: For read-heavy workloads
6. **Implement Connection Pooling**: Use RDS Proxy for better connection management
