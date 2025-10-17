# Exercise 3: Docker Compose

## Objective
Learn how to use Docker Compose to define and run multi-container Docker applications.

## Prerequisites
- Completed Exercises 1 and 2
- Understanding of Docker images and containers
- Docker Compose installed (comes with Docker Desktop)

## What is Docker Compose?

Docker Compose is a tool for defining and running multi-container Docker applications. It uses YAML files to configure your application's services, networks, and volumes.

## Tasks

### Task 1: Create a Simple Multi-container Application
Create a new directory for this exercise:
```bash
mkdir docker-compose-exercise
cd docker-compose-exercise
```

Create a simple web application:
```bash
# Create a simple HTML file
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Docker Compose App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; }
        .header { color: #333; border-bottom: 2px solid #007acc; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🐳 Docker Compose Application</h1>
        <p>This is a multi-container application running with Docker Compose!</p>
        <p>Services:</p>
        <ul>
            <li>Web server (Nginx)</li>
            <li>Database (MySQL)</li>
            <li>Cache (Redis)</li>
        </ul>
    </div>
</body>
</html>
EOF
```

Create a Docker Compose file:
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./index.html:/usr/share/nginx/html/index.html
    depends_on:
      - db
      - redis

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: myapp
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  db_data:
  redis_data:
```

**Questions to Answer**:
1. What does the `version: '3.8'` specify?
2. What is the purpose of the `depends_on` directive?
3. What are volumes used for?

### Task 2: Run Your First Docker Compose Application
```bash
# Start all services
docker-compose up -d

# Check running containers
docker-compose ps

# Check logs
docker-compose logs

# Check logs for specific service
docker-compose logs web
```

**Questions to Answer**:
1. What does the `-d` flag do in `docker-compose up`?
2. How do you view logs for all services?
3. How do you view logs for a specific service?

### Task 3: Test Your Application
```bash
# Test the web service
curl http://localhost:8080

# Check if MySQL is running
docker-compose exec db mysql -u root -prootpassword -e "SHOW DATABASES;"

# Check if Redis is running
docker-compose exec redis redis-cli ping
```

**Questions to Answer**:
1. How do you execute commands in a specific service?
2. What does the `exec` command do?
3. How do you access the database from the host?

### Task 4: Scale Services
```bash
# Scale the web service to 3 instances
docker-compose up -d --scale web=3

# Check the scaled services
docker-compose ps

# Check which ports are being used
docker ps
```

**Questions to Answer**:
1. What happens when you scale a service?
2. How does Docker Compose handle port conflicts when scaling?
3. Why might you want to scale services?

### Task 5: Stop and Clean Up
```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Check that everything is cleaned up
docker ps -a
docker volume ls
```

**Questions to Answer**:
1. What's the difference between `docker-compose down` and `docker-compose down -v`?
2. When would you use `-v` flag?
3. How do you verify that everything is cleaned up?

## Challenge Tasks

### Challenge 1: Create a Full-stack Application
Create a more complex application with a Python backend and MySQL database:

Create the Python application:
```bash
# Create a new directory
mkdir fullstack-app
cd fullstack-app

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.3
PyMySQL==1.1.0
redis==4.6.0
EOF

# Create the Python app
cat > app.py << 'EOF'
from flask import Flask, jsonify, request
import pymysql
import redis
import os
import json

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'db'),
    'user': os.environ.get('DB_USER', 'user'),
    'password': os.environ.get('DB_PASSWORD', 'password'),
    'database': os.environ.get('DB_NAME', 'myapp'),
    'port': int(os.environ.get('DB_PORT', 3306))
}

# Redis configuration
REDIS_HOST = os.environ.get('REDIS_HOST', 'redis')
REDIS_PORT = int(os.environ.get('REDIS_PORT', 6379))

def get_db_connection():
    return pymysql.connect(**DB_CONFIG)

def get_redis_connection():
    return redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

@app.route('/')
def home():
    return '''
    <h1>🐳 Full-stack Docker App</h1>
    <p>This is a full-stack application with:</p>
    <ul>
        <li>Python Flask backend</li>
        <li>MySQL database</li>
        <li>Redis cache</li>
    </ul>
    <p>Try these endpoints:</p>
    <ul>
        <li><a href="/users">GET /users</a> - List users</li>
        <li><a href="/cache">GET /cache</a> - Check cache</li>
        <li><a href="/health">GET /health</a> - Health check</li>
    </ul>
    '''

@app.route('/users')
def get_users():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users")
        users = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(users)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/users', methods=['POST'])
def create_user():
    try:
        data = request.get_json()
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO users (name, email) VALUES (%s, %s)",
            (data['name'], data['email'])
        )
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'User created successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/cache')
def get_cache():
    try:
        r = get_redis_connection()
        # Set a test value
        r.set('test_key', 'Hello from Redis!')
        value = r.get('test_key')
        return jsonify({'cache_value': value})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    try:
        # Check database connection
        conn = get_db_connection()
        conn.close()
        
        # Check Redis connection
        r = get_redis_connection()
        r.ping()
        
        return jsonify({
            'status': 'healthy',
            'database': 'connected',
            'redis': 'connected'
        })
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF
```

Create a Dockerfile for the Python app:
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose port
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
```

Create a Docker Compose file:
```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "5000:5000"
    environment:
      - DB_HOST=db
      - DB_USER=user
      - DB_PASSWORD=password
      - DB_NAME=myapp
      - REDIS_HOST=redis
    depends_on:
      - db
      - redis
    volumes:
      - .:/app
    command: python app.py

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: myapp
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
    command: --default-authentication-plugin=mysql_native_password

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  db_data:
  redis_data:
```

**Questions to Answer**:
1. How do you build a custom image in Docker Compose?
2. What is the purpose of the `command` directive?
3. How do you pass environment variables to services?

### Challenge 2: Test the Full-stack Application
```bash
# Build and start all services
docker-compose up -d --build

# Wait for services to be ready
sleep 10

# Test the application
curl http://localhost:5000

# Test the health endpoint
curl http://localhost:5000/health

# Test the cache endpoint
curl http://localhost:5000/cache

# Create a user
curl -X POST http://localhost:5000/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'

# List users
curl http://localhost:5000/users

# Check logs
docker-compose logs web
docker-compose logs db
docker-compose logs redis
```

### Challenge 3: Add a Reverse Proxy
Create an Nginx reverse proxy configuration:

Create nginx.conf:
```nginx
events {
    worker_connections 1024;
}

http {
    upstream web {
        server web:5000;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://web;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

Update the Docker Compose file to include Nginx:
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - web

  web:
    build: .
    environment:
      - DB_HOST=db
      - DB_USER=user
      - DB_PASSWORD=password
      - DB_NAME=myapp
      - REDIS_HOST=redis
    depends_on:
      - db
      - redis
    volumes:
      - .:/app
    command: python app.py

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: myapp
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    volumes:
      - db_data:/var/lib/mysql
    command: --default-authentication-plugin=mysql_native_password

  redis:
    image: redis:alpine
    volumes:
      - redis_data:/data

volumes:
  db_data:
  redis_data:
```

Test the reverse proxy:
```bash
# Restart with the new configuration
docker-compose down
docker-compose up -d --build

# Test through the reverse proxy
curl http://localhost
curl http://localhost/health
curl http://localhost/cache
```

## Summary Questions

1. **What is Docker Compose and why is it useful?**
2. **How do you define services in a Docker Compose file?**
3. **What is the purpose of volumes in Docker Compose?**
4. **How do you handle service dependencies?**
5. **What are the benefits of using Docker Compose over running containers manually?**

## Best Practices Learned

1. **Use version 3.8** for Docker Compose files
2. **Define service dependencies** with `depends_on`
3. **Use volumes** for persistent data
4. **Set environment variables** for configuration
5. **Use build context** for custom images
6. **Implement health checks** for production applications
7. **Use reverse proxies** for load balancing and SSL termination

## Common Docker Compose Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs

# Scale services
docker-compose up -d --scale web=3

# Execute commands
docker-compose exec web bash

# Build and start
docker-compose up -d --build

# Remove volumes
docker-compose down -v
```

## Next Steps
- Practice with more complex applications
- Learn about Docker networking
- Explore Docker Swarm for orchestration
- Learn about production deployment strategies
