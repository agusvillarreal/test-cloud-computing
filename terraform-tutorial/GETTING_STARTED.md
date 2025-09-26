# Getting Started with OpenTofu

This guide will help you get started with the OpenTofu examples in this tutorial.

## Quick Start

### 1. Prerequisites

Before running any examples, ensure you have:

- **OpenTofu installed** (version 1.6+)
- **AWS CLI configured** with appropriate credentials
- **SSH key pair** (for EC2 example)
- **Basic understanding** of AWS services

### 2. Installation

#### Install OpenTofu

```bash
# macOS (using Homebrew)
brew install opentofu

# Linux
wget https://github.com/opentofu/opentofu/releases/latest/download/tofu_linux_amd64.zip
unzip tofu_linux_amd64.zip
sudo mv tofu /usr/local/bin/

# Verify installation
tofu version
```

#### Configure AWS CLI

```bash
# Configure AWS CLI
aws configure

# Test configuration
aws sts get-caller-identity
```

### 3. Running Your First Example

Let's start with the S3 example as it's the simplest:

```bash
# Navigate to S3 example
cd examples/s3

# Create terraform.tfvars
cat > terraform.tfvars << EOF
bucket_name = "my-unique-bucket-name-$(date +%s)"
environment = "dev"
EOF

# Initialize OpenTofu
tofu init

# Review the plan
tofu plan

# Apply the configuration
tofu apply

# View the results
tofu output
```

### 4. Example Progression

We recommend running the examples in this order:

1. **S3 Example** - Object storage (simplest)
2. **VPC Example** - Networking foundation
3. **EC2 Example** - Compute resources
4. **RDS Example** - Database (most complex)

## Common Commands

### OpenTofu Commands

```bash
# Initialize a directory
tofu init

# Plan changes
tofu plan

# Apply changes
tofu apply

# Show current state
tofu show

# List resources
tofu state list

# View outputs
tofu output

# Destroy resources
tofu destroy

# Validate configuration
tofu validate

# Format configuration files
tofu fmt
```

### AWS CLI Commands

```bash
# List S3 buckets
aws s3 ls

# List EC2 instances
aws ec2 describe-instances

# List RDS instances
aws rds describe-db-instances

# List VPCs
aws ec2 describe-vpcs
```

## Best Practices

### 1. Always Use Variables

Create `terraform.tfvars` files for each example:

```hcl
# terraform.tfvars
project_name = "my-project"
environment = "dev"
aws_region = "us-west-2"
```

### 2. Review Before Applying

Always run `tofu plan` before `tofu apply`:

```bash
tofu plan -out=tfplan
tofu apply tfplan
```

### 3. Use Meaningful Names

Customize resource names to avoid conflicts:

```hcl
bucket_name = "my-company-dev-bucket-2024"
project_name = "my-company-project"
```

### 4. Clean Up Resources

Always destroy resources when done to avoid charges:

```bash
tofu destroy
```

## Troubleshooting

### Common Issues

1. **Provider Version Conflicts**
   ```bash
   # Clear provider cache
   rm -rf .terraform
   tofu init
   ```

2. **State Lock Issues**
   ```bash
   # Force unlock (use with caution)
   tofu force-unlock <lock-id>
   ```

3. **Resource Already Exists**
   ```bash
   # Import existing resource
   tofu import aws_s3_bucket.main existing-bucket-name
   ```

4. **Permission Denied**
   - Check AWS credentials: `aws sts get-caller-identity`
   - Verify IAM permissions
   - Check resource policies

### Getting Help

- **OpenTofu Documentation**: https://opentofu.org/docs/
- **AWS Provider Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Community Forums**: https://discuss.hashicorp.com/c/terraform-core

## Next Steps

After completing all examples:

1. **Combine Resources**: Create modules that use multiple resources
2. **Environment Management**: Set up dev/staging/prod environments
3. **Remote State**: Store state in S3 or Terraform Cloud
4. **CI/CD Integration**: Automate deployments with GitHub Actions
5. **Advanced Features**: Explore data sources, locals, and complex expressions

## Cost Management

### Monitoring Costs

- Use AWS Cost Explorer to monitor spending
- Set up billing alerts
- Review costs regularly

### Cost Optimization

- Use appropriate instance sizes
- Enable lifecycle policies for S3
- Use spot instances for non-critical workloads
- Clean up resources when not needed

### Free Tier Usage

Many examples use AWS Free Tier eligible resources:
- EC2 t2.micro instances
- S3 storage (5GB)
- RDS db.t2.micro instances
- VPC and networking (free)

## Security Considerations

### Best Practices

1. **Never commit secrets** to version control
2. **Use IAM roles** instead of access keys when possible
3. **Enable encryption** for all storage
4. **Use private subnets** for databases
5. **Implement least privilege** access

### Security Checklist

- [ ] AWS credentials are properly configured
- [ ] Resources use appropriate security groups
- [ ] Encryption is enabled where possible
- [ ] Public access is restricted
- [ ] IAM policies follow least privilege

## Support

If you encounter issues:

1. Check the example-specific README files
2. Review the OpenTofu documentation
3. Check AWS service status
4. Verify your AWS permissions
5. Ask for help in the community forums

Happy Infrastructure Building! 🚀
