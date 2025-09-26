# OpenTofu Theory and Concepts

This directory contains detailed explanations of OpenTofu concepts and best practices.

## Core Concepts

### 1. Configuration Files

OpenTofu uses `.tf` files written in HashiCorp Configuration Language (HCL). These files are human-readable and declarative.

**Basic Structure:**
```hcl
# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider block
provider "aws" {
  region = "us-west-2"
}

# Resource definition
resource "aws_instance" "example" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
}
```

### 2. Providers

Providers are plugins that OpenTofu uses to interact with APIs of cloud providers, SaaS providers, and other APIs.

**Common Providers:**
- `hashicorp/aws` - Amazon Web Services
- `hashicorp/azure` - Microsoft Azure
- `hashicorp/google` - Google Cloud Platform
- `hashicorp/kubernetes` - Kubernetes

### 3. Resources

Resources are the most important element in OpenTofu. Each resource block describes one or more infrastructure objects.

**Resource Syntax:**
```hcl
resource "resource_type" "resource_name" {
  # Configuration arguments
  argument1 = "value1"
  argument2 = "value2"
}
```

### 4. Data Sources

Data sources allow OpenTofu to fetch information from outside of OpenTofu.

```hcl
data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

### 5. Variables

Variables allow you to customize your configurations without changing the source code.

**Variable Definition:**
```hcl
variable "instance_type" {
  description = "The type of EC2 instance"
  type        = string
  default     = "t2.micro"
}
```

**Variable Usage:**
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = var.instance_type
}
```

### 6. Outputs

Outputs expose information about your infrastructure.

```hcl
output "instance_ip" {
  description = "The public IP of the instance"
  value       = aws_instance.example.public_ip
}
```

### 7. Local Values

Local values assign a name to an expression, allowing you to use it multiple times within a module.

```hcl
locals {
  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## State Management

### What is State?

OpenTofu stores information about your infrastructure in a state file. This state file is used to:

- Map real-world resources to your configuration
- Track metadata about resources
- Determine what changes need to be made

### State File Location

By default, OpenTofu stores state locally in a file named `terraform.tfstate`. For production use, consider remote state backends like:

- **S3**: AWS S3 bucket
- **Azure Storage**: Azure Blob Storage
- **Google Cloud Storage**: GCS bucket
- **Terraform Cloud**: HashiCorp's managed service

### State Commands

```bash
# Show current state
tofu show

# List resources in state
tofu state list

# Move resources in state
tofu state mv aws_instance.old aws_instance.new

# Remove resources from state
tofu state rm aws_instance.example
```

## Best Practices

### 1. File Organization

```
project/
├── main.tf          # Main configuration
├── variables.tf     # Variable definitions
├── outputs.tf       # Output definitions
├── terraform.tfvars # Variable values
└── modules/         # Reusable modules
    └── vpc/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### 2. Naming Conventions

- Use descriptive names for resources
- Use consistent naming patterns
- Include environment in resource names
- Use tags for additional metadata

### 3. Security

- Never commit sensitive data to version control
- Use environment variables for secrets
- Implement least privilege access
- Use IAM roles and policies appropriately

### 4. Version Control

- Always use version control for your configurations
- Use meaningful commit messages
- Tag releases
- Review changes before applying

### 5. Testing

- Use `tofu plan` before applying
- Test in non-production environments first
- Use automated testing tools
- Implement CI/CD pipelines

## Common Patterns

### 1. Conditional Resources

```hcl
resource "aws_instance" "example" {
  count = var.create_instance ? 1 : 0
  
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
}
```

### 2. For Each Loops

```hcl
resource "aws_instance" "example" {
  for_each = var.instance_configs
  
  ami           = each.value.ami
  instance_type = each.value.instance_type
  
  tags = {
    Name = each.key
  }
}
```

### 3. Data Source Dependencies

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "example" {
  count = length(data.aws_availability_zones.available.names)
  
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

## Troubleshooting

### Common Issues

1. **State Lock**: If state is locked, check for running operations
2. **Provider Version Conflicts**: Ensure consistent provider versions
3. **Resource Dependencies**: Use `depends_on` for explicit dependencies
4. **Variable Validation**: Use validation blocks for input validation

### Debugging

```bash
# Enable debug logging
export TF_LOG=DEBUG
tofu apply

# Show detailed plan
tofu plan -detailed-exitcode

# Validate configuration
tofu validate
```

## Next Steps

After understanding these concepts, proceed to the examples directory to see them in practice. Each example builds upon these foundational concepts and demonstrates real-world usage patterns.
