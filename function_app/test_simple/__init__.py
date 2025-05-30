import azure.functions as func
import json

def main(req: func.HttpRequest) -> func.HttpResponse:
    """Simple test function without external dependencies"""
    return func.HttpResponse(
        json.dumps({"message": "Hello from Azure Functions!", "status": "working"}),
        status_code=200,
        mimetype="application/json",
        headers={"Content-Type": "application/json"}
    ) 