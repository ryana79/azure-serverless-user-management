from flask import Flask, jsonify
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/')
def home():
    """
    Home route that returns a welcome message
    """
    logger.info("Home route accessed")
    return 'Welcome to the Flask Azure DevOps Demo!'

@app.route('/api/status')
def status():
    """
    API route that returns the application status
    """
    logger.info("Status route accessed")
    return jsonify({
        'status': 'healthy',
        'version': '1.0.0',
        'environment': os.getenv('FLASK_ENV', 'development')
    })

if __name__ == '__main__':
    try:
        # Azure App Service expects the app to listen on port 8000
        port = int(os.getenv('PORT', 8000))
        logger.info(f"Starting server on port {port}")
        app.run(host='0.0.0.0', port=port)
    except Exception as e:
        logger.error(f"Error starting server: {str(e)}")
        raise 