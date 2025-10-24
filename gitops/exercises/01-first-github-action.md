# Exercise 1: Your First GitHub Action

## Objective
Create your first GitHub Actions workflow and understand the basics of CI/CD automation. By the end of this exercise, you'll have a working GitHub Actions workflow that runs tests and builds your application.

## Prerequisites
- GitHub account
- Basic Git knowledge
- Completed Docker lectures (docker-lectures/)
- Text editor or IDE

## Part 1: Setting Up Your Repository

### Task 1: Create a New Repository

1. Go to GitHub and create a new repository
2. Name it `github-actions-practice`
3. Initialize with a README
4. Clone it to your local machine

```bash
git clone https://github.com/YOUR_USERNAME/github-actions-practice.git
cd github-actions-practice
```

### Task 2: Create a Simple Node.js Application

Create a basic application to test with:

```bash
# Initialize Node.js project
npm init -y

# Install dependencies
npm install express --save
npm install jest supertest --save-dev
```

**app.js**:
```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'Hello, GitHub Actions!' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Only start server if not in test environment
if (process.env.NODE_ENV !== 'test') {
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
}

module.exports = app;
```

**app.test.js**:
```javascript
const request = require('supertest');
const app = require('./app');

describe('API Endpoints', () => {
  test('GET / should return welcome message', async () => {
    const response = await request(app).get('/');
    expect(response.statusCode).toBe(200);
    expect(response.body).toHaveProperty('message');
  });

  test('GET /health should return health status', async () => {
    const response = await request(app).get('/health');
    expect(response.statusCode).toBe(200);
    expect(response.body).toHaveProperty('status', 'healthy');
  });
});
```

Update **package.json** scripts:
```json
{
  "name": "github-actions-practice",
  "version": "1.0.0",
  "description": "Learning GitHub Actions",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "test": "jest",
    "test:watch": "jest --watch"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "jest": "^29.5.0",
    "supertest": "^6.3.3"
  }
}
```

**jest.config.js**:
```javascript
module.exports = {
  testEnvironment: 'node',
  coveragePathIgnorePatterns: ['/node_modules/'],
};
```

### Task 3: Test Locally

```bash
# Run tests
npm test

# Start the app
npm start

# Test in another terminal
curl http://localhost:3000
curl http://localhost:3000/health
```

**Questions to Answer**:
1. Why do we need to export the app in app.js?
2. What is the purpose of the health endpoint?
3. Why do we check NODE_ENV before starting the server?

## Part 2: Create Your First Workflow

### Task 4: Create Workflow Directory

```bash
mkdir -p .github/workflows
```

### Task 5: Create a Simple CI Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

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
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Display success message
        run: echo "✅ Tests passed successfully!"
```

### Task 6: Commit and Push

```bash
git add .
git commit -m "Add simple CI workflow"
git push origin main
```

### Task 7: View Workflow Execution

1. Go to your repository on GitHub
2. Click on the "Actions" tab
3. Watch your workflow run!

**Questions to Answer**:
1. What triggers this workflow?
2. What does `ubuntu-latest` mean?
3. What's the difference between `npm ci` and `npm install`?
4. What happens if the tests fail?

## Part 3: Improve Your Workflow

### Task 8: Add Code Quality Checks

Update `.github/workflows/ci.yml`:

```yaml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  NODE_VERSION: '16'

jobs:
  lint:
    name: Lint Code
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run ESLint
        run: npx eslint . --ext .js
        continue-on-error: true
  
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests with coverage
        run: npm test -- --coverage
      
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        if: always()
  
  build:
    name: Build Application
    needs: [lint, test]
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build (if applicable)
        run: echo "Build step - add your build command here"
      
      - name: Display build info
        run: |
          echo "Build completed!"
          echo "Commit: ${{ github.sha }}"
          echo "Branch: ${{ github.ref }}"
          echo "Actor: ${{ github.actor }}"
```

**Questions to Answer**:
1. Why do we use `needs: [lint, test]` in the build job?
2. What does `cache: 'npm'` do?
3. What is the purpose of `continue-on-error: true`?
4. When would the coverage upload step run with `if: always()`?

## Part 4: Add Matrix Testing

### Task 9: Test Multiple Node.js Versions

Update your workflow to test multiple Node.js versions:

```yaml
name: CI Pipeline with Matrix

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    name: Test on Node.js ${{ matrix.node-version }}
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [14, 16, 18, 20]
      fail-fast: false
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Report results
        if: always()
        run: |
          echo "Tests completed for Node.js ${{ matrix.node-version }}"
          echo "Status: ${{ job.status }}"
```

**Questions to Answer**:
1. How many jobs will this workflow create?
2. What does `fail-fast: false` do?
3. Why might you want to test multiple Node.js versions?

## Part 5: Working with Secrets

### Task 10: Add Secrets to Your Workflow

1. Go to your repository settings
2. Navigate to: Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add a secret:
   - Name: `NOTIFICATION_TOKEN`
   - Value: `test-secret-value-123`

Create `.github/workflows/secrets-demo.yml`:

```yaml
name: Using Secrets

on:
  workflow_dispatch:  # Manual trigger

jobs:
  deploy:
    name: Deploy (Demo)
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Use secret (safe way)
        env:
          TOKEN: ${{ secrets.NOTIFICATION_TOKEN }}
        run: |
          echo "Token is set: $([ -n "$TOKEN" ] && echo 'Yes' || echo 'No')"
          echo "Token length: ${#TOKEN}"
          # Never echo the actual token value!
      
      - name: Simulate deployment
        run: |
          echo "Deploying application..."
          echo "Using secret for authentication"
          echo "Deployment completed!"
```

**Questions to Answer**:
1. Why should you never `echo` secret values?
2. How are secrets different from environment variables?
3. What is `workflow_dispatch` used for?

## Part 6: Conditional Execution

### Task 11: Deploy Only on Main Branch

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy Pipeline

on:
  push:
    branches: [ main ]

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '16'
      - run: npm ci
      - run: npm test
  
  deploy-staging:
    name: Deploy to Staging
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: staging
      url: https://staging.example.com
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to staging
        run: |
          echo "Deploying to staging environment..."
          echo "Branch: ${{ github.ref }}"
          echo "Commit: ${{ github.sha }}"
          echo "Deployment URL: https://staging.example.com"
  
  deploy-production:
    name: Deploy to Production
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to production
        run: |
          echo "Deploying to production environment..."
          echo "Branch: ${{ github.ref }}"
          echo "Commit: ${{ github.sha }}"
          echo "Deployment URL: https://example.com"
```

**Questions to Answer**:
1. When will the deploy-staging job run?
2. What is the purpose of the `environment` setting?
3. How can you add approval gates for production deployments?

## Part 7: Artifacts and Caching

### Task 12: Upload Build Artifacts

Create `.github/workflows/artifacts.yml`:

```yaml
name: Build with Artifacts

on:
  push:
    branches: [ main ]

jobs:
  build:
    name: Build Application
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
      
      - name: Create build directory
        run: |
          mkdir -p build
          echo "Build version: ${{ github.sha }}" > build/version.txt
          echo "Build date: $(date)" >> build/version.txt
          cp package.json build/
      
      - name: Upload build artifact
        uses: actions/upload-artifact@v3
        with:
          name: build-${{ github.sha }}
          path: build/
          retention-days: 7
  
  use-artifact:
    name: Use Build Artifact
    needs: build
    runs-on: ubuntu-latest
    
    steps:
      - name: Download build artifact
        uses: actions/download-artifact@v3
        with:
          name: build-${{ github.sha }}
      
      - name: Display artifact contents
        run: |
          ls -la
          cat version.txt
          echo "Artifact downloaded successfully!"
```

**Questions to Answer**:
1. What is the purpose of artifacts?
2. How long are artifacts retained by default?
3. When would you use artifacts vs. caching?

## Challenge Tasks

### Challenge 1: Add Notification on Failure

Add a step that runs only when tests fail:

```yaml
- name: Notify on failure
  if: failure()
  run: |
    echo "❌ Tests failed!"
    echo "Commit: ${{ github.sha }}"
    echo "Author: ${{ github.actor }}"
    # Add actual notification here (Slack, email, etc.)
```

### Challenge 2: Scheduled Workflow

Create a workflow that runs on a schedule:

```yaml
name: Nightly Build

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
  workflow_dispatch:

jobs:
  nightly-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run nightly tests
        run: echo "Running nightly tests..."
```

### Challenge 3: Reusable Workflow

Create a reusable workflow for common tasks:

**.github/workflows/reusable-test.yml**:
```yaml
name: Reusable Test Workflow

on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci
      - run: npm test
```

Use it in another workflow:

```yaml
name: Main CI

on: [push]

jobs:
  call-tests:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '16'
```

## Summary Questions

1. **What are the main components of a GitHub Actions workflow?**
2. **How do you trigger a workflow manually?**
3. **What is the difference between jobs running in parallel vs. sequential?**
4. **When should you use caching vs. artifacts?**
5. **How do you securely handle sensitive data in workflows?**
6. **What are matrix builds and when should you use them?**

## Best Practices Learned

1. ✅ Use specific action versions (`actions/checkout@v3`)
2. ✅ Cache dependencies to speed up workflows
3. ✅ Use secrets for sensitive data
4. ✅ Implement proper error handling
5. ✅ Add descriptive names to jobs and steps
6. ✅ Use conditional execution appropriately
7. ✅ Keep workflows modular and reusable
8. ✅ Test workflows on feature branches before merging

## Troubleshooting Tips

### Workflow Not Triggering
- Check the branch name matches the trigger configuration
- Verify the workflow file is in `.github/workflows/`
- Ensure YAML syntax is correct

### Tests Failing in CI but Pass Locally
- Check Node.js version consistency
- Verify environment variables
- Look for path or platform-specific issues
- Check for missing dependencies

### Slow Workflow Execution
- Implement caching for dependencies
- Use matrix builds efficiently
- Parallelize independent jobs
- Remove unnecessary steps

## Next Steps

- ✅ Complete Exercise 2: Docker Build and Push
- ✅ Explore GitHub Actions Marketplace
- ✅ Set up branch protection rules
- ✅ Add status badges to your README
- ✅ Learn about composite actions

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [GitHub Actions Community Forum](https://github.community/c/code-to-cloud/github-actions/41)

---

**Congratulations!** You've completed your first GitHub Actions exercise. You now understand the basics of CI/CD automation with GitHub Actions.

