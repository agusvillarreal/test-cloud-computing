# Exercise 2: Building Your First Docker Image

## Objective
Learn how to create custom Docker images using Dockerfiles and understand Docker image building best practices.

## Prerequisites
- Completed Exercise 1
- Basic understanding of Docker commands
- Text editor (VS Code, vim, nano, etc.)

## Tasks

### Task 1: Create a Simple Dockerfile
Create a new directory for this exercise:
```bash
mkdir docker-exercise-2
cd docker-exercise-2
```

Create a simple HTML file:
```bash
echo '<h1>Hello from my custom Docker image!</h1>' > index.html
```

Create a Dockerfile:
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
```

**Questions to Answer**:
1. What does each instruction in the Dockerfile do?
2. Why do we use `nginx:alpine` instead of just `nginx`?

### Task 2: Build Your First Image
```bash
# Build the image
docker build -t my-web-server .

# List your images
docker images

# Run your custom image
docker run -d -p 8080:80 --name my-server my-web-server

# Test it in your browser: http://localhost:8080

# Clean up
docker stop my-server
docker rm my-server
```

**Questions to Answer**:
1. What does the `-t` flag do in the build command?
2. What does the `.` at the end of the build command mean?
3. How do you know if the build was successful?

### Task 3: Improve Your Dockerfile
Create a more sophisticated HTML file:
```bash
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>My Docker App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; }
        .header { color: #333; border-bottom: 2px solid #007acc; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🐳 Welcome to Docker!</h1>
        <p>This is a custom web server running in a Docker container.</p>
        <p>Built with: Nginx + Alpine Linux</p>
        <p>Current time: <span id="time"></span></p>
    </div>
    <script>
        document.getElementById('time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF
```

Update your Dockerfile to include more metadata:
```dockerfile
FROM nginx:alpine

# Add metadata
LABEL maintainer="your-email@example.com"
LABEL version="1.0"
LABEL description="Custom web server for Docker learning"

# Copy HTML file
COPY index.html /usr/share/nginx/html/

# Expose port
EXPOSE 80

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
```

**Questions to Answer**:
1. What is the purpose of LABEL instructions?
2. What does the HEALTHCHECK instruction do?
3. Why might health checks be important in production?

### Task 4: Build and Test the Improved Image
```bash
# Build the improved image
docker build -t my-web-server:v2 .

# Run the new version
docker run -d -p 8080:80 --name my-server-v2 my-web-server:v2

# Check the health status
docker ps

# Test the health check
curl http://localhost:8080

# Clean up
docker stop my-server-v2
docker rm my-server-v2
```

### Task 5: Create a Python Application
Create a simple Python application:
```bash
# Create a new directory
mkdir python-app
cd python-app

# Create a simple Python app
cat > app.py << 'EOF'
#!/usr/bin/env python3
from flask import Flask
import datetime

app = Flask(__name__)

@app.route('/')
def home():
    return f'''
    <h1>🐍 Python Flask App in Docker</h1>
    <p>Current time: {datetime.datetime.now()}</p>
    <p>This app is running in a Docker container!</p>
    '''

@app.route('/health')
def health():
    return {'status': 'healthy', 'timestamp': datetime.datetime.now().isoformat()}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Create requirements file
echo "Flask==2.3.3" > requirements.txt
```

Create a Dockerfile for the Python app:
```dockerfile
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first (for better caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose port
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
```

**Questions to Answer**:
1. Why do we copy `requirements.txt` before copying the application code?
2. What does `--no-cache-dir` do in the pip install command?
3. Why do we use `host='0.0.0.0'` in the Flask app?

### Task 6: Build and Run the Python App
```bash
# Build the Python app image
docker build -t my-python-app .

# Run the Python app
docker run -d -p 5000:5000 --name python-server my-python-app

# Test the app
curl http://localhost:5000
curl http://localhost:5000/health

# Check logs
docker logs python-server

# Clean up
docker stop python-server
docker rm python-server
```

## Challenge Tasks

### Challenge 1: Multi-stage Build
Create a more complex application with a multi-stage build:

Create a simple Node.js app:
```bash
mkdir nodejs-app
cd nodejs-app

# Create package.json
cat > package.json << 'EOF'
{
  "name": "docker-nodejs-app",
  "version": "1.0.0",
  "description": "Simple Node.js app for Docker",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "build": "echo 'Building...' && echo '<h1>Built Node.js App</h1>' > dist/index.html"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

# Create server.js
cat > server.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send(`
    <h1>🚀 Node.js App in Docker</h1>
    <p>This is a Node.js application running in a Docker container!</p>
    <p>Built with Express.js</p>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`App listening at http://0.0.0.0:${port}`);
});
EOF
```

Create a multi-stage Dockerfile:
```dockerfile
# Build stage
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
```

**Questions to Answer**:
1. What are the benefits of multi-stage builds?
2. How does the `COPY --from=builder` instruction work?
3. Why is the final image smaller with multi-stage builds?

### Challenge 2: Environment Variables and Configuration
Modify your Python app to use environment variables:

Update the Python app:
```python
#!/usr/bin/env python3
from flask import Flask
import datetime
import os

app = Flask(__name__)

@app.route('/')
def home():
    env = os.environ.get('ENVIRONMENT', 'development')
    return f'''
    <h1>🐍 Python Flask App in Docker</h1>
    <p>Environment: {env}</p>
    <p>Current time: {datetime.datetime.now()}</p>
    <p>This app is running in a Docker container!</p>
    '''

@app.route('/health')
def health():
    return {
        'status': 'healthy', 
        'timestamp': datetime.datetime.now().isoformat(),
        'environment': os.environ.get('ENVIRONMENT', 'development')
    }

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
```

Update the Dockerfile to include environment variables:
```dockerfile
FROM python:3.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV ENVIRONMENT=production

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
```

Test with different environments:
```bash
# Build the image
docker build -t my-python-app:env .

# Run with default environment
docker run -d -p 5000:5000 --name python-prod my-python-app:env

# Run with custom environment
docker run -d -p 5001:5000 -e ENVIRONMENT=staging --name python-staging my-python-app:env

# Test both
curl http://localhost:5000
curl http://localhost:5001

# Clean up
docker stop python-prod python-staging
docker rm python-prod python-staging
```

## Summary Questions

1. **What is the purpose of a Dockerfile?**
2. **What is the difference between COPY and ADD instructions?**
3. **Why is it important to copy requirements.txt before copying application code?**
4. **What are the benefits of multi-stage builds?**
5. **How do you pass environment variables to Docker containers?**

## Best Practices Learned

1. **Use specific base image tags** (e.g., `python:3.9-slim` instead of `python:latest`)
2. **Copy dependencies first** for better build cache usage
3. **Use multi-stage builds** for smaller production images
4. **Add health checks** for production applications
5. **Use environment variables** for configuration
6. **Add metadata** with LABEL instructions

## Next Steps
- Practice building different types of applications
- Experiment with different base images
- Learn about Docker Compose for multi-container applications
- Move on to Exercise 3: Docker Compose
