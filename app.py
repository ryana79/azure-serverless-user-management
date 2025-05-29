from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    """
    Home route that returns a welcome message
    """
    return 'Welcome to the Flask Azure DevOps Demo!'

@app.route('/api/status')
def status():
    """
    API route that returns the application status
    """
    return jsonify({
        'status': 'healthy',
        'version': '1.0.0',
        'environment': os.getenv('FLASK_ENV', 'development')
    })

if __name__ == '__main__':
    # Get port from environment variable or default to 5000
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port) 