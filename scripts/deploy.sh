#!/bin/bash

# Azure Serverless User Management - Deployment Script
# This script automates the deployment of the Azure Functions and infrastructure

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP_NAME="rg-userapp-demo"
LOCATION="westus2"
APP_NAME="userapp-$(date +%s)"

echo -e "${BLUE}🚀 Azure Serverless User Management Deployment Script${NC}"
echo -e "${BLUE}===================================================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    print_status "Azure CLI is installed"
}

# Check if logged in to Azure
check_azure_login() {
    if ! az account show &> /dev/null; then
        print_warning "Not logged in to Azure. Please login first."
        az login
    fi
    print_status "Azure CLI is authenticated"
}

# Check if Azure Functions Core Tools is installed
check_func_tools() {
    if ! command -v func &> /dev/null; then
        print_warning "Azure Functions Core Tools not found. Please install it."
        echo "Visit: https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local"
        read -p "Continue without Functions Core Tools? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_status "Azure Functions Core Tools is installed"
    fi
}

# Create resource group
create_resource_group() {
    print_info "Creating resource group: $RESOURCE_GROUP_NAME"
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --output table
    print_status "Resource group created"
}

# Deploy infrastructure using Bicep
deploy_infrastructure() {
    print_info "Deploying infrastructure using Bicep template..."
    DEPLOYMENT_OUTPUT=$(az deployment group create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file infrastructure/main.bicep \
        --parameters appName="$APP_NAME" environment=dev \
        --output json)
    
    # Extract outputs
    FUNCTION_APP_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.functionAppName.value')
    FUNCTION_APP_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.functionAppUrl.value')
    
    print_status "Infrastructure deployed successfully"
    print_info "Function App Name: $FUNCTION_APP_NAME"
    print_info "Function App URL: $FUNCTION_APP_URL"
    
    # Save outputs for later use
    echo "FUNCTION_APP_NAME=$FUNCTION_APP_NAME" > .deployment_outputs
    echo "FUNCTION_APP_URL=$FUNCTION_APP_URL" >> .deployment_outputs
}

# Deploy function app
deploy_function_app() {
    if [ -f .deployment_outputs ]; then
        source .deployment_outputs
    else
        print_error "Deployment outputs not found. Please run infrastructure deployment first."
        exit 1
    fi
    
    print_info "Deploying Function App: $FUNCTION_APP_NAME"
    
    # Build and deploy
    cd function_app
    
    # Install dependencies
    print_info "Installing Python dependencies..."
    pip install -r ../requirements.txt --target=".python_packages/lib/site-packages"
    
    # Deploy using func tools if available
    if command -v func &> /dev/null; then
        func azure functionapp publish "$FUNCTION_APP_NAME" --python
    else
        print_warning "Using zip deployment (Functions Core Tools not available)"
        # Create zip file
        zip -r ../deployment.zip . -x "*.pyc" "__pycache__/*"
        cd ..
        
        # Deploy zip file
        az functionapp deployment source config-zip \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --name "$FUNCTION_APP_NAME" \
            --src deployment.zip
        
        # Cleanup
        rm deployment.zip
    fi
    
    cd ..
    print_status "Function App deployed successfully"
}

# Test the deployed endpoints
test_endpoints() {
    if [ -f .deployment_outputs ]; then
        source .deployment_outputs
    else
        print_error "Deployment outputs not found."
        return 1
    fi
    
    print_info "Testing deployed endpoints..."
    
    # Wait for function app to be ready
    print_info "Waiting for Function App to be ready..."
    sleep 30
    
    # Test GET /users endpoint
    print_info "Testing GET $FUNCTION_APP_URL/api/users"
    if curl -s -f "$FUNCTION_APP_URL/api/users" > /dev/null; then
        print_status "GET /users endpoint is working"
    else
        print_warning "GET /users endpoint test failed"
    fi
    
    # Test POST /user endpoint
    print_info "Testing POST $FUNCTION_APP_URL/api/user"
    RESPONSE=$(curl -s -w "%{http_code}" -X POST "$FUNCTION_APP_URL/api/user" \
        -H "Content-Type: application/json" \
        -d '{"name": "Deployment Test", "email": "test@deployment.com"}')
    
    HTTP_CODE="${RESPONSE: -3}"
    if [ "$HTTP_CODE" = "201" ]; then
        print_status "POST /user endpoint is working"
    else
        print_warning "POST /user endpoint test failed (HTTP $HTTP_CODE)"
    fi
}

# Update frontend configuration
update_frontend() {
    if [ -f .deployment_outputs ]; then
        source .deployment_outputs
    else
        print_warning "Deployment outputs not found. Skipping frontend update."
        return 1
    fi
    
    print_info "Updating frontend configuration..."
    
    # Update the API URL in the frontend
    sed -i.bak "s|https://your-function-app.azurewebsites.net|$FUNCTION_APP_URL|g" frontend/index.html
    
    print_status "Frontend updated with API URL: $FUNCTION_APP_URL"
    print_info "You can now open frontend/index.html in your browser"
}

# Display deployment summary
show_summary() {
    if [ -f .deployment_outputs ]; then
        source .deployment_outputs
    else
        print_warning "Deployment outputs not found."
        return 1
    fi
    
    echo
    echo -e "${GREEN}🎉 Deployment Summary${NC}"
    echo -e "${GREEN}===================${NC}"
    echo -e "${BLUE}Resource Group:${NC} $RESOURCE_GROUP_NAME"
    echo -e "${BLUE}Function App:${NC} $FUNCTION_APP_NAME"
    echo -e "${BLUE}API Base URL:${NC} $FUNCTION_APP_URL"
    echo
    echo -e "${BLUE}API Endpoints:${NC}"
    echo -e "  POST $FUNCTION_APP_URL/api/user"
    echo -e "  GET  $FUNCTION_APP_URL/api/users"
    echo
    echo -e "${BLUE}Frontend:${NC} Open frontend/index.html in your browser"
    echo -e "${BLUE}Monitoring:${NC} Check Azure Portal for Application Insights"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Test the API endpoints using curl or Postman"
    echo "2. Open the frontend in your browser"
    echo "3. Check Application Insights for monitoring data"
    echo "4. Set up GitHub Actions by adding the required secrets"
    echo
}

# Cleanup function
cleanup() {
    print_info "Cleaning up temporary files..."
    rm -f .deployment_outputs
    print_status "Cleanup completed"
}

# Main deployment function
main() {
    echo -e "${BLUE}Starting deployment process...${NC}"
    echo
    
    # Pre-flight checks
    check_azure_cli
    check_azure_login
    check_func_tools
    
    # Deployment steps
    create_resource_group
    deploy_infrastructure
    deploy_function_app
    test_endpoints
    update_frontend
    show_summary
    
    print_status "Deployment completed successfully! 🎉"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "test")
        test_endpoints
        ;;
    "cleanup")
        cleanup
        print_info "To delete all Azure resources, run:"
        echo "az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait"
        ;;
    "help"|"--help"|"-h")
        echo "Usage: $0 [deploy|test|cleanup|help]"
        echo "  deploy  - Full deployment (default)"
        echo "  test    - Test deployed endpoints"
        echo "  cleanup - Clean up temporary files"
        echo "  help    - Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 