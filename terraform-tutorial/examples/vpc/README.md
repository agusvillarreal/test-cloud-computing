# VPC Example

This example demonstrates how to create a Virtual Private Cloud (VPC) with public and private subnets, internet gateway, route tables, and security groups.

## What This Example Creates

- **VPC**: A custom virtual private cloud with DNS support
- **Internet Gateway**: Allows internet access for public subnets
- **Public Subnets**: Subnets with direct internet access (2 subnets across different AZs)
- **Private Subnets**: Subnets without direct internet access (2 subnets across different AZs)
- **Route Tables**: Separate routing for public and private subnets
- **Security Groups**: Web and database security groups with appropriate rules

## Architecture

```
Internet Gateway
        |
    Public Subnet (10.0.1.0/24) - AZ-a
        |
    Private Subnet (10.0.10.0/24) - AZ-a
    
    Public Subnet (10.0.2.0/24) - AZ-b
        |
    Private Subnet (10.0.20.0/24) - AZ-b
```

## Key Concepts Demonstrated

### 1. VPC Configuration
- Custom CIDR block (10.0.0.0/16)
- DNS hostnames and support enabled
- Proper tagging for resource management

### 2. Subnet Design
- **Public Subnets**: For resources that need internet access (load balancers, NAT gateways)
- **Private Subnets**: For resources that don't need direct internet access (databases, application servers)
- Multi-AZ deployment for high availability

### 3. Networking Components
- **Internet Gateway**: Provides internet access to public subnets
- **Route Tables**: Control traffic routing between subnets and internet
- **Route Table Associations**: Link subnets to their respective route tables

### 4. Security Groups
- **Web Security Group**: Allows HTTP (80), HTTPS (443), and SSH (22) traffic
- **Database Security Group**: Allows PostgreSQL (5432) traffic only from web security group

## Files Structure

- `main.tf`: Main configuration with all resources
- `variables.tf`: Input variables for customization
- `outputs.tf`: Output values for use by other configurations
- `README.md`: This documentation

## Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- OpenTofu installed

### Steps

1. **Navigate to the VPC example directory**:
   ```bash
   cd examples/vpc
   ```

2. **Initialize OpenTofu**:
   ```bash
   tofu init
   ```

3. **Review the plan**:
   ```bash
   tofu plan
   ```

4. **Apply the configuration**:
   ```bash
   tofu apply
   ```

5. **View outputs**:
   ```bash
   tofu output
   ```

6. **Clean up when done**:
   ```bash
   tofu destroy
   ```

### Customization

You can customize the VPC by modifying the variables in `variables.tf` or by creating a `terraform.tfvars` file:

```hcl
# terraform.tfvars
aws_region = "us-east-1"
project_name = "my-project"
environment = "production"
vpc_cidr = "172.16.0.0/16"
public_subnet_cidrs = ["172.16.1.0/24", "172.16.2.0/24"]
private_subnet_cidrs = ["172.16.10.0/24", "172.16.20.0/24"]
```

## Important Notes

- **Cost**: This example creates resources that may incur AWS charges
- **Naming**: Resource names include the project name to avoid conflicts
- **Security**: Security groups are configured for basic web and database access
- **Availability Zones**: Uses available AZs in the specified region

## Next Steps

After creating this VPC, you can:
1. Deploy EC2 instances in the public subnets
2. Set up RDS databases in the private subnets
3. Add NAT gateways for private subnet internet access
4. Create additional security groups as needed

## Troubleshooting

### Common Issues

1. **CIDR Block Conflicts**: Ensure your VPC CIDR doesn't overlap with existing networks
2. **Availability Zone Limits**: Some regions have limited AZs
3. **Resource Limits**: Check AWS service limits for your account

### Useful Commands

```bash
# Show current state
tofu show

# List all resources
tofu state list

# Import existing resources
tofu import aws_vpc.main vpc-xxxxxxxxx
```
