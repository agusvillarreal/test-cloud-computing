# Docker Containers

## What are Docker Containers?

Docker containers are running instances of Docker images. They provide:
- Isolated runtime environment
- Resource allocation
- Network access
- File system access
- Process management

## Container Lifecycle

### States
1. **Created**: Container created but not started
2. **Running**: Container is actively running
3. **Paused**: Container processes are suspended
4. **Stopped**: Container has been stopped
5. **Removed**: Container has been deleted

## Running Containers

### Basic Run Command
```bash
# Run container in foreground
docker run nginx

# Run container in background (detached)
docker run -d nginx

# Run with custom name
docker run --name my-nginx nginx

# Run with port mapping
docker run -p 8080:80 nginx
```

### Interactive Containers
```bash
# Run with interactive terminal
docker run -it ubuntu bash

# Run with interactive terminal and remove after exit
docker run -it --rm ubuntu bash

# Run with environment variables
docker run -e MYSQL_ROOT_PASSWORD=secret mysql
```

## Container Management

### Starting and Stopping
```bash
# Start a container
docker start container_name

# Stop a container
docker stop container_name

# Restart a container
docker restart container_name

# Pause a container
docker pause container_name

# Unpause a container
docker unpause container_name
```

### Container Information
```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Show container logs
docker logs container_name

# Follow logs in real-time
docker logs -f container_name

# Show container details
docker inspect container_name

# Show container processes
docker top container_name

# Show container statistics
docker stats container_name
```

## Container Configuration

### Port Mapping
```bash
# Map single port
docker run -p 8080:80 nginx

# Map multiple ports
docker run -p 8080:80 -p 8443:443 nginx

# Map to specific interface
docker run -p 127.0.0.1:8080:80 nginx

# Map random port
docker run -P nginx
```

### Volume Mounting
```bash
# Mount host directory
docker run -v /host/path:/container/path nginx

# Mount with read-only access
docker run -v /host/path:/container/path:ro nginx

# Use named volumes
docker run -v myvolume:/container/path nginx

# Mount current directory
docker run -v $(pwd):/app nginx
```

### Environment Variables
```bash
# Set single environment variable
docker run -e NODE_ENV=production node

# Set multiple environment variables
docker run -e NODE_ENV=production -e PORT=3000 node

# Use environment file
docker run --env-file .env node

# Pass all environment variables from host
docker run --env-file /dev/stdin node
```

### Resource Limits
```bash
# Limit memory usage
docker run -m 512m nginx

# Limit CPU usage
docker run --cpus="1.5" nginx

# Limit both memory and CPU
docker run -m 512m --cpus="1.5" nginx
```

## Container Networking

### Network Modes
```bash
# Use default bridge network
docker run nginx

# Use host network
docker run --network host nginx

# Use specific network
docker run --network mynetwork nginx

# Create custom network
docker network create mynetwork
```

### Container Communication
```bash
# Link containers (legacy)
docker run --link container1:alias container2

# Use custom network for communication
docker network create app-network
docker run --network app-network --name db mysql
docker run --network app-network --name app myapp
```

## Container Data Management

### Volumes
```bash
# Create named volume
docker volume create myvolume

# List volumes
docker volume ls

# Inspect volume
docker volume inspect myvolume

# Remove volume
docker volume rm myvolume

# Remove unused volumes
docker volume prune
```

### Bind Mounts
```bash
# Mount host directory
docker run -v /host/data:/container/data nginx

# Mount with specific options
docker run -v /host/data:/container/data:ro,z nginx
```

## Container Health Checks

### Health Check in Dockerfile
```dockerfile
FROM nginx
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
```

### Health Check in Run Command
```bash
docker run --health-cmd="curl -f http://localhost/ || exit 1" \
           --health-interval=30s \
           --health-timeout=3s \
           --health-retries=3 \
           nginx
```

## Container Debugging

### Accessing Running Containers
```bash
# Execute command in running container
docker exec -it container_name bash

# Execute command as root
docker exec -it --user root container_name bash

# Execute command in background
docker exec -d container_name command
```

### Copying Files
```bash
# Copy from container to host
docker cp container_name:/path/to/file /host/path

# Copy from host to container
docker cp /host/path container_name:/path/to/file
```

## Container Cleanup

### Removing Containers
```bash
# Remove stopped container
docker rm container_name

# Remove running container (force)
docker rm -f container_name

# Remove all stopped containers
docker container prune

# Remove all containers
docker rm $(docker ps -aq)
```

### Cleanup Commands
```bash
# Remove all unused containers, networks, images
docker system prune

# Remove everything including volumes
docker system prune -a --volumes

# Remove specific resources
docker container prune    # Remove stopped containers
docker image prune        # Remove unused images
docker volume prune       # Remove unused volumes
docker network prune      # Remove unused networks
```

## Best Practices

### 1. Use Specific Tags
```bash
# Good
docker run nginx:1.21

# Avoid
docker run nginx:latest
```

### 2. Run as Non-root User
```bash
# Use non-root user
docker run --user 1000:1000 nginx
```

### 3. Set Resource Limits
```bash
# Always set memory and CPU limits
docker run -m 512m --cpus="1.0" nginx
```

### 4. Use Health Checks
```bash
# Implement health checks for production
docker run --health-cmd="curl -f http://localhost/ || exit 1" nginx
```

### 5. Clean Up Resources
```bash
# Regular cleanup
docker system prune -f
```

## Common Commands Summary

```bash
# Container operations
docker run <image>         # Run container
docker start <container>   # Start container
docker stop <container>    # Stop container
docker restart <container> # Restart container
docker rm <container>      # Remove container
docker ps                  # List containers
docker logs <container>    # Show logs
docker exec -it <container> bash  # Access container
docker cp <src> <dest>     # Copy files
docker stats <container>   # Show statistics
```
