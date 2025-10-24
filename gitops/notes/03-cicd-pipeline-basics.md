# CI/CD Pipeline Basics

## What is CI/CD?

CI/CD stands for Continuous Integration and Continuous Delivery/Deployment. It's a method to frequently deliver apps to customers by introducing automation into the stages of app development.

### Continuous Integration (CI)

Developers regularly merge their code changes into a central repository, after which automated builds and tests are run.

**Goals:**
- Find and fix bugs faster
- Improve software quality
- Reduce time to validate and release new updates

### Continuous Delivery (CD)

An extension of CI that automatically delivers code changes to a testing or staging environment after the build stage.

**Goals:**
- Ensure code is always in a deployable state
- Automate release process
- Enable frequent releases

### Continuous Deployment (CD)

Takes continuous delivery one step further by automatically deploying every change that passes all tests to production.

**Goals:**
- Eliminate manual deployment
- Fastest time to market
- Immediate customer feedback

## CI/CD Pipeline Stages

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Source    │────▶│    Build    │────▶│    Test     │────▶│   Deploy    │────▶│   Monitor   │
│  (Commit)   │     │  (Compile)  │     │  (Quality)  │     │(Production) │     │  (Observe)  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### 1. Source Stage

**Trigger**: Code commit or pull request

**Activities**:
- Code checkout
- Version control
- Branch strategy
- Code review

**Example (GitHub Actions)**:
```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  source:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
```

### 2. Build Stage

**Activities**:
- Compile code
- Package application
- Build Docker images
- Create artifacts

**Example**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '16'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build application
        run: npm run build
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: build-artifact
          path: dist/
```

### 3. Test Stage

**Types of Testing**:
- Unit tests
- Integration tests
- End-to-end tests
- Security scans
- Code quality checks

**Example**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests
        run: npm test
      
      - name: Run integration tests
        run: npm run test:integration
      
      - name: Code coverage
        run: npm run coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### 4. Deploy Stage

**Deployment Strategies**:
- Rolling deployment
- Blue/green deployment
- Canary deployment
- Feature flags

**Example**:
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    needs: [build, test]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Download artifact
        uses: actions/download-artifact@v3
        with:
          name: build-artifact
      
      - name: Deploy to production
        run: |
          echo "Deploying to production..."
          # Deployment commands here
```

### 5. Monitor Stage

**Activities**:
- Application monitoring
- Log aggregation
- Performance metrics
- Error tracking
- User analytics

## CI/CD Best Practices

### 1. Version Control Everything

```bash
# Store in version control:
- Application code
- Infrastructure as Code (Terraform, CloudFormation)
- Configuration files
- CI/CD pipeline definitions
- Documentation
```

### 2. Automate Everything

```yaml
# Automate:
- Building
- Testing
- Deployment
- Infrastructure provisioning
- Rollbacks
```

### 3. Build Once, Deploy Many

```yaml
# Build artifact once and deploy to multiple environments
build:
  steps:
    - name: Build Docker image
      run: docker build -t myapp:${{ github.sha }} .
    
    - name: Push to registry
      run: docker push myapp:${{ github.sha }}

deploy-staging:
  needs: build
  steps:
    - name: Deploy to staging
      run: deploy myapp:${{ github.sha }} staging

deploy-production:
  needs: build
  steps:
    - name: Deploy to production
      run: deploy myapp:${{ github.sha }} production
```

### 4. Test Early and Often

```yaml
# Test at multiple stages
jobs:
  lint:
    steps:
      - name: Lint code
        run: npm run lint
  
  unit-test:
    steps:
      - name: Unit tests
        run: npm test
  
  integration-test:
    steps:
      - name: Integration tests
        run: npm run test:integration
  
  e2e-test:
    steps:
      - name: E2E tests
        run: npm run test:e2e
```

### 5. Keep Pipelines Fast

```yaml
# Parallelize independent jobs
jobs:
  lint:
    runs-on: ubuntu-latest
    # ...
  
  test:
    runs-on: ubuntu-latest
    # Runs in parallel with lint
  
  security-scan:
    runs-on: ubuntu-latest
    # Runs in parallel with lint and test
```

### 6. Use Environment-Specific Configurations

```yaml
jobs:
  deploy:
    strategy:
      matrix:
        environment: [dev, staging, production]
    steps:
      - name: Deploy to ${{ matrix.environment }}
        env:
          API_URL: ${{ secrets[format('{0}_API_URL', matrix.environment)] }}
          DATABASE_URL: ${{ secrets[format('{0}_DB_URL', matrix.environment)] }}
        run: deploy.sh
```

### 7. Implement Proper Logging

```yaml
steps:
  - name: Deploy with logging
    run: |
      echo "Starting deployment at $(date)"
      echo "Deploying version: ${{ github.sha }}"
      deploy.sh 2>&1 | tee deployment.log
      echo "Deployment completed at $(date)"
```

### 8. Secure Your Pipeline

```yaml
# Use secrets for sensitive data
steps:
  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v2
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: us-east-1
```

## Branching Strategies

### Git Flow

```
main (production)
  ↑
develop
  ↑
feature branches
```

**Pipeline Example**:
```yaml
on:
  push:
    branches:
      - main        # Deploy to production
      - develop     # Deploy to staging
      - 'feature/*' # Run tests only
```

### Trunk-Based Development

```
main (always deployable)
  ↑
short-lived feature branches
```

**Pipeline Example**:
```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    if: github.event_name == 'pull_request'
    # Run tests on PRs
  
  deploy:
    if: github.ref == 'refs/heads/main'
    # Deploy on merge to main
```

### GitHub Flow

```
main (production)
  ↑
feature branches → Pull Request → main
```

**Pipeline Example**:
```yaml
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize]
  push:
    branches: [main]

jobs:
  ci:
    if: github.event_name == 'pull_request'
    steps:
      - name: Run tests
        run: npm test
  
  cd:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - name: Deploy
        run: deploy.sh
```

## Deployment Strategies

### 1. Rolling Deployment

Gradually replace old versions with new ones.

```yaml
deploy:
  steps:
    - name: Rolling deployment
      run: |
        for instance in $(get_instances); do
          deploy_to_instance $instance
          wait_for_healthy $instance
        done
```

**Pros**: Simple, no additional infrastructure
**Cons**: Slow, mixed versions during deployment

### 2. Blue/Green Deployment

Run two identical production environments, switch traffic when ready.

```yaml
deploy:
  steps:
    - name: Deploy to green environment
      run: deploy_to_green.sh
    
    - name: Run smoke tests
      run: test_green_environment.sh
    
    - name: Switch traffic to green
      run: switch_traffic.sh
    
    - name: Keep blue as backup
      run: maintain_blue_backup.sh
```

**Pros**: Zero downtime, easy rollback
**Cons**: Requires double infrastructure

### 3. Canary Deployment

Deploy to a small subset of users first.

```yaml
deploy:
  steps:
    - name: Deploy canary (10%)
      run: deploy_canary.sh --percentage 10
    
    - name: Monitor metrics
      run: monitor_metrics.sh --duration 30m
    
    - name: Deploy to 50%
      run: deploy_canary.sh --percentage 50
    
    - name: Monitor metrics
      run: monitor_metrics.sh --duration 30m
    
    - name: Deploy to 100%
      run: deploy_full.sh
```

**Pros**: Risk mitigation, gradual rollout
**Cons**: Complex, requires monitoring

### 4. Feature Flags

Deploy code but control feature visibility.

```yaml
deploy:
  steps:
    - name: Deploy with feature flags
      env:
        NEW_FEATURE_ENABLED: false
      run: deploy.sh
    
    - name: Enable for beta users
      run: |
        feature-flag set new-feature \
          --enabled true \
          --percentage 10 \
          --users beta-users
```

**Pros**: Decouple deployment from release, easy A/B testing
**Cons**: Code complexity, technical debt

## Complete CI/CD Pipeline Example

### Full Pipeline with Docker and AWS

```yaml
name: Complete CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: my-app
  ECS_CLUSTER: production
  ECS_SERVICE: my-app-service
  CONTAINER_NAME: web

jobs:
  # ============================================================
  # CI STAGE: Build and Test
  # ============================================================
  
  code-quality:
    name: Code Quality Checks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '16'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint
        run: npm run lint
      
      - name: Format check
        run: npm run format:check
  
  security-scan:
    name: Security Scanning
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
  
  unit-test:
    name: Unit Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '16'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test -- --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
  
  build-image:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [code-quality, security-scan, unit-test]
    outputs:
      image-tag: ${{ steps.vars.outputs.tag }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Set variables
        id: vars
        run: |
          echo "tag=${{ github.sha }}" >> $GITHUB_OUTPUT
      
      - name: Build Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: false
          tags: ${{ env.ECR_REPOSITORY }}:${{ steps.vars.outputs.tag }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
  
  integration-test:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: build-image
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v3
      
      - name: Run integration tests
        env:
          DATABASE_URL: postgresql://postgres:postgres@postgres:5432/test
        run: npm run test:integration
  
  # ============================================================
  # CD STAGE: Deploy
  # ============================================================
  
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: [build-image, integration-test]
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.myapp.com
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ needs.build-image.outputs.image-tag }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
      
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster staging-cluster \
            --service my-app-staging \
            --force-new-deployment
      
      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster staging-cluster \
            --services my-app-staging
      
      - name: Run smoke tests
        run: npm run test:smoke -- --url https://staging.myapp.com
  
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: [build-image, integration-test]
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://myapp.com
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ needs.build-image.outputs.image-tag }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
                    $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
      
      - name: Download task definition
        run: |
          aws ecs describe-task-definition \
            --task-definition my-app \
            --query taskDefinition > task-definition.json
      
      - name: Update task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-definition.json
          container-name: ${{ env.CONTAINER_NAME }}
          image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ needs.build-image.outputs.image-tag }}
      
      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true
      
      - name: Run smoke tests
        run: npm run test:smoke -- --url https://myapp.com
      
      - name: Notify deployment
        if: always()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
            -H 'Content-Type: application/json' \
            -d '{"text":"Deployment to production completed!"}'
```

## Monitoring and Observability

### Key Metrics to Track

1. **Deployment Frequency**: How often you deploy
2. **Lead Time**: Time from commit to production
3. **Mean Time to Recovery (MTTR)**: Time to recover from failure
4. **Change Failure Rate**: Percentage of deployments causing failures

### Implementing Monitoring

```yaml
post-deployment:
  steps:
    - name: Monitor deployment
      run: |
        # Check application health
        curl -f https://myapp.com/health || exit 1
        
        # Check error rates
        check-error-rate --threshold 1%
        
        # Check response times
        check-response-time --threshold 500ms
        
        # Check resource usage
        check-cpu-usage --threshold 80%
```

## Rollback Strategies

### Automatic Rollback

```yaml
deploy:
  steps:
    - name: Deploy new version
      id: deploy
      run: deploy.sh
    
    - name: Health check
      id: health
      run: health-check.sh
      continue-on-error: true
    
    - name: Rollback on failure
      if: steps.health.outcome == 'failure'
      run: rollback.sh
```

### Manual Rollback

```yaml
rollback:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to rollback to'
        required: true
  steps:
    - name: Rollback to version
      run: |
        aws ecs update-service \
          --cluster production \
          --service my-app \
          --task-definition my-app:${{ github.event.inputs.version }}
```

## Summary

**CI/CD Pipeline Stages**:
1. Source → Code commit triggers pipeline
2. Build → Compile and package application
3. Test → Validate code quality and functionality
4. Deploy → Release to environments
5. Monitor → Track application health

**Best Practices**:
- Automate everything
- Test early and often
- Keep pipelines fast
- Use proper branching strategy
- Implement gradual rollouts
- Monitor and measure

**Next Steps**:
- Learn Docker to ECS deployment
- Practice building complete pipelines
- Implement monitoring and alerting

## Resources

- [Martin Fowler - Continuous Integration](https://martinfowler.com/articles/continuousIntegration.html)
- [The DevOps Handbook](https://www.amazon.com/DevOps-Handbook-World-Class-Reliability-Organizations/dp/1942788002)
- [AWS DevOps Blog](https://aws.amazon.com/blogs/devops/)
- [GitHub Actions CI/CD](https://github.com/features/actions)

