import os
import logging
import uuid
from datetime import datetime, timezone
from azure.cosmos import CosmosClient, PartitionKey, exceptions
from azure.identity import DefaultAzureCredential
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)

class CosmosDBService:
    """Service class for interacting with Azure Cosmos DB"""
    
    def __init__(self):
        self.connection_string = os.getenv('COSMOS_DB_CONNECTION_STRING')
        self.database_name = os.getenv('COSMOS_DB_DATABASE_NAME', 'users-db')
        self.container_name = os.getenv('COSMOS_DB_CONTAINER_NAME', 'users')
        
        if not self.connection_string:
            raise ValueError("COSMOS_DB_CONNECTION_STRING environment variable is required")
        
        try:
            self.client = CosmosClient.from_connection_string(self.connection_string)
            self.database = self.client.get_database_client(self.database_name)
            self.container = self.database.get_container_client(self.container_name)
            logger.info(f"Successfully connected to Cosmos DB: {self.database_name}/{self.container_name}")
        except Exception as e:
            logger.error(f"Failed to connect to Cosmos DB: {str(e)}")
            raise
    
    def create_user(self, name: str, email: str) -> Dict:
        """Create a new user in the database"""
        try:
            user_id = str(uuid.uuid4())
            user_data = {
                'id': user_id,
                'name': name,
                'email': email,
                'created_at': datetime.now(timezone.utc).isoformat(),
                'partitionKey': user_id  # Using id as partition key for simplicity
            }
            
            # Insert the user into Cosmos DB
            created_user = self.container.create_item(body=user_data)
            logger.info(f"Successfully created user with ID: {user_id}")
            
            # Remove internal fields before returning
            response_user = {k: v for k, v in created_user.items() 
                           if k not in ['_rid', '_self', '_etag', '_attachments', '_ts', 'partitionKey']}
            
            return response_user
            
        except exceptions.CosmosResourceExistsError:
            logger.error(f"User with ID {user_id} already exists")
            raise ValueError("User already exists")
        except Exception as e:
            logger.error(f"Error creating user: {str(e)}")
            raise
    
    def get_all_users(self) -> List[Dict]:
        """Retrieve all users from the database"""
        try:
            # Query all items in the container
            items = list(self.container.read_all_items())
            
            # Clean up the response by removing internal fields
            users = []
            for item in items:
                user = {k: v for k, v in item.items() 
                       if k not in ['_rid', '_self', '_etag', '_attachments', '_ts', 'partitionKey']}
                users.append(user)
            
            logger.info(f"Successfully retrieved {len(users)} users")
            return users
            
        except Exception as e:
            logger.error(f"Error retrieving users: {str(e)}")
            raise
    
    def get_user_by_id(self, user_id: str) -> Optional[Dict]:
        """Retrieve a specific user by ID"""
        try:
            item = self.container.read_item(item=user_id, partition_key=user_id)
            
            # Clean up the response
            user = {k: v for k, v in item.items() 
                   if k not in ['_rid', '_self', '_etag', '_attachments', '_ts', 'partitionKey']}
            
            logger.info(f"Successfully retrieved user with ID: {user_id}")
            return user
            
        except exceptions.CosmosResourceNotFoundError:
            logger.warning(f"User with ID {user_id} not found")
            return None
        except Exception as e:
            logger.error(f"Error retrieving user {user_id}: {str(e)}")
            raise

# Global instance
_cosmos_service = None

def get_cosmos_service() -> CosmosDBService:
    """Get or create a singleton instance of CosmosDBService"""
    global _cosmos_service
    if _cosmos_service is None:
        _cosmos_service = CosmosDBService()
    return _cosmos_service 