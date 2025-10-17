# Exercise 1: Basic Docker Commands

## Objective
Get familiar with basic Docker commands and understand the Docker workflow.

## Prerequisites
- Docker installed and running
- Basic command line knowledge

## Tasks

### Task 1: Check Docker Installation
```bash
# Check Docker version
docker --version

# Check Docker info
docker info

# Check running containers
docker ps
```

**Expected Output**: Docker version information and empty container list.

### Task 2: Run Your First Container
```bash
# Run the hello-world container
docker run hello-world
```

**Questions to Answer**:
1. What happened when you ran this command?
2. Did Docker download anything? Why?
3. What is the difference between `docker run` and `docker start`?

### Task 3: Explore Container Lifecycle
```bash
# Run a container in the background
docker run -d --name my-nginx nginx

# Check running containers
docker ps

# Check all containers (including stopped)
docker ps -a

# Stop the container
docker stop my-nginx

# Start the container again
docker start my-nginx

# Remove the container
docker rm my-nginx
```

**Questions to Answer**:
1. What does the `-d` flag do?
2. What does the `--name` flag do?
3. What's the difference between `docker stop` and `docker kill`?

### Task 4: Work with Images
```bash
# List all images
docker images

# Pull a specific image
docker pull ubuntu:20.04

# Run an interactive container
docker run -it ubuntu:20.04 bash

# Inside the container, run:
# ls -la
# cat /etc/os-release
# exit
```

**Questions to Answer**:
1. What does the `-it` flag do?
2. How do you exit an interactive container?
3. What happens to the container when you exit?

### Task 5: Port Mapping
```bash
# Run nginx with port mapping
docker run -d -p 8080:80 --name web-server nginx

# Check if the container is running
docker ps

# Open your browser and go to http://localhost:8080
# You should see the nginx welcome page

# Stop and remove the container
docker stop web-server
docker rm web-server
```

**Questions to Answer**:
1. What does `-p 8080:80` mean?
2. Why do we need port mapping?
3. What happens if you don't specify port mapping?

### Task 6: Environment Variables
```bash
# Run a container with environment variables
docker run -d -p 3000:3000 -e NODE_ENV=production --name node-app node:16-alpine node -e "console.log('Environment:', process.env.NODE_ENV); setInterval(() => console.log('Running...'), 5000)"

# Check the logs
docker logs node-app

# Stop and remove the container
docker stop node-app
docker rm node-app
```

**Questions to Answer**:
1. How do you pass environment variables to a container?
2. How do you view container logs?
3. What happens if you don't specify a command for the container?

## Challenge Tasks

### Challenge 1: Container Inspection
```bash
# Run a container
docker run -d --name inspect-me nginx

# Inspect the container
docker inspect inspect-me

# Get container statistics
docker stats inspect-me

# Clean up
docker stop inspect-me
docker rm inspect-me
```

**Questions to Answer**:
1. What information does `docker inspect` provide?
2. How can you use this information for debugging?

### Challenge 2: File Copying
```bash
# Create a test file
echo "Hello from host!" > test.txt

# Run a container
docker run -d --name file-test ubuntu:20.04 sleep 300

# Copy file to container
docker cp test.txt file-test:/tmp/

# Execute command in container
docker exec file-test cat /tmp/test.txt

# Copy file from container
docker exec file-test sh -c "echo 'Hello from container!' > /tmp/container.txt"
docker cp file-test:/tmp/container.txt ./container.txt
cat container.txt

# Clean up
docker stop file-test
docker rm file-test
rm test.txt container.txt
```

**Questions to Answer**:
1. How do you copy files to and from containers?
2. When might you need to copy files to containers?

## Summary Questions

1. **What is the difference between a Docker image and a container?**
2. **How do you run a container in the background?**
3. **What is port mapping and why is it important?**
4. **How do you pass environment variables to containers?**
5. **What are the main commands for container lifecycle management?**

## Next Steps
- Practice these commands until you're comfortable
- Try running different types of applications (databases, web servers, etc.)
- Experiment with different flags and options
- Move on to Exercise 2: Building Your First Image
