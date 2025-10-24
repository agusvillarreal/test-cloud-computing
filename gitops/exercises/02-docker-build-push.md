# Exercise 2: Docker Build and Push to AWS ECR

## Objective
Learn how to automate Docker image building and pushing to Amazon Elastic Container Registry (ECR) using GitHub Actions. This exercise builds on your Docker knowledge and integrates it with CI/CD pipelines.

## Prerequisites
- Completed Exercise 1 (First GitHub Action)
- Completed Docker lectures
- AWS account with appropriate permissions
- AWS CLI installed and configured
- Docker installed locally

## Part 1: AWS ECR Setup

### Task 1: Create ECR Repository

Using AWS CLI:

```bash
# Create ECR repository
aws ecr create-repository \
  --repository-name my-demo-app \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true

# Note the repositoryUri from the output
# Example: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-demo-app
```

Or using AWS Console:
1. Go to Amazon ECR in AWS Console
2. Click "Create repository"
3. Enter repository name: `my-demo-app`
4. Enable "Scan on push"
5. Click "Create repository"

**Save these values**:
- Repository URI: `____________.dkr.ecr.__________.amazonaws.com/my-demo-app`
- AWS Region: `__________`
- AWS Account ID: `____________`

### Task 2: Create IAM User for GitHub Actions

Create a user with ECR push permissions:

```bash
# Create IAM user
aws iam create-user --user-name github-actions-ecr

# Create and attach policy
cat > ecr-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "arn:aws:ecr:us-east-1:*:repository/my-demo-app"
    }
  ]
}
EOF

aws iam put-user-policy \
  --user-name github-actions-ecr \
  --policy-name ECRPushPolicy \
  --policy-document file://ecr-policy.json

# Create access keys
aws iam create-access-key --user-name github-actions-ecr
```

**Save the output**:
- Access Key ID: `______________`
- Secret Access Key: `______________`

**Questions to Answer**:
1. Why do we need separate permissions for `ecr:GetAuthorizationToken`?
2. What is the purpose of image scanning?
3. Why should we create a dedicated IAM user for CI/CD?

## Part 2: Prepare Your Application

### Task 3: Create a Sample Application

Use the application from Exercise 1, or create a new one:

**app.js**:
```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Dockerized App!',
    version: process.env.APP_VERSION || 'unknown',
    environment: process.env.ENVIRONMENT || 'development'
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: process.env.APP_VERSION || 'unknown'
  });
});

if (process.env.NODE_ENV !== 'test') {
  app.listen(port, '0.0.0.0', () => {
    console.log(`Server running on port ${port}`);
  });
}

module.exports = app;
```

**package.json**:
```json
{
  "name": "docker-ecr-demo",
  "version": "1.0.0",
  "description": "Demo app for Docker and ECR",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "test": "jest",
    "dev": "nodemon app.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "jest": "^29.5.0",
    "nodemon": "^2.0.22",
    "supertest": "^6.3.3"
  }
}
```

### Task 4: Create Production-Ready Dockerfile

**Dockerfile**:
```dockerfile
# Build stage
FROM node:16-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Production stage
FROM node:16-alpine

# Set up security best practices
RUN apk add --no-cache curl \
    && addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy application files
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Add build arguments for version tracking
ARG APP_VERSION=unknown
ARG BUILD_DATE=unknown
ENV APP_VERSION=${APP_VERSION}
ENV BUILD_DATE=${BUILD_DATE}

# Add labels
LABEL maintainer="your-email@example.com" \
      version="${APP_VERSION}" \
      description="Demo application for ECR deployment" \
      build-date="${BUILD_DATE}"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start application
CMD ["node", "app.js"]
```

**.dockerignore**:
```
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.env.*
.DS_Store
coverage
*.test.js
jest.config.js
.github
Dockerfile
docker-compose.yml
```

**Questions to Answer**:
1. Why do we use multi-stage builds?
2. What is the purpose of the health check?
3. Why do we run as a non-root user?
4. What are build arguments (ARG) used for?

### Task 5: Test Docker Build Locally

```bash
# Build the image
docker build \
  --build-arg APP_VERSION=1.0.0 \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  -t my-demo-app:latest \
  .

# Run the container
docker run -d -p 3000:3000 --name demo-app my-demo-app:latest

# Test the application
curl http://localhost:3000
curl http://localhost:3000/health

# Check logs
docker logs demo-app

# Inspect the image
docker inspect my-demo-app:latest | grep -A 10 Labels

# Clean up
docker stop demo-app
docker rm demo-app
```

## Part 3: Configure GitHub Secrets

### Task 6: Add AWS Credentials to GitHub

1. Go to your repository on GitHub
2. Navigate to: Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add the following secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `AWS_REGION` | `us-east-1` (or your region) |
| `ECR_REPOSITORY` | `my-demo-app` |

**Questions to Answer**:
1. Why should we never commit AWS credentials to Git?
2. What happens if someone gets access to your AWS credentials?
3. How can you rotate AWS credentials?

## Part 4: Create Docker Build and Push Workflow

### Task 7: Create Basic Docker Workflow

Create `.github/workflows/docker-build.yml`:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}

jobs:
  build-and-push:
    name: Build and Push to ECR
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build, tag, and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build \
            --build-arg APP_VERSION=$IMAGE_TAG \
            --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
            -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
            -t $ECR_REGISTRY/$ECR_REPOSITORY:latest \
            .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
          echo "Image pushed: $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
```

**Questions to Answer**:
1. What does `${{ github.sha }}` represent?
2. Why do we tag images with both SHA and 'latest'?
3. What is the purpose of `steps.login-ecr.outputs.registry`?

### Task 8: Test the Workflow

```bash
# Commit and push
git add .
git commit -m "Add Docker build and push workflow"
git push origin main

# Watch the workflow run on GitHub
```

## Part 5: Improve the Workflow

### Task 9: Add Docker Layer Caching

Update `.github/workflows/docker-build.yml`:

```yaml
name: Build and Push Docker Image (Optimized)

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}

jobs:
  test:
    name: Run Tests
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
      
      - name: Run tests
        run: npm test

  build-and-push:
    name: Build and Push to ECR
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push'
    outputs:
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
          TAG="${{ github.ref_name }}-${SHORT_SHA}-${{ github.run_number }}"
          echo "tag=$TAG" >> $GITHUB_OUTPUT
          echo "short-sha=$SHORT_SHA" >> $GITHUB_OUTPUT
          echo "build-date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> $GITHUB_OUTPUT
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        with:
          context: .
          push: true
          tags: |
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:${{ steps.meta.outputs.tag }}
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:${{ github.ref_name }}-latest
          build-args: |
            APP_VERSION=${{ steps.meta.outputs.tag }}
            BUILD_DATE=${{ steps.meta.outputs.build-date }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Image digest
        run: echo "Image pushed with digest: ${{ steps.build.outputs.digest }}"
      
      - name: Print image information
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        run: |
          echo "Docker image built and pushed successfully!"
          echo "Repository: $ECR_REGISTRY/$ECR_REPOSITORY"
          echo "Tag: ${{ steps.meta.outputs.tag }}"
          echo "Short SHA: ${{ steps.meta.outputs.short-sha }}"
          echo "Build Date: ${{ steps.meta.outputs.build-date }}"
  
  scan-image:
    name: Scan Image for Vulnerabilities
    runs-on: ubuntu-latest
    needs: build-and-push
    
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Check ECR scan results
        run: |
          echo "Waiting for image scan to complete..."
          sleep 30
          
          SCAN_FINDINGS=$(aws ecr describe-image-scan-findings \
            --repository-name ${{ env.ECR_REPOSITORY }} \
            --image-id imageTag=${{ needs.build-and-push.outputs.image-tag }} \
            --query 'imageScanFindings.findingSeverityCounts' \
            --output json)
          
          echo "Scan findings: $SCAN_FINDINGS"
          
          # Check for critical vulnerabilities
          CRITICAL=$(echo $SCAN_FINDINGS | jq -r '.CRITICAL // 0')
          HIGH=$(echo $SCAN_FINDINGS | jq -r '.HIGH // 0')
          
          if [ "$CRITICAL" != "0" ] || [ "$HIGH" != "0" ]; then
            echo "Warning: Found $CRITICAL critical and $HIGH high severity vulnerabilities"
          else
            echo "No critical or high severity vulnerabilities found"
          fi
```

**Questions to Answer**:
1. What is Docker Buildx?
2. How does GitHub Actions caching work for Docker?
3. Why do we scan images for vulnerabilities?
4. What happens if critical vulnerabilities are found?

## Part 6: Multi-Environment Setup

### Task 10: Deploy Different Tags for Different Environments

Create `.github/workflows/multi-env-docker.yml`:

```yaml
name: Multi-Environment Docker Build

on:
  push:
    branches: [ main, develop, 'feature/*' ]

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}

jobs:
  determine-environment:
    name: Determine Environment
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.env.outputs.environment }}
      should-deploy: ${{ steps.env.outputs.should-deploy }}
    
    steps:
      - name: Determine environment
        id: env
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "environment=production" >> $GITHUB_OUTPUT
            echo "should-deploy=true" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
            echo "environment=staging" >> $GITHUB_OUTPUT
            echo "should-deploy=true" >> $GITHUB_OUTPUT
          else
            echo "environment=development" >> $GITHUB_OUTPUT
            echo "should-deploy=false" >> $GITHUB_OUTPUT
          fi

  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: determine-environment
    
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
      
      - name: Generate tags
        id: tags
        env:
          ENVIRONMENT: ${{ needs.determine-environment.outputs.environment }}
        run: |
          SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)
          BRANCH=$(echo ${{ github.ref_name }} | sed 's/\//-/g')
          
          TAGS="$ENVIRONMENT-$SHORT_SHA"
          TAGS="$TAGS,$ENVIRONMENT-latest"
          TAGS="$TAGS,$BRANCH-$SHORT_SHA"
          
          echo "tags=$TAGS" >> $GITHUB_OUTPUT
          echo "short-sha=$SHORT_SHA" >> $GITHUB_OUTPUT
      
      - name: Build and push
        uses: docker/build-push-action@v4
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        with:
          context: .
          push: ${{ needs.determine-environment.outputs.should-deploy }}
          tags: |
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:${{ needs.determine-environment.outputs.environment }}-${{ steps.tags.outputs.short-sha }}
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:${{ needs.determine-environment.outputs.environment }}-latest
          build-args: |
            APP_VERSION=${{ steps.tags.outputs.short-sha }}
            BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
            ENVIRONMENT=${{ needs.determine-environment.outputs.environment }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Summary
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ENVIRONMENT: ${{ needs.determine-environment.outputs.environment }}
        run: |
          echo "### Docker Build Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "- **Environment:** $ENVIRONMENT" >> $GITHUB_STEP_SUMMARY
          echo "- **Repository:** $ECR_REPOSITORY" >> $GITHUB_STEP_SUMMARY
          echo "- **Tags:** ${{ steps.tags.outputs.tags }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Pushed:** ${{ needs.determine-environment.outputs.should-deploy }}" >> $GITHUB_STEP_SUMMARY
```

**Questions to Answer**:
1. How does this workflow determine which environment to use?
2. Why might you want different tags for different environments?
3. What is `$GITHUB_STEP_SUMMARY` used for?

## Challenge Tasks

### Challenge 1: Add Image Size Check

Add a step to fail the build if the image is too large:

```yaml
- name: Check image size
  run: |
    IMAGE_SIZE=$(docker images --format "{{.Size}}" $ECR_REGISTRY/$ECR_REPOSITORY:latest | sed 's/MB//')
    if (( $(echo "$IMAGE_SIZE > 500" | bc -l) )); then
      echo "Image size ($IMAGE_SIZE MB) exceeds limit (500 MB)"
      exit 1
    fi
    echo "Image size OK: $IMAGE_SIZE MB"
```

### Challenge 2: Implement Semantic Versioning

Create a workflow that generates semantic version tags:

```bash
# Use git tags for versioning
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

Update workflow to use version tags:

```yaml
- name: Get version
  id: version
  run: |
    if [[ ${{ github.ref }} == refs/tags/* ]]; then
      VERSION=${GITHUB_REF#refs/tags/}
    else
      VERSION=$(git describe --tags --always --dirty)
    fi
    echo "version=$VERSION" >> $GITHUB_OUTPUT
```

### Challenge 3: Add Trivy Security Scan

Add vulnerability scanning with Trivy:

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}:${{ steps.meta.outputs.tag }}
    format: 'sarif'
    output: 'trivy-results.sarif'

- name: Upload Trivy results to GitHub Security
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results.sarif'
```

## Summary Questions

1. **What is Amazon ECR and why use it over Docker Hub?**
2. **How do you authenticate Docker with ECR?**
3. **What are the benefits of multi-stage Docker builds?**
4. **Why is image tagging strategy important?**
5. **How does Docker layer caching improve build times?**
6. **What security considerations should you have when building images?**

## Best Practices Learned

1. Use multi-stage builds for smaller images
2. Run containers as non-root users
3. Implement proper image tagging strategy
4. Scan images for vulnerabilities
5. Use Docker layer caching
6. Never commit AWS credentials
7. Add health checks to containers
8. Use specific base image versions
9. Minimize image layers
10. Use .dockerignore file

## Verification

Check your ECR repository:

```bash
# List images in ECR
aws ecr list-images \
  --repository-name my-demo-app \
  --region us-east-1

# Describe images
aws ecr describe-images \
  --repository-name my-demo-app \
  --region us-east-1

# Get image details
aws ecr describe-images \
  --repository-name my-demo-app \
  --image-ids imageTag=latest \
  --region us-east-1
```

## Cleanup

When you're done with the exercise:

```bash
# Delete images from ECR
aws ecr batch-delete-image \
  --repository-name my-demo-app \
  --image-ids imageTag=latest

# Delete repository (optional)
aws ecr delete-repository \
  --repository-name my-demo-app \
  --force
```

## Next Steps

- Complete Exercise 3: Deploy to ECS
- Implement automated testing before build
- Set up image retention policies
- Explore AWS ECR lifecycle policies
- Learn about container security best practices

## Resources

- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Actions for AWS](https://github.com/aws-actions)
- [Trivy Security Scanner](https://aquasecurity.github.io/trivy/)

---

**Congratulations!** You've successfully automated Docker image building and pushing to AWS ECR using GitHub Actions!

