# Docker Images

## What are Docker Images?

Docker images are read-only templates that contain everything needed to run an application:
- Application code
- Runtime environment
- System libraries
- Dependencies
- Configuration files

## Image Layers

Docker images are built using a layered filesystem:
- Each instruction in a Dockerfile creates a new layer
- Layers are cached and reused
- Only changed layers are rebuilt
- This makes images efficient and fast to build

## Working with Images

### Pulling Images
```bash
# Pull latest version
docker pull nginx

# Pull specific version
docker pull nginx:1.21

# Pull from different registry
docker pull myregistry.com/myimage:latest
```

### Listing Images
```bash
# List all images
docker images

# List images with specific format
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Filter images
docker images nginx
```

### Removing Images
```bash
# Remove specific image
docker rmi nginx:1.21

# Remove unused images
docker image prune

# Remove all unused images (not just dangling)
docker image prune -a
```

## Creating Custom Images

### Using Dockerfile
```dockerfile
# Use official Python runtime as base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first (for better caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Define command to run
CMD ["python", "app.py"]
```

### Building Images
```bash
# Build image with tag
docker build -t myapp:latest .

# Build with specific Dockerfile
docker build -f Dockerfile.prod -t myapp:prod .

# Build without cache
docker build --no-cache -t myapp:latest .
```

## Image Best Practices

### 1. Use Official Base Images
```dockerfile
# Good
FROM node:16-alpine

# Avoid
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y nodejs
```

### 2. Minimize Layers
```dockerfile
# Good - combine RUN commands
RUN apt-get update && \
    apt-get install -y python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Avoid - separate RUN commands
RUN apt-get update
RUN apt-get install -y python3
RUN apt-get clean
```

### 3. Use .dockerignore
```dockerignore
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.nyc_output
.coverage
```

### 4. Multi-stage Builds
```dockerfile
# Build stage
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Image Security

### 1. Scan Images for Vulnerabilities
```bash
# Using Docker Scout (if available)
docker scout cves myapp:latest

# Using Trivy
trivy image myapp:latest
```

### 2. Use Non-root Users
```dockerfile
# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Switch to non-root user
USER nextjs
```

### 3. Keep Images Updated
```bash
# Check for outdated packages
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image myapp:latest
```

## Image Registry

### Docker Hub
- Public registry for Docker images
- Free for public repositories
- Paid plans for private repositories

### Private Registries
- AWS ECR (Elastic Container Registry)
- Google Container Registry
- Azure Container Registry
- Self-hosted registries

### Pushing Images
```bash
# Tag image for registry
docker tag myapp:latest myregistry.com/myapp:latest

# Push to registry
docker push myregistry.com/myapp:latest

# Login to registry
docker login myregistry.com
```

## Image Optimization

### 1. Use Alpine Images
```dockerfile
# Smaller base image
FROM node:16-alpine
```

### 2. Remove Package Managers
```dockerfile
# Remove apt cache after installation
RUN apt-get update && \
    apt-get install -y python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### 3. Use Distroless Images
```dockerfile
# Minimal runtime image
FROM gcr.io/distroless/python3
COPY . /app
WORKDIR /app
CMD ["app.py"]
```

## Common Commands Summary

```bash
# Image operations
docker pull <image>          # Download image
docker push <image>          # Upload image
docker build -t <tag> .      # Build image
docker rmi <image>           # Remove image
docker images                # List images
docker inspect <image>       # Inspect image details
docker history <image>       # Show image layers
```
