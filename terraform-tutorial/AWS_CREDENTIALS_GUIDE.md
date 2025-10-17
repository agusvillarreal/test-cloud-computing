# AWS Credentials Configuration Guide

This guide shows you how to configure AWS credentials for Terraform/OpenTofu.

## Quick Setup (5 minutes)

### Step 1: Get Your AWS Access Keys

1. Go to [AWS Console](https://console.aws.amazon.com)
2. Click your username (top right) → **Security credentials**
3. Scroll to **Access keys**
4. Click **Create access key**
5. Select **Command Line Interface (CLI)**
6. Click **Next** → **Create access key**
7. **Download** or copy both keys:
   - Access Key ID (starts with `AKIA...`)
   - Secret Access Key (long random string)
8. ⚠️ Save the secret key now - you can't see it again!

### Step 2: Configure AWS CLI

```bash
# Install AWS CLI (if needed)
# macOS:
brew install awscli

# Linux:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
```

Enter your information:
```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-west-2
Default output format [None]: json
```

### Step 3: Test It

```bash
aws sts get-caller-identity
```

You should see your account info. If it works, you're ready to use Terraform!

---

## Three Methods Explained

### Method 1: AWS CLI Configuration Files (Recommended)

**Best for**: Most users, especially beginners

**Location**: 
- Credentials: `~/.aws/credentials`
- Config: `~/.aws/config`

**Setup**:
```bash
aws configure
```

**Pros**:
- ✅ Easy to set up
- ✅ Works with all AWS tools
- ✅ Terraform auto-detects it
- ✅ Can manage multiple profiles

**Example `~/.aws/credentials`**:
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[dev-account]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
```

**Example `~/.aws/config`**:
```ini
[default]
region = us-west-2
output = json

[profile dev-account]
region = us-east-1
output = json
```

---

### Method 2: Environment Variables

**Best for**: CI/CD pipelines, temporary setups, or scripts

**Setup**:
```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-west-2"
```

**Make permanent** (add to `~/.zshrc` or `~/.bashrc`):
```bash
echo 'export AWS_ACCESS_KEY_ID="your-key"' >> ~/.zshrc
echo 'export AWS_SECRET_ACCESS_KEY="your-secret"' >> ~/.zshrc
echo 'export AWS_DEFAULT_REGION="us-west-2"' >> ~/.zshrc
source ~/.zshrc
```

**Pros**:
- ✅ Quick to set up
- ✅ Good for automation
- ✅ Easy to switch between accounts

**Cons**:
- ❌ Must set for each terminal session
- ❌ Can accidentally expose in shell history

---

### Method 3: Named Profiles

**Best for**: Managing multiple AWS accounts

**Setup multiple accounts**:
```bash
# Default account
aws configure

# Work account
aws configure --profile work

# Personal account  
aws configure --profile personal
```

**Use with Terraform**:

Option A - Environment variable:
```bash
export AWS_PROFILE=work
tofu plan
```

Option B - In `main.tf`:
```hcl
provider "aws" {
  region  = var.region
  profile = "work"  # Add this line
}
```

**List all profiles**:
```bash
aws configure list-profiles
```

**Switch profiles**:
```bash
export AWS_PROFILE=personal
aws s3 ls  # Uses personal account

export AWS_PROFILE=work
aws s3 ls  # Uses work account
```

---

## Common Issues & Solutions

### Issue: "Unable to locate credentials"

**Problem**: Terraform can't find your AWS credentials

**Solutions**:
```bash
# Check if AWS CLI is configured
aws configure list

# Verify credentials work
aws sts get-caller-identity

# If using profiles, set the profile
export AWS_PROFILE=default

# If using env vars, check they're set
echo $AWS_ACCESS_KEY_ID
```

### Issue: "Access Denied" or "UnauthorizedOperation"

**Problem**: Your credentials don't have the right permissions

**Solution**: Your IAM user needs these policies:
- `AmazonVPCFullAccess` (for VPC examples)
- `AmazonEC2FullAccess` (for EC2 examples)
- `AmazonS3FullAccess` (for S3 examples)
- `AmazonRDSFullAccess` (for RDS examples)

Or create a custom policy with only what you need.

### Issue: "The security token included in the request is expired"

**Problem**: Temporary credentials expired

**Solution**:
```bash
# If using AWS SSO
aws sso login --profile your-profile

# If using regular keys, reconfigure
aws configure
```

---

## Security Best Practices

### ✅ DO:
- **Use IAM users** with limited permissions (not root account)
- **Enable MFA** (Multi-Factor Authentication)
- **Rotate keys** every 90 days
- **Use different keys** for different projects
- **Delete unused keys** regularly
- **Use AWS SSO** for organization accounts

### ❌ DON'T:
- **Never** commit credentials to Git
- **Never** share credentials via email/Slack
- **Never** use root account credentials
- **Never** hardcode credentials in code
- **Never** use overly permissive policies (like `*:*`)

---

## Verify Your Setup

Run this checklist before using Terraform:

```bash
# 1. Check AWS CLI is installed
aws --version

# 2. Check credentials are configured
aws configure list

# 3. Verify you can authenticate
aws sts get-caller-identity

# 4. Test access to a service (e.g., S3)
aws s3 ls

# 5. Check your region
aws configure get region
```

If all commands work, you're ready to go! 🎉

---

## Quick Reference Card

```bash
# Configure credentials (interactive)
aws configure

# Configure with a profile name
aws configure --profile myproject

# Set credentials via environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-west-2"

# Use a specific profile
export AWS_PROFILE=myproject

# Test authentication
aws sts get-caller-identity

# View current configuration
aws configure list

# List all profiles
aws configure list-profiles
```

---

## Additional Resources

- [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)

---

**Need Help?**

If you're stuck, check:
1. AWS credentials are in `~/.aws/credentials`
2. AWS config is in `~/.aws/config`
3. Run `aws sts get-caller-identity` to verify
4. Check IAM permissions in AWS Console

