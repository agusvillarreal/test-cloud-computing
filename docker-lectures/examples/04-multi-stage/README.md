# Multi-stage Docker Build Example

This example demonstrates how to use Docker multi-stage builds to create optimized production images.

## What are Multi-stage Builds?

Multi-stage builds allow you to use multiple `FROM` statements in a single Dockerfile. Each stage can use a different base image and copy artifacts from previous stages. This is useful for:

- Separating build dependencies from runtime dependencies
- Creating smaller production images
- Optimizing build cache usage
- Improving security by excluding build tools from production

## Files

- `Dockerfile` - Multi-stage Dockerfile with builder and production stages
- `package.json` - Node.js application configuration
- `nginx.conf` - Custom Nginx configuration
- `README.md` - This documentation file

## How Multi-stage Builds Work

### Stage 1: Builder
- Uses `node:16-alpine` image
- Installs dependencies
- Builds the application
- Creates production artifacts

### Stage 2: Production
- Uses `nginx:alpine` image (much smaller)
- Copies only the built artifacts from builder stage
- Configures Nginx to serve the application
- No Node.js or build tools in final image

## How to Run

1. Navigate to the example directory:
   ```bash
   cd docker-lectures/examples/04-multi-stage
   ```

2. Build the Docker image:
   ```bash
   docker build -t multi-stage-app .
   ```

3. Run the container:
   ```bash
   docker run -p 8080:80 multi-stage-app
   ```

4. Open your web browser and navigate to:
   ```
   http://localhost:8080
   ```

## Expected Output

You should see a simple HTML page with:
- "Hello from Multi-stage Docker Build!" heading
- Explanation that the content was built in the builder stage
- Served from the production stage

## What This Example Demonstrates

- Multi-stage Docker builds
- Separating build and runtime environments
- Optimizing image size
- Using different base images for different stages
- Copying artifacts between stages
- Custom Nginx configuration
- Health checks

## Key Concepts

### Stage Naming
```dockerfile
FROM node:16-alpine AS builder
FROM nginx:alpine AS production
```

### Copying Between Stages
```dockerfile
COPY --from=builder /app/dist /usr/share/nginx/html
```

### Benefits of Multi-stage Builds

1. **Smaller Images**: Final image only contains runtime dependencies
2. **Better Security**: Build tools not included in production image
3. **Faster Deployments**: Smaller images deploy faster
4. **Cleaner Separation**: Build and runtime concerns separated

## Image Size Comparison

### Single-stage Build (hypothetical)
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
# Final image includes Node.js, npm, source code, etc.
```

### Multi-stage Build (this example)
```dockerfile
# Builder stage with Node.js
FROM node:16-alpine AS builder
# ... build steps ...

# Production stage with only Nginx
FROM nginx:alpine AS production
# ... only runtime files ...
```

The multi-stage build results in a much smaller final image.

## Advanced Usage

### Build Specific Stage
```bash
# Build only the builder stage
docker build --target builder -t multi-stage-builder .

# Build only the production stage
docker build --target production -t multi-stage-prod .
```

### Inspect Build Stages
```bash
# See all stages during build
docker build --progress=plain -t multi-stage-app .
```

### Use Build Cache
```bash
# Build with cache
docker build -t multi-stage-app .

# Build without cache
docker build --no-cache -t multi-stage-app .
```

## Health Check

The application includes a health check endpoint:
```bash
curl http://localhost:8080/health
```

Expected response:
```
healthy
```

## Custom Nginx Configuration

The example includes a custom Nginx configuration with:
- Gzip compression
- Security headers
- Static file caching
- Health check endpoint
- Proper MIME types

## Best Practices Demonstrated

1. **Use Alpine Images**: Smaller base images
2. **Copy Dependencies First**: Better build cache usage
3. **Remove Package Managers**: Clean up after installation
4. **Use Non-root Users**: Security best practice
5. **Health Checks**: Monitor application health
6. **Multi-stage Builds**: Optimize final image size

## Stopping the Container

To stop the running container:
1. Press `Ctrl+C` in the terminal where the container is running
2. Or find the container ID and stop it:
   ```bash
   docker ps
   docker stop <container_id>
   ```

## Troubleshooting

### Build Fails
- Check that all required files are present
- Verify package.json syntax
- Ensure Docker is running

### Container Won't Start
- Check port mapping (8080:80)
- Verify Nginx configuration
- Check container logs: `docker logs <container_id>`

### Health Check Fails
- Ensure curl is available in the container
- Check that Nginx is running on port 80
- Verify health check endpoint is accessible
