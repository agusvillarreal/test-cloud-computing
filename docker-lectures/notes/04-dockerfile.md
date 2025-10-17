# Dockerfile

## What is a Dockerfile?

A Dockerfile is a text file that contains a series of instructions used to build a Docker image. It defines:
- Base image to use
- Dependencies to install
- Files to copy
- Commands to run
- Environment variables
- Ports to expose

## Dockerfile Instructions

### FROM
Specifies the base image to build upon.
```dockerfile
# Use official Python image
FROM python:3.9

# Use specific version
FROM python:3.9.7

# Use Alpine variant (smaller)
FROM python:3.9-alpine

# Use distroless (minimal runtime)
FROM gcr.io/distroless/python3
```

### WORKDIR
Sets the working directory for subsequent instructions.
```dockerfile
# Set working directory
WORKDIR /app

# Use absolute path
WORKDIR /usr/src/app

# Use relative path
WORKDIR src
```

### COPY
Copies files from host to container.
```dockerfile
# Copy single file
COPY package.json .

# Copy directory
COPY src/ /app/src/

# Copy with specific ownership
COPY --chown=node:node package.json .

# Copy with specific permissions
COPY --chmod=755 script.sh /usr/local/bin/
```

### ADD
Similar to COPY but with additional features.
```dockerfile
# Copy files (same as COPY)
ADD package.json .

# Extract tar files
ADD archive.tar.gz /app/

# Download from URL
ADD https://example.com/file.txt /app/
```

### RUN
Executes commands during image build.
```dockerfile
# Single command
RUN apt-get update

# Multiple commands (recommended)
RUN apt-get update && \
    apt-get install -y python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Use shell form
RUN echo "Hello World"

# Use exec form (recommended)
RUN ["apt-get", "update"]
```

### CMD
Defines the default command to run when container starts.
```dockerfile
# Shell form
CMD python app.py

# Exec form (recommended)
CMD ["python", "app.py"]

# With parameters
CMD ["python", "app.py", "--port", "8000"]
```

### ENTRYPOINT
Similar to CMD but cannot be overridden easily.
```dockerfile
# Exec form
ENTRYPOINT ["python", "app.py"]

# Shell form
ENTRYPOINT python app.py

# Combined with CMD
ENTRYPOINT ["python", "app.py"]
CMD ["--port", "8000"]
```

### ENV
Sets environment variables.
```dockerfile
# Set single variable
ENV NODE_ENV=production

# Set multiple variables
ENV NODE_ENV=production \
    PORT=3000 \
    DEBUG=false

# Use in subsequent instructions
ENV PATH=/app/bin:$PATH
```

### ARG
Defines build-time variables.
```dockerfile
# Define argument
ARG VERSION=latest

# Use argument
FROM node:${VERSION}

# Pass argument during build
# docker build --build-arg VERSION=16 .
```

### EXPOSE
Documents which ports the container listens on.
```dockerfile
# Expose single port
EXPOSE 80

# Expose multiple ports
EXPOSE 80 443

# Expose with protocol
EXPOSE 80/tcp 443/tcp
```

### VOLUME
Creates mount points for external volumes.
```dockerfile
# Create volume
VOLUME ["/data"]

# Multiple volumes
VOLUME ["/data", "/logs"]

# With specific path
VOLUME /var/lib/mysql
```

### USER
Sets the user for subsequent instructions.
```dockerfile
# Create user
RUN adduser --disabled-password --gecos '' appuser

# Switch to user
USER appuser

# Use specific UID
USER 1000
```

### LABEL
Adds metadata to the image.
```dockerfile
# Add labels
LABEL maintainer="john@example.com"
LABEL version="1.0"
LABEL description="My application"

# Multiple labels
LABEL maintainer="john@example.com" \
      version="1.0" \
      description="My application"
```

### HEALTHCHECK
Defines how to check if container is healthy.
```dockerfile
# Basic health check
HEALTHCHECK CMD curl -f http://localhost/ || exit 1

# With options
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Disable health check
HEALTHCHECK NONE
```

## Multi-stage Builds

### Basic Multi-stage
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

### Advanced Multi-stage
```dockerfile
# Dependencies stage
FROM node:16 AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Build stage
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:16-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
USER nextjs
EXPOSE 3000
CMD ["npm", "start"]
```

## Best Practices

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
```

### 4. Copy Dependencies First
```dockerfile
# Good - copy package.json first
COPY package*.json ./
RUN npm install
COPY . .

# Avoid - copy everything first
COPY . .
RUN npm install
```

### 5. Use Specific Tags
```dockerfile
# Good
FROM node:16.14.0-alpine

# Avoid
FROM node:latest
```

### 6. Run as Non-root User
```dockerfile
# Create user
RUN adduser --disabled-password --gecos '' appuser

# Switch to user
USER appuser
```

### 7. Use Multi-stage Builds
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
```

## Common Patterns

### Python Application
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Run application
CMD ["python", "app.py"]
```

### Node.js Application
```dockerfile
FROM node:16-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start application
CMD ["npm", "start"]
```

### Java Application
```dockerfile
FROM openjdk:11-jre-slim

WORKDIR /app

# Copy JAR file
COPY target/myapp.jar app.jar

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run application
CMD ["java", "-jar", "app.jar"]
```

## Building Images

### Basic Build
```bash
# Build with default Dockerfile
docker build -t myapp:latest .

# Build with specific Dockerfile
docker build -f Dockerfile.prod -t myapp:prod .

# Build with build arguments
docker build --build-arg VERSION=1.0 -t myapp:1.0 .
```

### Advanced Build
```bash
# Build without cache
docker build --no-cache -t myapp:latest .

# Build with specific target
docker build --target builder -t myapp:builder .

# Build with build context
docker build -f Dockerfile -t myapp:latest /path/to/context
```

## Common Commands Summary

```bash
# Build operations
docker build -t <tag> .           # Build image
docker build -f <file> -t <tag> . # Build with specific Dockerfile
docker build --no-cache -t <tag> . # Build without cache
docker build --target <stage> -t <tag> . # Build specific stage
```
