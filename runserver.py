import os
import sys
import logging
from app import app

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

if __name__ == '__main__':
    try:
        # Log the current working directory and Python path
        logger.info(f"Current working directory: {os.getcwd()}")
        logger.info(f"Python path: {sys.path}")
        
        # Get the port from environment variable or use 8000 as default
        port = int(os.getenv('PORT', 8000))
        logger.info(f"Starting server on port {port}")
        
        # Run the app
        app.run(host='0.0.0.0', port=port)
    except Exception as e:
        logger.error(f"Error starting server: {str(e)}")
        logger.error(f"Error type: {type(e)}")
        logger.error(f"Error details: {sys.exc_info()}")
        raise 