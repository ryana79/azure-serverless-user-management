#!/bin/bash

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the Flask application
gunicorn --bind=0.0.0.0:8000 --timeout 600 app:app 