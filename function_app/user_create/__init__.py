import json
import logging
import azure.functions as func
import uuid
from datetime import datetime

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Azure Function to create a new user - simplified version
    POST /api/user
    """
    logger = logging.getLogger(__name__)
    logger.info("Processing user creation request")
    
    try:
        # Parse and validate request body
        try:
            req_body = req.get_json()
        except ValueError:
            logger.error("Invalid JSON in request body")
            return func.HttpResponse(
                json.dumps({"error": "Invalid JSON in request body"}),
                status_code=400,
                mimetype="application/json"
            )
        
        if not req_body:
            logger.error("Empty request body")
            return func.HttpResponse(
                json.dumps({"error": "Request body is required"}),
                status_code=400,
                mimetype="application/json"
            )
        
        # Validate required fields
        name = req_body.get('name', '').strip()
        email = req_body.get('email', '').strip()
        
        if not name:
            return func.HttpResponse(
                json.dumps({"error": "Name is required and cannot be empty"}),
                status_code=400,
                mimetype="application/json"
            )
        
        if not email:
            return func.HttpResponse(
                json.dumps({"error": "Email is required and cannot be empty"}),
                status_code=400,
                mimetype="application/json"
            )
        
        # Create mock user (not saving to database yet)
        user_id = str(uuid.uuid4())
        mock_user = {
            'id': user_id,
            'name': name,
            'email': email,
            'created_at': datetime.now().isoformat(),
            'status': 'mock_created'
        }
        
        logger.info(f"Successfully created mock user with ID: {user_id}")
        
        return func.HttpResponse(
            json.dumps(mock_user),
            status_code=201,
            mimetype="application/json",
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        )
        
    except Exception as e:
        logger.error(f"Unexpected error creating user: {str(e)}", exc_info=True)
        return func.HttpResponse(
            json.dumps({"error": "Internal server error occurred"}),
            status_code=500,
            mimetype="application/json"
        ) 