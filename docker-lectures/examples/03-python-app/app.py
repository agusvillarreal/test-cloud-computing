#!/usr/bin/env python3
"""
Simple Python Flask Web Application
Demonstrates Docker containerization of a Python web app
"""

from flask import Flask, render_template_string
import os
import platform
import datetime

app = Flask(__name__)

# HTML template
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Python Docker App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .info {
            background-color: #e8f4f8;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .code {
            background-color: #f4f4f4;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            border-left: 4px solid #007acc;
        }
        .status {
            background-color: #d4edda;
            padding: 10px;
            border-radius: 5px;
            border-left: 4px solid #28a745;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐍 Python Flask App in Docker</h1>
        
        <div class="status">
            <h3>✅ Application Status: Running</h3>
            <p>This Python Flask application is successfully running inside a Docker container!</p>
        </div>

        <div class="info">
            <h3>Container Information:</h3>
            <ul>
                <li><strong>Python Version:</strong> {{ python_version }}</li>
                <li><strong>Platform:</strong> {{ platform }}</li>
                <li><strong>Container ID:</strong> {{ container_id }}</li>
                <li><strong>Current Time:</strong> {{ current_time }}</li>
                <li><strong>Environment:</strong> {{ environment }}</li>
            </ul>
        </div>

        <h3>How to run this example:</h3>
        <div class="code">
            # Build the image<br>
            docker build -t python-flask-app .<br><br>
            
            # Run the container<br>
            docker run -p 5000:5000 python-flask-app<br><br>
            
            # Access the application<br>
            # Open http://localhost:5000 in your browser
        </div>

        <div class="info">
            <h3>Docker Concepts Demonstrated:</h3>
            <ul>
                <li>Python application containerization</li>
                <li>Flask web framework in Docker</li>
                <li>Environment variable usage</li>
                <li>Port mapping and exposure</li>
                <li>Multi-stage builds (if applicable)</li>
            </ul>
        </div>

        <h3>API Endpoints:</h3>
        <ul>
            <li><a href="/">Home page (this page)</a></li>
            <li><a href="/health">Health check endpoint</a></li>
            <li><a href="/info">Container information</a></li>
        </ul>
    </div>
</body>
</html>
"""

@app.route('/')
def home():
    """Home page with container information"""
    return render_template_string(HTML_TEMPLATE,
                                python_version=platform.python_version(),
                                platform=platform.platform(),
                                container_id=os.environ.get('HOSTNAME', 'Unknown'),
                                current_time=datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                                environment=os.environ.get('ENVIRONMENT', 'development'))

@app.route('/health')
def health():
    """Health check endpoint"""
    return {
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat(),
        'service': 'python-flask-app'
    }

@app.route('/info')
def info():
    """Container information endpoint"""
    return {
        'python_version': platform.python_version(),
        'platform': platform.platform(),
        'container_id': os.environ.get('HOSTNAME', 'Unknown'),
        'environment': os.environ.get('ENVIRONMENT', 'development'),
        'timestamp': datetime.datetime.now().isoformat()
    }

if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 5000))
    
    # Run the application
    app.run(host='0.0.0.0', port=port, debug=False)
