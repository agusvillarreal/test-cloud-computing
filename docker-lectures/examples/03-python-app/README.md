# Python Flask Application Docker Example

This example demonstrates how to containerize a Python Flask web application using Docker.

## Files

- `Dockerfile` - Instructions to build the Python application image
- `app.py` - Flask web application with multiple endpoints
- `requirements.txt` - Python dependencies
- `README.md` - This documentation file

## Application Features

The Flask application includes:
- Home page with container information
- Health check endpoint (`/health`)
- Information endpoint (`/info`)
- Responsive HTML interface
- Environment variable support

## How to Run

1. Navigate to the example directory:
   ```bash
   cd docker-lectures/examples/03-python-app
   ```

2. Build the Docker image:
   ```bash
   docker build -t python-flask-app .
   ```

3. Run the container with port mapping:
   ```bash
   docker run -p 5000:5000 python-flask-app
   ```

4. Open your web browser and navigate to:
   ```
   http://localhost:5000
   ```

## API Endpoints

- **GET /** - Home page with container information
- **GET /health** - Health check endpoint (returns JSON)
- **GET /info** - Container information endpoint (returns JSON)

## Expected Output

### Home Page
You should see a styled HTML page displaying:
- Application status
- Container information (Python version, platform, container ID, etc.)
- Instructions and Docker concepts
- Links to API endpoints

### Health Check
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.123456",
  "service": "python-flask-app"
}
```

### Info Endpoint
```json
{
  "python_version": "3.9.7",
  "platform": "Linux-5.4.0-74-generic-x86_64-with-glibc2.31",
  "container_id": "abc123def456",
  "environment": "production",
  "timestamp": "2024-01-15T10:30:00.123456"
}
```

## What This Example Demonstrates

- Python application containerization
- Flask web framework in Docker
- Environment variable usage
- Port mapping and exposure
- Health checks
- Non-root user security
- Multi-layer Dockerfile optimization
- API endpoint creation

## Key Concepts

- **FROM python:3.9-slim**: Uses official Python image
- **WORKDIR**: Sets working directory
- **ENV**: Sets environment variables
- **COPY requirements.txt**: Copies dependencies first for better caching
- **RUN pip install**: Installs Python packages
- **USER appuser**: Runs as non-root user for security
- **EXPOSE 5000**: Documents the port the app listens on
- **HEALTHCHECK**: Implements health monitoring
- **CMD**: Runs the Flask application

## Advanced Usage

### Run with Custom Environment
```bash
docker run -p 5000:5000 -e ENVIRONMENT=staging python-flask-app
```

### Run in Background
```bash
docker run -d -p 5000:5000 --name flask-app python-flask-app
```

### View Logs
```bash
docker logs flask-app
```

### Access Container Shell
```bash
docker exec -it flask-app bash
```

### Test Health Check
```bash
curl http://localhost:5000/health
```

## Stopping the Container

To stop the running container:
1. Press `Ctrl+C` in the terminal where the container is running
2. Or find the container ID and stop it:
   ```bash
   docker ps
   docker stop <container_id>
   ```

## Development Mode

For development, you can mount the source code:
```bash
docker run -p 5000:5000 -v $(pwd):/app python-flask-app
```

Note: This requires modifying the Dockerfile to install dependencies in development mode.
