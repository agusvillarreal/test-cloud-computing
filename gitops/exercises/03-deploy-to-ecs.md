# Exercise 3: Complete CI/CD Pipeline - Deploy to AWS ECS

## Objective
Build a complete end-to-end CI/CD pipeline that builds, tests, and deploys a containerized application to AWS ECS/Fargate using GitHub Actions. This exercise combines everything you've learned about Docker, GitHub Actions, and AWS.

## Prerequisites
- Completed Exercise 1 (First GitHub Action)
- Completed Exercise 2 (Docker Build and Push)
- AWS account with appropriate permissions
- Basic understanding of networking (VPC, subnets, security groups)
- Terraform installed (optional, for infrastructure setup)

## Architecture Overview

```
GitHub Repository
       │
       ├──> GitHub Actions (CI/CD)
       │    │
       │    ├──> Run Tests
       │    ├──> Build Docker Image
       │    ├──> Push to ECR
       │    └──> Deploy to ECS
       │
       ▼
Amazon ECR (Container Registry)
       │
       ▼
AWS ECS Cluster (Fargate)
       │
       ├──> Task Definition
       ├──> Service (with Auto Scaling)
       └──> Application Load Balancer
              │
              ▼
         Public Internet
```

## Part 1: AWS Infrastructure Setup

### Task 1: Set Up VPC and Networking

You can use Terraform or AWS Console. Here's the Terraform approach:

**terraform/main.tf**:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
  }
}

# NAT Gateway (for private subnets)
resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}
```

**terraform/variables.tf**:
```hcl
variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  default     = "ecs-demo"
}
```

Apply the infrastructure:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Questions to Answer**:
1. Why do we need both public and private subnets?
2. What is the purpose of a NAT Gateway?
3. Why do tasks need to communicate with the ALB through security groups?

### Task 2: Create ECS Resources with Terraform

**terraform/ecs.tf**:
```hcl
# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.project_name
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = var.project_name
  }
}

# IAM Roles
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-tg"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.app.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "NODE_ENV"
        value = "production"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = {
    Name = var.project_name
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 3000
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.app]

  tags = {
    Name = "${var.project_name}-service"
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.project_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Outputs
output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "task_definition_family" {
  value = aws_ecs_task_definition.app.family
}
```

Apply the ECS infrastructure:

```bash
terraform apply
```

Save the outputs - you'll need them for GitHub Actions!

## Part 2: Prepare Application

### Task 3: Create the Application

Use the same application from previous exercises, or create a new one with additional features:

**app.js**:
```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Metrics tracking
let requestCount = 0;
const startTime = Date.now();

// Root endpoint
app.get('/', (req, res) => {
  requestCount++;
  res.json({
    message: 'Hello from ECS!',
    version: process.env.APP_VERSION || 'unknown',
    environment: process.env.ENVIRONMENT || 'unknown',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || 'unknown'
  });
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
  res.json({
    requests: requestCount,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    cpu: process.cpuUsage(),
    startTime: new Date(startTime).toISOString()
  });
});

// Info endpoint
app.get('/info', (req, res) => {
  res.json({
    version: process.env.APP_VERSION || 'unknown',
    environment: process.env.ENVIRONMENT || 'unknown',
    nodeVersion: process.version,
    platform: process.platform,
    hostname: require('os').hostname()
  });
});

if (process.env.NODE_ENV !== 'test') {
  app.listen(port, '0.0.0.0', () => {
    console.log(`Server running on port ${port}`);
    console.log(`Environment: ${process.env.ENVIRONMENT || 'unknown'}`);
    console.log(`Version: ${process.env.APP_VERSION || 'unknown'}`);
  });
}

module.exports = app;
```

### Task 4: Create Task Definition Template

Create `task-definition.json` in your repository:

```json
{
  "family": "ecs-demo",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecs-demo-ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecs-demo-ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "PLACEHOLDER",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "ENVIRONMENT",
          "value": "production"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/ecs-demo",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

## Part 3: Create Complete CI/CD Pipeline

### Task 5: Create the Full Deployment Workflow

Create `.github/workflows/deploy-ecs-complete.yml`:

```yaml
name: Complete ECS Deployment Pipeline

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: ecs-demo
  ECS_CLUSTER: ecs-demo-cluster
  ECS_SERVICE: ecs-demo-service
  ECS_TASK_DEFINITION: task-definition.json
  CONTAINER_NAME: app

permissions:
  contents: read

jobs:
  # ==========================================================
  # Stage 1: Code Quality and Testing
  # ==========================================================
  
  lint-and-test:
    name: Lint and Test
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '16'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linter
        run: npx eslint . --ext .js || true
      
      - name: Run tests
        run: npm test
      
      - name: Generate coverage report
        run: npm test -- --coverage
        continue-on-error: true

  # ==========================================================
  # Stage 2: Build and Push Docker Image
  # ==========================================================
  
  build-and-push:
    name: Build and Push to ECR
    runs-on: ubuntu-latest
    needs: lint-and-test
    if: github.event_name == 'push'
    outputs:
      image: ${{ steps.build-image.outputs.image }}
      image-tag: ${{ steps.meta.outputs.tag }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Generate image metadata
        id: meta
        run: |
          SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)
          BRANCH=$(echo ${{ github.ref_name }} | sed 's/\//-/g')
          TAG="${BRANCH}-${SHORT_SHA}-${{ github.run_number }}"
          echo "tag=$TAG" >> $GITHUB_OUTPUT
          echo "short-sha=$SHORT_SHA" >> $GITHUB_OUTPUT
          echo "build-date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> $GITHUB_OUTPUT
          echo "branch=$BRANCH" >> $GITHUB_OUTPUT
      
      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ steps.meta.outputs.tag }}
        run: |
          docker build \
            --build-arg APP_VERSION=$IMAGE_TAG \
            --build-arg BUILD_DATE=${{ steps.meta.outputs.build-date }} \
            -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
            -t $ECR_REGISTRY/$ECR_REPOSITORY:${{ steps.meta.outputs.branch }}-latest \
            .
          
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:${{ steps.meta.outputs.branch }}-latest
          
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT
          
          echo "### Docker Image Built" >> $GITHUB_STEP_SUMMARY
          echo "- **Image:** \`$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG\`" >> $GITHUB_STEP_SUMMARY
          echo "- **Size:** $(docker images $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG --format '{{.Size}}')" >> $GITHUB_STEP_SUMMARY
      
      - name: Scan image for vulnerabilities
        run: |
          echo "Waiting for ECR scan to complete..."
          sleep 30
          
          aws ecr describe-image-scan-findings \
            --repository-name $ECR_REPOSITORY \
            --image-id imageTag=${{ steps.meta.outputs.tag }} \
            --query 'imageScanFindings.findingSeverityCounts' || true

  # ==========================================================
  # Stage 3: Deploy to Staging (develop branch)
  # ==========================================================
  
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build-and-push
    if: github.ref == 'refs/heads/develop' && github.event_name == 'push'
    environment:
      name: staging
      url: http://${{ steps.get-alb.outputs.dns }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Fill in the new image ID in the task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: ${{ env.ECS_TASK_DEFINITION }}
          container-name: ${{ env.CONTAINER_NAME }}
          image: ${{ needs.build-and-push.outputs.image }}
          environment-variables: |
            ENVIRONMENT=staging
            APP_VERSION=${{ needs.build-and-push.outputs.image-tag }}
      
      - name: Deploy Amazon ECS task definition
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: staging-service
          cluster: staging-cluster
          wait-for-service-stability: true
          wait-for-minutes: 10
      
      - name: Get ALB DNS
        id: get-alb
        run: |
          DNS=$(aws elbv2 describe-load-balancers \
            --names ecs-demo-staging-alb \
            --query 'LoadBalancers[0].DNSName' \
            --output text)
          echo "dns=$DNS" >> $GITHUB_OUTPUT
      
      - name: Run smoke tests
        run: |
          echo "Running smoke tests against staging..."
          sleep 30
          curl -f http://${{ steps.get-alb.outputs.dns }}/health || exit 1
          curl -f http://${{ steps.get-alb.outputs.dns }}/ || exit 1
          echo "Smoke tests passed!"

  # ==========================================================
  # Stage 4: Deploy to Production (main branch)
  # ==========================================================
  
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build-and-push
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment:
      name: production
      url: http://${{ steps.get-alb.outputs.dns }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Fill in the new image ID in the task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: ${{ env.ECS_TASK_DEFINITION }}
          container-name: ${{ env.CONTAINER_NAME }}
          image: ${{ needs.build-and-push.outputs.image }}
          environment-variables: |
            ENVIRONMENT=production
            APP_VERSION=${{ needs.build-and-push.outputs.image-tag }}
      
      - name: Deploy Amazon ECS task definition
        id: deploy
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true
          wait-for-minutes: 15
      
      - name: Get ALB DNS
        id: get-alb
        run: |
          DNS=$(aws elbv2 describe-load-balancers \
            --names ecs-demo-alb \
            --query 'LoadBalancers[0].DNSName' \
            --output text)
          echo "dns=$DNS" >> $GITHUB_OUTPUT
      
      - name: Run smoke tests
        run: |
          echo "Running smoke tests against production..."
          sleep 30
          curl -f http://${{ steps.get-alb.outputs.dns }}/health || exit 1
          curl -f http://${{ steps.get-alb.outputs.dns }}/ || exit 1
          echo "Smoke tests passed!"
      
      - name: Monitor deployment
        run: |
          echo "Monitoring deployment for 2 minutes..."
          for i in {1..4}; do
            sleep 30
            curl -f http://${{ steps.get-alb.outputs.dns }}/health
          done
          echo "Deployment stable!"
      
      - name: Deployment summary
        run: |
          echo "### Production Deployment Complete" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "- **Version:** \`${{ needs.build-and-push.outputs.image-tag }}\`" >> $GITHUB_STEP_SUMMARY
          echo "- **Image:** \`${{ needs.build-and-push.outputs.image }}\`" >> $GITHUB_STEP_SUMMARY
          echo "- **URL:** http://${{ steps.get-alb.outputs.dns }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Deployed at:** $(date -u)" >> $GITHUB_STEP_SUMMARY

  # ==========================================================
  # Stage 5: Post-Deployment Monitoring
  # ==========================================================
  
  monitor:
    name: Post-Deployment Monitoring
    runs-on: ubuntu-latest
    needs: [build-and-push, deploy-production]
    if: success()
    
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Check ECS service health
        run: |
          SERVICE_STATUS=$(aws ecs describe-services \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE \
            --query 'services[0].status' \
            --output text)
          
          RUNNING_COUNT=$(aws ecs describe-services \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE \
            --query 'services[0].runningCount' \
            --output text)
          
          DESIRED_COUNT=$(aws ecs describe-services \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE \
            --query 'services[0].desiredCount' \
            --output text)
          
          echo "Service Status: $SERVICE_STATUS"
          echo "Running Tasks: $RUNNING_COUNT"
          echo "Desired Tasks: $DESIRED_COUNT"
          
          if [ "$RUNNING_COUNT" -eq "$DESIRED_COUNT" ]; then
            echo "Service is healthy!"
          else
            echo "Warning: Running count doesn't match desired count"
          fi
      
      - name: Check recent deployments
        run: |
          aws ecs describe-services \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE \
            --query 'services[0].events[:5]' \
            --output table
```

**Questions to Answer**:
1. What happens if the smoke tests fail?
2. Why do we wait for service stability?
3. What is the purpose of the monitoring job?
4. How would you implement a rollback strategy?

## Part 4: Advanced Features

### Task 6: Add Blue/Green Deployment

Create `.github/workflows/blue-green-deploy.yml`:

```yaml
name: Blue/Green Deployment

on:
  workflow_dispatch:
    inputs:
      image-tag:
        description: 'Image tag to deploy'
        required: true

jobs:
  blue-green-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Create new task definition
        run: |
          # Implementation for blue/green deployment
          echo "Creating green environment..."
      
      - name: Monitor green environment
        run: |
          echo "Monitoring green environment for 5 minutes..."
          # Add monitoring logic
      
      - name: Switch traffic to green
        run: |
          echo "Switching traffic to green environment..."
          # Update ALB target group
```

### Task 7: Add Rollback Workflow

Create `.github/workflows/rollback.yml`:

```yaml
name: Rollback Deployment

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to rollback to (task definition revision)'
        required: true
        type: string

jobs:
  rollback:
    name: Rollback to Previous Version
    runs-on: ubuntu-latest
    environment:
      name: production
    
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Rollback ECS service
        run: |
          echo "Rolling back to version ${{ inputs.version }}..."
          
          aws ecs update-service \
            --cluster ecs-demo-cluster \
            --service ecs-demo-service \
            --task-definition ecs-demo:${{ inputs.version }} \
            --force-new-deployment
      
      - name: Wait for service stability
        run: |
          aws ecs wait services-stable \
            --cluster ecs-demo-cluster \
            --services ecs-demo-service
      
      - name: Verify rollback
        run: |
          echo "Verifying rollback..."
          # Add verification logic
          echo "Rollback completed successfully!"
```

## Challenge Tasks

### Challenge 1: Implement Canary Deployment

Modify the workflow to deploy to 10% of traffic first, monitor, then roll out to 100%.

### Challenge 2: Add Performance Testing

Add a job that runs performance tests after deployment:

```yaml
performance-test:
  needs: deploy-production
  runs-on: ubuntu-latest
  steps:
    - name: Run load tests
      run: |
        # Use tools like Apache Bench or k6
        echo "Running load tests..."
```

### Challenge 3: Add Slack Notifications

Integrate Slack notifications for deployment events:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Challenge 4: Implement Auto-Rollback

Add logic to automatically rollback if health checks fail after deployment.

## Monitoring and Debugging

### Task 8: View Logs

```bash
# Stream ECS logs
aws logs tail /ecs/ecs-demo --follow

# View specific task logs
aws ecs list-tasks --cluster ecs-demo-cluster --service-name ecs-demo-service
aws ecs describe-tasks --cluster ecs-demo-cluster --tasks TASK_ID
```

### Task 9: Check Service Status

```bash
# Describe service
aws ecs describe-services \
  --cluster ecs-demo-cluster \
  --services ecs-demo-service

# View service events
aws ecs describe-services \
  --cluster ecs-demo-cluster \
  --services ecs-demo-service \
  --query 'services[0].events[:10]' \
  --output table
```

## Summary Questions

1. **What are the stages of a complete CI/CD pipeline?**
2. **How does ECS handle rolling deployments?**
3. **What is the purpose of health checks in ECS?**
4. **How would you implement a rollback strategy?**
5. **What metrics should you monitor after deployment?**
6. **How do you debug failed deployments?**

## Best Practices Learned

1. Always run tests before deployment
2. Use proper image tagging strategy
3. Implement health checks at multiple levels
4. Monitor deployments in real-time
5. Have a rollback plan ready
6. Use deployment circuit breakers
7. Implement gradual rollouts for production
8. Keep task definitions in version control
9. Use proper logging and monitoring
10. Secure secrets and credentials

## Cleanup

When you're done:

```bash
# Delete ECS service
aws ecs update-service \
  --cluster ecs-demo-cluster \
  --service ecs-demo-service \
  --desired-count 0

aws ecs delete-service \
  --cluster ecs-demo-cluster \
  --service ecs-demo-service \
  --force

# Destroy Terraform infrastructure
cd terraform
terraform destroy
```

## Next Steps

- Implement monitoring with CloudWatch Dashboards
- Add automated testing (integration, e2e)
- Set up multiple environments (dev, staging, prod)
- Implement advanced deployment strategies
- Add cost optimization
- Explore ECS Capacity Providers
- Implement disaster recovery procedures

## Resources

- [AWS ECS Deployment Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)
- [GitHub Actions AWS Deployment](https://github.com/aws-actions)
- [ECS Best Practices Guide](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS ECS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)

---

**Congratulations!** You've completed the full CI/CD pipeline from code to production deployment on AWS ECS!

