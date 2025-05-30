import json
import logging
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Azure Function to retrieve all users - simplified version
    GET /api/users
    """
    logger = logging.getLogger(__name__)
    logger.info("Processing get all users request")
    
    try:
        # Return mock data for now to test if function works
        mock_users = [
            {"id": "1", "name": "Test User 1", "email": "test1@example.com"},
            {"id": "2", "name": "Test User 2", "email": "test2@example.com"}
        ]
        
        logger.info(f"Successfully retrieved {len(mock_users)} mock users")
        
        return func.HttpResponse(
            json.dumps(mock_users),
            status_code=200,
            mimetype="application/json",
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        )
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return func.HttpResponse(
            json.dumps({"error": "Internal server error occurred"}),
            status_code=500,
            mimetype="application/json"
        ) 