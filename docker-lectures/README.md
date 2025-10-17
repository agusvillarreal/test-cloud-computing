# Docker Lectures and Examples

This repository contains comprehensive Docker learning materials including lecture notes, practical examples, and hands-on exercises.

## 📚 Table of Contents

### Lecture Notes
- [01 - Docker Introduction](notes/01-docker-introduction.md)
- [02 - Docker Images](notes/02-docker-images.md)
- [03 - Docker Containers](notes/03-docker-containers.md)
- [04 - Dockerfile](notes/04-dockerfile.md)

### Examples
- [01 - Hello World](examples/01-hello-world/) - Basic Docker container
- [02 - Web Server](examples/02-web-server/) - Nginx web server
- [03 - Python App](examples/03-python-app/) - Flask web application
- [04 - Multi-stage Build](examples/04-multi-stage/) - Optimized production image

### Exercises
- [01 - Basic Commands](exercises/01-basic-commands.md) - Docker fundamentals
- [02 - Building Images](exercises/02-building-images.md) - Creating custom images
- [03 - Docker Compose](exercises/03-docker-compose.md) - Multi-container applications

## 🚀 Getting Started

### Prerequisites
- Docker installed and running
- Basic command line knowledge
- Text editor (VS Code, vim, nano, etc.)

### Installation
1. Install Docker Desktop or Docker Engine
2. Verify installation:
   ```bash
   docker --version
   docker-compose --version
   ```

## 📖 Learning Path

### Beginner Level
1. Start with [Docker Introduction](notes/01-docker-introduction.md)
2. Complete [Exercise 1: Basic Commands](exercises/01-basic-commands.md)
3. Try the [Hello World example](examples/01-hello-world/)

### Intermediate Level
1. Learn about [Docker Images](notes/02-docker-images.md) and [Containers](notes/03-docker-containers.md)
2. Complete [Exercise 2: Building Images](exercises/02-building-images.md)
3. Practice with [Web Server](examples/02-web-server/) and [Python App](examples/03-python-app/) examples

### Advanced Level
1. Master [Dockerfile](notes/04-dockerfile.md) best practices
2. Complete [Exercise 3: Docker Compose](exercises/03-docker-compose.md)
3. Explore [Multi-stage builds](examples/04-multi-stage/)

## 🛠️ Quick Start Examples

### Run Your First Container
```bash
docker run hello-world
```

### Build and Run a Custom Image
```bash
cd examples/01-hello-world
docker build -t hello-world .
docker run hello-world
```

### Start a Multi-container Application
```bash
cd examples/03-python-app
docker-compose up -d
```

## 📋 Key Concepts Covered

### Docker Fundamentals
- Containerization vs Virtualization
- Docker architecture and components
- Images, containers, and registries
- Docker daemon and client

### Image Management
- Creating custom images with Dockerfiles
- Image layers and caching
- Multi-stage builds
- Image optimization techniques

### Container Operations
- Container lifecycle management
- Port mapping and networking
- Volume mounting and data persistence
- Environment variables and configuration

### Docker Compose
- Multi-container application definition
- Service dependencies and orchestration
- Volume and network management
- Scaling and load balancing

## 🎯 Learning Objectives

By the end of this course, you will be able to:

1. **Understand Docker concepts** and how containerization works
2. **Create custom Docker images** using Dockerfiles
3. **Run and manage containers** effectively
4. **Build multi-container applications** with Docker Compose
5. **Apply best practices** for production deployments
6. **Troubleshoot common issues** and debug applications

## 🔧 Common Commands Reference

### Basic Docker Commands
```bash
# Container management
docker run <image>              # Run a container
docker start <container>        # Start a container
docker stop <container>         # Stop a container
docker rm <container>           # Remove a container
docker ps                       # List containers

# Image management
docker build -t <tag> .         # Build an image
docker images                   # List images
docker rmi <image>              # Remove an image
docker pull <image>             # Pull an image

# Information and debugging
docker logs <container>         # View container logs
docker exec -it <container> bash # Access container shell
docker inspect <container>      # Inspect container details
```

### Docker Compose Commands
```bash
docker-compose up -d            # Start services
docker-compose down             # Stop services
docker-compose logs             # View logs
docker-compose ps               # List services
docker-compose exec <service> bash # Access service shell
```

## 🚨 Troubleshooting

### Common Issues

1. **Permission denied errors**
   - Ensure Docker daemon is running
   - Check user permissions for Docker socket

2. **Port already in use**
   - Change port mapping: `-p 8081:80`
   - Stop conflicting services

3. **Build failures**
   - Check Dockerfile syntax
   - Verify all required files are present
   - Check base image availability

4. **Container won't start**
   - Check container logs: `docker logs <container>`
   - Verify port mappings
   - Check environment variables

### Getting Help
- Check Docker documentation: https://docs.docker.com/
- Use `docker --help` for command help
- Check container logs for error messages
- Verify Docker daemon is running: `docker info`

## 📚 Additional Resources

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/) - Container image registry
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Best Practices for Docker](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 Contributing

Feel free to contribute to this learning material by:
- Adding new examples
- Improving existing content
- Fixing errors or typos
- Adding more exercises

## 📄 License

This educational material is provided for learning purposes. Feel free to use and modify for educational use.

---

**Happy Learning! 🐳**
