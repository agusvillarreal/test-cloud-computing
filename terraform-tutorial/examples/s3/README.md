# S3 Example

This example demonstrates how to create an S3 bucket with comprehensive configuration including versioning, encryption, lifecycle policies, and security settings.

## What This Example Creates

- **S3 Bucket**: A secure, versioned, and encrypted object storage bucket
- **Versioning**: Enables object versioning for data protection
- **Encryption**: Server-side encryption for data at rest
- **Public Access Block**: Prevents accidental public exposure
- **Lifecycle Policies**: Automated data lifecycle management
- **Bucket Policy**: Enforces SSL/TLS for all requests
- **IAM User**: Optional dedicated user for bucket access
- **Sample Files**: Optional file uploads for testing

## Architecture

```
S3 Bucket
├── Versioning (Enabled)
├── Encryption (AES256/KMS)
├── Public Access Block
├── Lifecycle Configuration
│   ├── Transition to IA (30 days)
│   ├── Transition to Glacier (90 days)
│   └── Delete old versions (365 days)
├── Bucket Policy (SSL enforcement)
└── IAM User (optional)
```

## Key Concepts Demonstrated

### 1. S3 Bucket Configuration
- Globally unique bucket naming
- Regional configuration
- Comprehensive tagging strategy

### 2. Security Features
- Server-side encryption (AES256 or KMS)
- Public access blocking
- SSL/TLS enforcement via bucket policy
- IAM-based access control

### 3. Data Management
- Object versioning for data protection
- Lifecycle policies for cost optimization
- Automated cleanup of incomplete uploads

### 4. Monitoring and Notifications
- Optional CloudWatch event notifications
- Configurable event filtering

## Files Structure

- `main.tf`: Main configuration with all S3 resources
- `variables.tf`: Input variables with validation
- `outputs.tf`: Output values for bucket information
- `README.md`: This documentation

## Usage

### Steps

1. **Navigate to the S3 example directory**:
   ```bash
   cd examples/s3
   ```

2. **Create a terraform.tfvars file**:
   ```hcl
   # terraform.tfvars
   bucket_name = "my-unique-bucket-name-12345"
   environment = "dev"
   enable_versioning = true
   encryption_algorithm = "AES256"
   enable_lifecycle = true
   create_iam_user = true
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

6. **Test the bucket**:
   ```bash
   # List bucket contents
   aws s3 ls s3://your-bucket-name
   
   # Upload a test file
   echo "Hello, S3!" > test.txt
   aws s3 cp test.txt s3://your-bucket-name/
   
   # Download the file
   aws s3 cp s3://your-bucket-name/test.txt downloaded.txt
   ```

7. **View outputs**:
   ```bash
   tofu output
   ```

8. **Clean up when done**:
   ```bash
   tofu destroy
   ```

### Customization Options

You can customize the S3 bucket by modifying variables:

```hcl
# terraform.tfvars
aws_region = "us-east-1"
project_name = "my-project"
environment = "production"
bucket_name = "my-production-bucket-2024"
enable_versioning = true
encryption_algorithm = "aws:kms"
bucket_key_enabled = true
enable_lifecycle = true
enable_bucket_policy = true
create_iam_user = true
enable_notifications = true
```

### Sample Files Upload

You can upload sample files during bucket creation:

```hcl
# terraform.tfvars
sample_files = {
  "welcome.txt" = "welcome.txt"
  "config.json" = "config.json"
}
```

Create the files first:
```bash
echo "Welcome to S3!" > welcome.txt
echo '{"version": "1.0", "environment": "dev"}' > config.json
```

## Features

### 1. Security Best Practices
- **Encryption**: Server-side encryption for all objects
- **Access Control**: Public access blocking enabled by default
- **SSL Enforcement**: Bucket policy requires HTTPS
- **IAM Integration**: Dedicated user with minimal permissions

### 2. Cost Optimization
- **Lifecycle Policies**: Automatic transition to cheaper storage classes
- **Version Management**: Automatic cleanup of old versions
- **Multipart Cleanup**: Automatic deletion of incomplete uploads

### 3. Data Protection
- **Versioning**: Keep multiple versions of objects
- **Encryption**: Data encrypted at rest
- **Access Logging**: Optional CloudWatch integration

### 4. Monitoring
- **Event Notifications**: Optional CloudWatch events
- **Filtering**: Configurable event filtering
- **Integration**: Easy integration with other AWS services

## Important Notes

- **Bucket Names**: Must be globally unique across all AWS accounts
- **Cost**: Lifecycle policies help manage costs but monitor usage
- **Security**: Public access is blocked by default for security
- **Region**: Choose the region closest to your users for better performance

## Troubleshooting

### Common Issues

1. **Bucket Name Already Exists**:
   - S3 bucket names must be globally unique
   - Try adding random numbers or your name/company

2. **Access Denied**:
   - Check IAM permissions
   - Verify bucket policy allows your actions
   - Ensure SSL is being used if policy requires it

3. **Versioning Issues**:
   - Once enabled, versioning cannot be disabled, only suspended
   - Consider lifecycle policies to manage version costs

### Useful Commands

```bash
# Check bucket configuration
aws s3api get-bucket-versioning --bucket your-bucket-name
aws s3api get-bucket-encryption --bucket your-bucket-name
aws s3api get-public-access-block --bucket your-bucket-name

# List all versions of an object
aws s3api list-object-versions --bucket your-bucket-name --prefix your-file

# Check bucket policy
aws s3api get-bucket-policy --bucket your-bucket-name
```

## Use Cases

This S3 configuration is suitable for:

1. **Application Data Storage**: Store application files, images, documents
2. **Backup Storage**: Automated backups with lifecycle management
3. **Static Website Hosting**: Host static websites (with additional configuration)
4. **Data Lake**: Store large datasets for analytics
5. **Log Storage**: Centralized logging with automated archival

## Next Steps

After creating this S3 bucket, you can:

1. **Configure Static Website Hosting**: Enable website hosting
2. **Set up CloudFront**: Add CDN for better performance
3. **Integrate with Applications**: Use the bucket in your applications
4. **Set up Monitoring**: Add CloudWatch alarms and dashboards
5. **Implement Backup Strategies**: Use for automated backups
