#!/bin/bash

# Create and activate virtual environment
python -m venv env
source env/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the application
gunicorn --bind=0.0.0.0:8000 app:app 