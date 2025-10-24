# AWS ECS and Fargate

## What is Amazon ECS?

Amazon Elastic Container Service (ECS) is a fully managed container orchestration service that makes it easy to deploy, manage, and scale containerized applications using Docker.

## Key Concepts

### 1. Clusters

A cluster is a logical grouping of tasks or services. It acts as a container for your ECS resources.

```bash
# Create a cluster
aws ecs create-cluster --cluster-name my-cluster
```

### 2. Task Definitions

A task definition is a blueprint for your application. It specifies:
- Docker images to use
- CPU and memory requirements
- Networking configuration
- Environment variables
- IAM roles
- Logging configuration

**Example Task Definition (JSON)**:
```json
{
  "family": "web-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "web-container",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "environment": [
        {
          "name": "ENVIRONMENT",
          "value": "production"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/web-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### 3. Tasks

A task is a running instance of a task definition. It's the actual container(s) that are running.

### 4. Services

A service maintains a specified number of task instances and can be integrated with load balancers.

```bash
# Create a service
aws ecs create-service \
  --cluster my-cluster \
  --service-name my-service \
  --task-definition web-app:1 \
  --desired-count 2 \
  --launch-type FARGATE
```

### 5. Container Instance

When using EC2 launch type, a container instance is an EC2 instance running the ECS agent.

## ECS Launch Types

### EC2 Launch Type

You manage the EC2 instances that host your containers.

**Characteristics:**
- More control over infrastructure
- Can use reserved instances for cost savings
- Access to instance storage
- You manage the EC2 instances
- More complex setup
- Pay for instances even if not fully utilized

**When to Use:**
- Need specific instance types or configurations
- Cost optimization with reserved instances
- Require GPU instances
- Need access to instance metadata or storage

### Fargate Launch Type

AWS manages the infrastructure - serverless containers.

**Characteristics:**
- No infrastructure management
- Pay only for resources used
- Automatic scaling
- Simplified operations
- Less control over infrastructure
- Potentially higher cost for always-on workloads
- Limited instance type selection

**When to Use:**
- Want to focus on application, not infrastructure
- Variable or unpredictable workloads
- Rapid deployment needs
- Small to medium sized applications
- Development/testing environments

## Architecture Comparison

### ECS EC2 Architecture
```
┌─────────────────────────────────────────┐
│           ECS Cluster                    │
│                                          │
│  ┌──────────────┐    ┌──────────────┐  │
│  │  EC2 Instance │    │  EC2 Instance │  │
│  │  ┌─────────┐ │    │  ┌─────────┐ │  │
│  │  │Container│ │    │  │Container│ │  │
│  │  └─────────┘ │    │  └─────────┘ │  │
│  │  ┌─────────┐ │    │  ┌─────────┐ │  │
│  │  │Container│ │    │  │Container│ │  │
│  │  └─────────┘ │    │  └─────────┘ │  │
│  └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────┘
         You manage EC2 instances
```

### ECS Fargate Architecture
```
┌─────────────────────────────────────────┐
│           ECS Cluster                    │
│                                          │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │  Task   │  │  Task   │  │  Task   │ │
│  │┌───────┐│  │┌───────┐│  │┌───────┐│ │
│  ││Container│  ││Container│  ││Container││
│  │└───────┘│  │└───────┘│  │└───────┘│ │
│  └─────────┘  └─────────┘  └─────────┘ │
└─────────────────────────────────────────┘
      AWS manages infrastructure
```

## Amazon ECR (Elastic Container Registry)

ECR is AWS's managed Docker container registry, similar to Docker Hub.

### Creating a Repository

```bash
# Create ECR repository
aws ecr create-repository --repository-name my-app

# Get login token and authenticate Docker
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# Tag your image
docker tag my-app:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# Push to ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

### ECR Repository Policies

Control access to your images:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789:root"
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  ]
}
```

## Networking in ECS

### Network Modes

1. **awsvpc** (Recommended for Fargate, required for Fargate)
   - Each task gets its own ENI (Elastic Network Interface)
   - Tasks have their own private IP addresses
   - Best isolation and security

2. **bridge** (Default for EC2)
   - Uses Docker's built-in virtual network
   - Port mapping required

3. **host** (EC2 only)
   - Task uses host's network stack
   - No port mapping needed

4. **none**
   - No external networking

### VPC Configuration

```json
{
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": ["subnet-12345678", "subnet-87654321"],
      "securityGroups": ["sg-12345678"],
      "assignPublicIp": "ENABLED"
    }
  }
}
```

## Load Balancing with ECS

### Application Load Balancer (ALB)

Perfect for HTTP/HTTPS traffic:

```json
{
  "loadBalancers": [
    {
      "targetGroupArn": "arn:aws:elasticloadbalancing:...",
      "containerName": "web-container",
      "containerPort": 80
    }
  ]
}
```

### Network Load Balancer (NLB)

For TCP/UDP traffic or extreme performance:

```json
{
  "loadBalancers": [
    {
      "targetGroupArn": "arn:aws:elasticloadbalancing:...",
      "containerName": "api-container",
      "containerPort": 8080
    }
  ]
}
```

## Auto Scaling

### Service Auto Scaling

Scale based on metrics:

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/my-cluster/my-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10

# Create scaling policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/my-cluster/my-service \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json
```

**scaling-policy.json**:
```json
{
  "TargetValue": 75.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleOutCooldown": 60,
  "ScaleInCooldown": 60
}
```

## IAM Roles for ECS

### Task Execution Role

Allows ECS to pull images and write logs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### Task Role

Allows your application containers to access AWS services:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:123456789:table/my-table"
    }
  ]
}
```

## Logging and Monitoring

### CloudWatch Logs

```json
{
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "/ecs/my-app",
      "awslogs-region": "us-east-1",
      "awslogs-stream-prefix": "ecs",
      "awslogs-create-group": "true"
    }
  }
}
```

### CloudWatch Metrics

ECS provides metrics for:
- CPU utilization
- Memory utilization
- Network traffic
- Task count

```bash
# View metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=my-service Name=ClusterName,Value=my-cluster \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

## Complete Example: Deploying a Web App on Fargate

### Step 1: Create ECR Repository

```bash
aws ecr create-repository --repository-name my-web-app
```

### Step 2: Build and Push Docker Image

```bash
# Build image
docker build -t my-web-app .

# Tag for ECR
docker tag my-web-app:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# Push
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest
```

### Step 3: Create Task Definition

```json
{
  "family": "my-web-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::123456789:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "web",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/my-web-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

### Step 4: Create ECS Cluster

```bash
aws ecs create-cluster --cluster-name production
```

### Step 5: Create Service

```bash
aws ecs create-service \
  --cluster production \
  --service-name my-web-app \
  --task-definition my-web-app:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-12345],securityGroups=[sg-12345],assignPublicIp=ENABLED}"
```

## Deployment Strategies

### Rolling Update (Default)

```json
{
  "deploymentConfiguration": {
    "maximumPercent": 200,
    "minimumHealthyPercent": 100
  }
}
```

### Blue/Green Deployment

Using CodeDeploy with ECS:

```json
{
  "deploymentController": {
    "type": "CODE_DEPLOY"
  }
}
```

### External Deployment Controller

Use your own deployment logic:

```json
{
  "deploymentController": {
    "type": "EXTERNAL"
  }
}
```

## Cost Optimization

### Fargate Pricing

Calculated based on:
- vCPU per hour
- Memory (GB) per hour
- Storage (GB) per hour

### Cost Optimization Tips

1. **Right-size your tasks**: Don't over-provision CPU/memory
2. **Use Spot capacity**: Save up to 70% (Fargate Spot)
3. **Fargate Savings Plans**: Commit to usage for discounts
4. **EC2 for predictable workloads**: Use reserved instances
5. **Auto-scaling**: Scale down during off-peak hours

### Fargate Spot

```json
{
  "capacityProviderStrategy": [
    {
      "capacityProvider": "FARGATE_SPOT",
      "weight": 1,
      "base": 0
    },
    {
      "capacityProvider": "FARGATE",
      "weight": 1,
      "base": 1
    }
  ]
}
```

## Troubleshooting

### Common Issues

1. **Task fails to start**
   - Check CloudWatch logs
   - Verify ECR permissions
   - Check security group rules
   - Verify subnet has internet access (if public image)

2. **Task keeps restarting**
   - Application error (check logs)
   - Health check failures
   - Resource constraints (CPU/memory)

3. **Cannot pull image**
   - Verify ECR permissions
   - Check execution role
   - Verify image exists and tag is correct

### Debugging Commands

```bash
# List tasks
aws ecs list-tasks --cluster my-cluster

# Describe task
aws ecs describe-tasks --cluster my-cluster --tasks <task-id>

# View logs
aws logs tail /ecs/my-app --follow

# Describe service
aws ecs describe-services --cluster my-cluster --services my-service
```

## Best Practices

1. **Use Fargate for simplicity**: Unless you need EC2-specific features
2. **Implement health checks**: Ensure reliable deployments
3. **Use secrets management**: AWS Secrets Manager or Systems Manager Parameter Store
4. **Enable auto-scaling**: Handle variable load automatically
5. **Use multiple availability zones**: For high availability
6. **Implement proper logging**: Use CloudWatch Logs
7. **Tag resources**: For cost tracking and management
8. **Use IAM roles**: Don't hardcode credentials
9. **Implement proper security groups**: Restrict access
10. **Monitor with CloudWatch**: Set up alarms for key metrics

## Security Best Practices

1. **Scan images**: Use ECR image scanning
2. **Use private subnets**: With NAT gateway for outbound access
3. **Implement least privilege**: IAM roles with minimal permissions
4. **Encrypt data**: In transit and at rest
5. **Keep images updated**: Patch vulnerabilities regularly
6. **Use secrets management**: Never store secrets in images
7. **Enable VPC Flow Logs**: Monitor network traffic
8. **Use AWS Security Hub**: Centralized security findings

## Summary

**Amazon ECS** is a powerful container orchestration service that offers two launch types:

- **EC2**: More control, better for predictable workloads
- **Fargate**: Serverless, easier to manage, pay-per-use

**Key Components**:
- Clusters: Logical grouping of resources
- Task Definitions: Blueprint for your application
- Tasks: Running instances of task definitions
- Services: Maintain desired number of tasks

**Next Steps**:
- Learn about CI/CD pipelines
- Practice deploying applications to ECS
- Integrate with GitHub Actions for automated deployments

## Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Fargate Documentation](https://docs.aws.amazon.com/fargate/)
- [Amazon ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [ECS Workshop](https://ecsworkshop.com/)
- [AWS Well-Architected Framework - Containers](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)

