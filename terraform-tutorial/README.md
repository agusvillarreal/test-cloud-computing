# Terraform (OpenTofu) Tutorial

Welcome to this comprehensive tutorial on Infrastructure as Code (IaC) using OpenTofu (formerly Terraform). This tutorial covers the basics of OpenTofu with practical examples for AWS cloud resources.

## Table of Contents

1. [Introduction](#introduction)
2. [Theory and Concepts](#theory-and-concepts)
3. [Prerequisites](#prerequisites)
4. [Examples](#examples)
5. [Getting Started](#getting-started)

## Introduction

OpenTofu is an open-source Infrastructure as Code (IaC) tool that allows you to define and provision cloud infrastructure using declarative configuration files. It's a community-driven fork of Terraform that maintains compatibility with Terraform configurations.

### What is Infrastructure as Code?

Infrastructure as Code (IaC) is the practice of managing and provisioning computing infrastructure through machine-readable definition files, rather than through physical hardware configuration or interactive configuration tools.

### Benefits of OpenTofu

- **Version Control**: Infrastructure configurations are stored in version control
- **Reproducibility**: Consistent infrastructure across environments
- **Automation**: Reduces manual errors and speeds up deployments
- **Documentation**: Infrastructure is self-documenting
- **Collaboration**: Teams can work together on infrastructure changes

## Theory and Concepts

Before diving into examples, it's important to understand the core concepts:

### Core Components

1. **Providers**: Plugins that interact with APIs of cloud providers (AWS, Azure, GCP, etc.)
2. **Resources**: Infrastructure components (EC2 instances, S3 buckets, etc.)
3. **Data Sources**: Read-only information about existing infrastructure
4. **Variables**: Input parameters for your configurations
5. **Outputs**: Values returned after infrastructure creation
6. **Modules**: Reusable components that encapsulate multiple resources

### OpenTofu Workflow

1. **Write**: Create configuration files (.tf files)
2. **Initialize**: Run `tofu init` to download providers
3. **Plan**: Run `tofu plan` to preview changes
4. **Apply**: Run `tofu apply` to create/modify infrastructure
5. **Destroy**: Run `tofu destroy` to remove infrastructure

### State Management

OpenTofu maintains a state file that tracks the current state of your infrastructure. This state file is crucial for:
- Tracking resource dependencies
- Determining what changes need to be made
- Managing resource lifecycle

## Prerequisites

Before starting with the examples, ensure you have:

1. **OpenTofu installed**: Download from [OpenTofu website](https://opentofu.org/)
2. **AWS CLI configured**: With appropriate credentials
3. **AWS Account**: With necessary permissions for the resources you'll create
4. **Text Editor**: For writing configuration files

### Installing OpenTofu

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

### AWS Configuration

```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

## Examples

This tutorial includes individual examples for common AWS resources:

### 1. VPC (Virtual Private Cloud)
- **Location**: `examples/vpc/`
- **Description**: Creates a custom VPC with subnets, internet gateway, and route tables
- **Key Concepts**: Networking basics, CIDR blocks, subnets

### 2. EC2 Instance
- **Location**: `examples/ec2/`
- **Description**: Launches an EC2 instance with security groups
- **Key Concepts**: Compute resources, security groups, key pairs

### 3. S3 Bucket
- **Location**: `examples/s3/`
- **Description**: Creates an S3 bucket with versioning and encryption
- **Key Concepts**: Object storage, bucket policies, versioning

### 4. RDS Database
- **Location**: `examples/rds/`
- **Description**: Sets up an RDS PostgreSQL database instance
- **Key Concepts**: Managed databases, parameter groups, security

## Getting Started

1. **Navigate to an example directory**:
   ```bash
   cd examples/vpc
   ```

2. **Initialize OpenTofu**:
   ```bash
   tofu init
   ```

3. **Review the configuration**:
   ```bash
   tofu plan
   ```

4. **Apply the configuration**:
   ```bash
   tofu apply
   ```

5. **Clean up when done**:
   ```bash
   tofu destroy
   ```

## Important Notes

- **Cost Awareness**: These examples create real AWS resources that may incur costs
- **Region Selection**: All examples use `us-west-2` by default - change as needed
- **Security**: Examples use basic security configurations - enhance for production
- **Naming**: Use unique names to avoid conflicts with existing resources

## Next Steps

After completing these individual examples, consider:

1. **Combining Resources**: Create modules that combine multiple resources
2. **Environment Management**: Use workspaces or separate directories for dev/staging/prod
3. **Remote State**: Store state files in S3 or other remote backends
4. **Advanced Features**: Explore data sources, locals, and complex expressions

## Resources

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

**Happy Infrastructure Building! 🚀**
