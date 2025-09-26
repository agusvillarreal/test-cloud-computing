# EC2 Example

This example demonstrates how to create an EC2 instance with a complete setup including VPC, security groups, key pairs, and user data scripts.

## What This Example Creates

- **VPC**: A simple VPC with public subnet and internet gateway
- **EC2 Instance**: Amazon Linux 2 instance with Apache web server
- **Security Group**: Configured for SSH, HTTP, and HTTPS access
- **Key Pair**: For secure SSH access to the instance
- **Elastic IP**: Optional static IP address
- **User Data Script**: Automatically installs and configures Apache

## Architecture

```
Internet Gateway
        |
    Public Subnet (10.0.1.0/24)
        |
    EC2 Instance (t2.micro)
    ├── Apache Web Server
    ├── Security Group (SSH, HTTP, HTTPS)
    └── EBS Volume (encrypted)
```

## Key Concepts Demonstrated

### 1. EC2 Instance Configuration
- Latest Amazon Linux 2 AMI selection using data sources
- Instance type configuration with validation
- User data script for automated setup
- EBS volume configuration with encryption

### 2. Security Configuration
- Security group with specific port rules
- SSH key pair for secure access
- Network ACLs through VPC configuration

### 3. Networking Setup
- VPC with public subnet
- Internet gateway for internet access
- Route table configuration
- Public IP assignment

### 4. User Data Scripts
- Automated software installation
- Service configuration and startup
- Custom web page creation
- Instance metadata utilization

## Files Structure

- `main.tf`: Main configuration with all resources
- `variables.tf`: Input variables with validation
- `outputs.tf`: Output values for instance information
- `user_data.sh`: Bootstrap script for the instance
- `README.md`: This documentation

## Prerequisites

### 1. SSH Key Pair
You need to provide your SSH public key. Generate one if you don't have it:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Display public key
cat ~/.ssh/id_rsa.pub
```

### 2. AWS Configuration
Ensure your AWS CLI is configured with appropriate credentials.

## Usage

### Steps

1. **Navigate to the EC2 example directory**:
   ```bash
   cd examples/ec2
   ```

2. **Create a terraform.tfvars file**:
   ```hcl
   # terraform.tfvars
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-email@example.com"
   instance_type = "t2.micro"
   allocate_eip = true
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

6. **Access your instance**:
   ```bash
   # SSH into the instance
   ssh -i ~/.ssh/id_rsa ec2-user@<public-ip>
   
   # Or visit the web server
   curl http://<public-ip>
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

You can customize the instance by modifying variables:

```hcl
# terraform.tfvars
aws_region = "us-east-1"
project_name = "my-web-server"
environment = "production"
instance_type = "t3.small"
volume_size = 20
volume_type = "gp3"
encrypt_volume = true
enable_monitoring = true
allocate_eip = true
```

## Features

### 1. Automated Setup
The user data script automatically:
- Updates system packages
- Installs Apache web server
- Creates a custom welcome page
- Displays instance metadata
- Configures proper permissions

### 2. Security Best Practices
- Encrypted EBS volumes
- Security groups with minimal required access
- SSH key-based authentication
- Optional Elastic IP for static addressing

### 3. Monitoring and Logging
- Optional detailed monitoring
- User data execution logging
- Instance metadata display

## Important Notes

- **Cost**: This example creates resources that may incur AWS charges
- **Security**: The security group allows SSH from anywhere (0.0.0.0/0) - restrict in production
- **Key Management**: Keep your private key secure and never share it
- **AMI Selection**: Uses the latest Amazon Linux 2 AMI automatically

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   - Verify the public key is correct
   - Check security group allows SSH (port 22)
   - Ensure the instance is running

2. **Web Server Not Accessible**:
   - Check security group allows HTTP (port 80)
   - Verify the user data script completed successfully
   - Check instance logs: `sudo tail -f /var/log/cloud-init-output.log`

3. **Instance Creation Failed**:
   - Check AWS service limits
   - Verify the instance type is available in your region
   - Ensure you have sufficient permissions

### Useful Commands

```bash
# Check instance status
tofu show aws_instance.main

# View user data logs
ssh -i ~/.ssh/id_rsa ec2-user@<public-ip>
sudo tail -f /var/log/cloud-init-output.log

# Test web server
curl -I http://<public-ip>
```

## Next Steps

After creating this EC2 instance, you can:
1. Deploy applications on the instance
2. Set up load balancers for multiple instances
3. Configure auto-scaling groups
4. Integrate with RDS databases
5. Set up monitoring and alerting
