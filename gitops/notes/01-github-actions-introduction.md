# GitHub Actions Introduction

## What is GitHub Actions?

GitHub Actions is a continuous integration and continuous delivery (CI/CD) platform that allows you to automate your build, test, and deployment pipeline. You can create workflows that build and test every pull request to your repository, or deploy merged pull requests to production.

## Key Concepts

### 1. Workflows

A workflow is an automated procedure that you add to your repository. Workflows are made up of one or more jobs and can be scheduled or triggered by an event.

**Workflow File Location**: `.github/workflows/*.yml`

### 2. Events

Events are specific activities that trigger a workflow run. Common events include:
- `push` - Code is pushed to the repository
- `pull_request` - A pull request is opened or updated
- `schedule` - Runs on a schedule (cron syntax)
- `workflow_dispatch` - Manual trigger
- `release` - A release is published

### 3. Jobs

A job is a set of steps that execute on the same runner. By default, jobs run in parallel, but you can configure them to run sequentially.

### 4. Steps

Steps are individual tasks that run commands in a job. A step can either:
- Run a shell command
- Use an action (reusable unit of code)

### 5. Actions

Actions are standalone commands that are combined into steps to create a job. You can create your own actions or use actions from the GitHub Marketplace.

### 6. Runners

A runner is a server that has the GitHub Actions runner application installed. Runners execute your workflows. GitHub provides hosted runners (Linux, Windows, macOS), or you can host your own.

## Basic Workflow Syntax

```yaml
name: CI Pipeline                    # Workflow name

on:                                  # Event triggers
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:                                # Jobs definition
  build:                            # Job ID
    runs-on: ubuntu-latest          # Runner type
    
    steps:                          # Steps in the job
    - name: Checkout code           # Step name
      uses: actions/checkout@v3     # Use an action
      
    - name: Run a command           # Another step
      run: echo "Hello World"       # Run shell command
```

## Common Workflow Patterns

### 1. Simple CI Workflow

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          echo "Running tests..."
          npm test
```

### 2. Multi-Job Workflow

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: npm run build
      
  test:
    runs-on: ubuntu-latest
    needs: build                    # Runs after build job
    steps:
      - uses: actions/checkout@v3
      - name: Test
        run: npm test
      
  deploy:
    runs-on: ubuntu-latest
    needs: [build, test]            # Runs after both jobs
    steps:
      - uses: actions/checkout@v3
      - name: Deploy
        run: echo "Deploying..."
```

### 3. Matrix Strategy (Multiple Versions)

```yaml
name: Test Multiple Versions

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [14, 16, 18]
        python-version: [3.8, 3.9, 3.10]
    
    steps:
      - uses: actions/checkout@v3
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
      - name: Test
        run: npm test
```

## Using Secrets

Secrets are encrypted environment variables that you create in your repository or organization settings.

### Setting Secrets
1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add name and value

### Using Secrets in Workflows

```yaml
name: Deploy with Secrets

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to AWS
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          aws s3 sync ./build s3://my-bucket
```

## Environment Variables

You can define environment variables at different levels:

```yaml
name: Environment Variables

on: [push]

env:                                    # Workflow-level
  GLOBAL_VAR: "global value"

jobs:
  build:
    runs-on: ubuntu-latest
    env:                                # Job-level
      JOB_VAR: "job value"
    
    steps:
      - name: Use variables
        env:                            # Step-level
          STEP_VAR: "step value"
        run: |
          echo "Global: $GLOBAL_VAR"
          echo "Job: $JOB_VAR"
          echo "Step: $STEP_VAR"
          echo "Built-in: $GITHUB_REPOSITORY"
```

## Built-in Context Variables

GitHub Actions provides several context variables:

```yaml
steps:
  - name: Print contexts
    run: |
      echo "Repository: ${{ github.repository }}"
      echo "Branch: ${{ github.ref }}"
      echo "Commit SHA: ${{ github.sha }}"
      echo "Actor: ${{ github.actor }}"
      echo "Event: ${{ github.event_name }}"
      echo "Runner OS: ${{ runner.os }}"
```

## Conditional Execution

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'    # Only on main branch
    steps:
      - name: Deploy
        run: echo "Deploying to production"
  
  notify:
    runs-on: ubuntu-latest
    if: failure()                          # Only if previous job fails
    steps:
      - name: Send notification
        run: echo "Build failed!"
```

## Artifacts

Share data between jobs or save build outputs:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: npm run build
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: build-files
          path: dist/
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Download artifact
        uses: actions/download-artifact@v3
        with:
          name: build-files
      - name: Deploy
        run: echo "Deploying files"
```

## Caching Dependencies

Speed up workflows by caching dependencies:

```yaml
steps:
  - uses: actions/checkout@v3
  
  - name: Cache npm dependencies
    uses: actions/cache@v3
    with:
      path: ~/.npm
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-node-
  
  - name: Install dependencies
    run: npm ci
```

## Best Practices

### 1. Use Specific Action Versions
```yaml
# Good - pinned version
- uses: actions/checkout@v3

# Bad - using latest
- uses: actions/checkout@main
```

### 2. Minimize Job Dependencies
```yaml
# Jobs run in parallel by default - use this to your advantage
jobs:
  lint:
    runs-on: ubuntu-latest
    # ...
  
  test:
    runs-on: ubuntu-latest
    # Runs in parallel with lint
  
  deploy:
    needs: [lint, test]  # Only add dependencies when necessary
```

### 3. Use Matrix for Multiple Configurations
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    node: [14, 16, 18]
  fail-fast: false  # Continue even if one combination fails
```

### 4. Secure Your Secrets
- Never hardcode secrets in workflows
- Use repository secrets or GitHub environments
- Limit secret access to specific branches
- Rotate secrets regularly

### 5. Optimize Workflow Execution
- Use caching for dependencies
- Fail fast when appropriate
- Use conditionals to skip unnecessary jobs
- Leverage artifacts efficiently

## Common Actions from GitHub Marketplace

### Essential Actions

```yaml
# Checkout code
- uses: actions/checkout@v3

# Setup languages/tools
- uses: actions/setup-node@v3
- uses: actions/setup-python@v4
- uses: actions/setup-java@v3

# Docker
- uses: docker/build-push-action@v4
- uses: docker/login-action@v2

# AWS
- uses: aws-actions/configure-aws-credentials@v2
- uses: aws-actions/amazon-ecr-login@v1
```

## Debugging Workflows

### Enable Debug Logging
Set these secrets in your repository:
- `ACTIONS_STEP_DEBUG`: `true` (detailed logs)
- `ACTIONS_RUNNER_DEBUG`: `true` (runner diagnostic logs)

### Using tmate for Interactive Debugging
```yaml
- name: Setup tmate session
  uses: mxschmitt/action-tmate@v3
  if: failure()  # Only on failure
```

### View Logs
```yaml
steps:
  - name: Debug information
    run: |
      echo "Current directory: $(pwd)"
      echo "List files: $(ls -la)"
      echo "Environment variables:"
      env | sort
```

## Workflow Triggers Reference

```yaml
# Push to specific branches
on:
  push:
    branches:
      - main
      - 'releases/**'
    paths:
      - 'src/**'
      - '!src/docs/**'

# Scheduled workflows (cron)
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

# Manual trigger with inputs
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

# Multiple events
on: [push, pull_request, workflow_dispatch]
```

## Example: Complete CI Workflow

```yaml
name: Complete CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '16'

jobs:
  setup:
    runs-on: ubuntu-latest
    outputs:
      cache-key: ${{ steps.cache-keys.outputs.node }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Generate cache keys
        id: cache-keys
        run: echo "node=${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}" >> $GITHUB_OUTPUT

  lint:
    needs: setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  test:
    needs: setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        if: always()

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v3
        with:
          name: build-artifact
          path: dist/
          retention-days: 7

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: build-artifact
      - name: Deploy
        run: echo "Deploying to production..."
```

## Summary

GitHub Actions provides a powerful platform for automating your software development workflows. Key takeaways:

- Workflows are defined in YAML files in `.github/workflows/`
- Events trigger workflow runs
- Jobs contain steps that run commands or actions
- Use secrets for sensitive data
- Leverage caching and artifacts for efficiency
- Follow best practices for security and performance

## Next Steps

- Practice creating your first workflow (Exercise 1)
- Explore the GitHub Actions Marketplace
- Learn about AWS ECS and Fargate (Next lecture)
- Integrate Docker builds with GitHub Actions

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [Action Examples](https://github.com/actions/starter-workflows)

