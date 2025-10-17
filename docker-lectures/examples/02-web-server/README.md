# Web Server Docker Example

This example demonstrates how to create a simple web server using Docker and Nginx.

## Files

- `Dockerfile` - Instructions to build the web server image
- `index.html` - Custom HTML page to serve
- `README.md` - This documentation file

## How to Run

1. Navigate to the example directory:
   ```bash
   cd docker-lectures/examples/02-web-server
   ```

2. Build the Docker image:
   ```bash
   docker build -t my-web-server .
   ```

3. Run the container with port mapping:
   ```bash
   docker run -p 8080:80 my-web-server
   ```

4. Open your web browser and navigate to:
   ```
   http://localhost:8080
   ```

## Expected Output

You should see a styled HTML page with:
- Welcome message
- Container information
- Instructions on how to run the example
- Docker concepts demonstrated

## What This Example Demonstrates

- Using official Nginx base image
- Copying custom files into the container
- Port exposure and mapping
- Running web servers in containers
- Custom HTML content serving

## Key Concepts

- **FROM nginx:alpine**: Uses lightweight Nginx image
- **COPY**: Copies HTML file to Nginx web directory
- **EXPOSE 80**: Documents that the container listens on port 80
- **Port Mapping**: `-p 8080:80` maps host port 8080 to container port 80

## Stopping the Container

To stop the running container:
1. Press `Ctrl+C` in the terminal where the container is running
2. Or find the container ID and stop it:
   ```bash
   docker ps
   docker stop <container_id>
   ```

## Advanced Usage

### Run in Background
```bash
docker run -d -p 8080:80 --name web-server my-web-server
```

### View Logs
```bash
docker logs web-server
```

### Access Container Shell
```bash
docker exec -it web-server sh
```
