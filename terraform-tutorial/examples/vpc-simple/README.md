# Simple VPC Example

This is the **simplest possible VPC setup** to get you started with Terraform/OpenTofu and AWS networking.

## What This Creates

This example creates just 4 resources:
1. **VPC** - Your virtual network (10.0.0.0/16)
2. **Internet Gateway** - Allows internet access
3. **Public Subnet** - One subnet (10.0.1.0/24) where you can launch resources
4. **Route Table** - Routes internet traffic through the gateway

## Files

- `main.tf` - All the resources (VPC, subnet, gateway, route table)
- `variables.tf` - Configurable parameters
- `outputs.tf` - Information displayed after creation
- `README.md` - This file

## Prerequisites - AWS Credentials Setup

Before running Terraform, you need to configure your AWS credentials. Here are three methods:

### Method 1: AWS CLI Configuration (Recommended for Beginners)

1. **Install AWS CLI** (if not already installed):
   ```bash
   # macOS
   brew install awscli
   
   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

2. **Configure your credentials**:
   ```bash
   aws configure
   ```
   
   You'll be prompted for:
   ```
   AWS Access Key ID: [Your access key]
   AWS Secret Access Key: [Your secret key]
   Default region name: us-west-2
   Default output format: json
   ```

3. **Verify it works**:
   ```bash
   aws sts get-caller-identity
   ```

This creates credentials in `~/.aws/credentials` and `~/.aws/config` that Terraform/OpenTofu will automatically use.

### Method 2: Environment Variables

Set these in your terminal:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

To make them permanent, add to your `~/.zshrc` or `~/.bashrc`:

```bash
echo 'export AWS_ACCESS_KEY_ID="your-access-key"' >> ~/.zshrc
echo 'export AWS_SECRET_ACCESS_KEY="your-secret-key"' >> ~/.zshrc
echo 'export AWS_DEFAULT_REGION="us-west-2"' >> ~/.zshrc
source ~/.zshrc
```

### Method 3: Using AWS Profiles (For Multiple AWS Accounts)

If you manage multiple AWS accounts, use named profiles:

1. **Configure a profile**:
   ```bash
   aws configure --profile myproject
   ```

2. **Use the profile with Terraform**:
   ```bash
   export AWS_PROFILE=myproject
   tofu plan
   ```

   Or specify in the provider block in `main.tf`:
   ```hcl
   provider "aws" {
     region  = var.region
     profile = "myproject"
   }
   ```

### Getting AWS Access Keys

If you don't have access keys yet:

1. Log in to AWS Console: https://console.aws.amazon.com
2. Click your username (top right) → **Security credentials**
3. Scroll to **Access keys** section
4. Click **Create access key**
5. Choose **Command Line Interface (CLI)**
6. Download or copy the keys
7. ⚠️ **Important**: Save your secret key now - you can't view it again!

### Security Best Practices

- ✅ **Never** commit credentials to Git
- ✅ Use IAM users with limited permissions (not root account)
- ✅ Enable MFA (Multi-Factor Authentication)
- ✅ Rotate access keys regularly
- ✅ Use AWS Organizations for production environments

## Quick Start

### 1. Initialize Terraform
```bash
cd terraform-tutorial/examples/vpc-simple
tofu init
```

### 2. See what will be created
```bash
tofu plan
```

### 3. Create the VPC
```bash
tofu apply
```
Type `yes` when prompted.

### 4. View the results
```bash
tofu output
```

You'll see the VPC ID, subnet ID, and other information.

### 5. Delete everything when done
```bash
tofu destroy
```
Type `yes` when prompted.

## Customize It

Create a file called `terraform.tfvars` to override the defaults:

```hcl
region      = "us-east-1"
vpc_name    = "my-test-vpc"
vpc_cidr    = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"
```

## What Can You Do With This VPC?

After creating this VPC, you can:
- Launch EC2 instances in the public subnet
- They'll automatically get public IPs
- They'll have internet access
- Perfect for testing and learning!

## Understanding the Components

### VPC (Virtual Private Cloud)
Think of it as your own private network in AWS. The CIDR block `10.0.0.0/16` gives you 65,536 IP addresses to use.

### Subnet
A smaller network inside your VPC. The `10.0.1.0/24` gives you 256 IP addresses.

### Internet Gateway
Like a door to the internet. Without it, your VPC is completely isolated.

### Route Table
Tells traffic where to go. Our route says "send all internet traffic (0.0.0.0/0) to the internet gateway".

## Cost

⚠️ **Important**: A VPC, subnet, and route table are FREE. The Internet Gateway is also FREE. However, any resources you launch inside this VPC (like EC2 instances) will cost money.

## Next Steps

Once you're comfortable with this simple VPC, check out:
- The full VPC example in `../vpc/` for multi-subnet setups
- The EC2 example to launch servers in your VPC
- Add a security group to control traffic

## Troubleshooting

**"No credentials found"**: Make sure AWS CLI is configured (`aws configure`)

**"Region not available"**: Change the region in `variables.tf` or your tfvars file

**"Already exists"**: You might have created this before. Run `tofu destroy` first.

