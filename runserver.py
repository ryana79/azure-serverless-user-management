import os
import logging
from app import app

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

if __name__ == '__main__':
    try:
        # Get the port from environment variable or use 8000 as default
        port = int(os.getenv('PORT', 8000))
        logger.info(f"Starting server on port {port}")
        app.run(host='0.0.0.0', port=port)
    except Exception as e:
        logger.error(f"Error starting server: {str(e)}")
        raise 