from flask import Flask, jsonify, request
import os
from datetime import datetime

app = Flask(__name__)

# Configuration
app.config['JSON_SORT_KEYS'] = False

@app.route('/')
def home():
    """Home endpoint"""
    return jsonify({
        'message': 'Welcome to Flask Demo Application',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat(),
        'endpoints': {
            'home': '/',
            'health': '/health',
            'info': '/info',
            'echo': '/echo',
            'greet': '/greet/<name>'
        }
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }), 200

@app.route('/info')
def info():
    """Application information"""
    return jsonify({
        'application': 'Flask Demo',
        'version': '1.0.0',
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'python_version': os.sys.version,
        'flask_version': Flask.__version__
    })

@app.route('/echo', methods=['GET', 'POST'])
def echo():
    """Echo endpoint - returns request data"""
    if request.method == 'POST':
        data = request.get_json() or {}
        return jsonify({
            'method': 'POST',
            'received': data,
            'timestamp': datetime.utcnow().isoformat()
        })
    else:
        return jsonify({
            'method': 'GET',
            'query_params': dict(request.args),
            'timestamp': datetime.utcnow().isoformat()
        })

@app.route('/greet/<name>')
def greet(name):
    """Greet endpoint with path parameter"""
    return jsonify({
        'greeting': f'Hello, {name}!',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested endpoint does not exist',
        'status': 404
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred',
        'status': 500
    }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'False').lower() == 'true'
    
    print(f'Starting Flask application on port {port}')
    print(f'Debug mode: {debug}')
    print(f'Environment: {os.getenv("ENVIRONMENT", "development")}')
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug
    )

