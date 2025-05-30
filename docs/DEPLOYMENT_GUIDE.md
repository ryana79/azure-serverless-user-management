# Deployment Guide

This guide provides detailed instructions for deploying the Azure Serverless User Management system using different methods.

## Prerequisites

Before starting the deployment, ensure you have the following tools installed:

### Required Tools
- **Azure CLI**: [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Python 3.11+**: [Download Python](https://www.python.org/downloads/)
- **Git**: [Install Git](https://git-scm.com/downloads)

### Optional Tools
- **Azure Functions Core Tools v4**: [Install Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- **Visual Studio Code**: [Download VS Code](https://code.visualstudio.com/)
- **Azure Functions Extension for VS Code**: [Install Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefunctions)

## Method 1: Automated Deployment (Recommended)

The quickest way to deploy the entire solution:

### Step 1: Login to Azure
```bash
az login
```

### Step 2: Run the Deployment Script
```bash
./scripts/deploy.sh
```

This script will:
- Create a resource group
- Deploy infrastructure using Bicep
- Deploy the Function App
- Test the endpoints
- Update the frontend configuration
- Display a deployment summary

### Step 3: Verify Deployment
The script will automatically test the endpoints and provide you with the API URLs.

## Method 2: Manual Deployment with Azure CLI

### Step 1: Create Resource Group
```bash
RESOURCE_GROUP="rg-userapp-demo"
LOCATION="eastus"
APP_NAME="userapp-$(date +%s)"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 2: Deploy Infrastructure
```bash
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infrastructure/main.bicep \
  --parameters appName=$APP_NAME environment=dev
```

### Step 3: Get Function App Name
```bash
FUNCTION_APP_NAME=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query "properties.outputs.functionAppName.value" \
  --output tsv)
```

### Step 4: Deploy Function App
```bash
cd function_app
pip install -r ../requirements.txt --target=".python_packages/lib/site-packages"
func azure functionapp publish $FUNCTION_APP_NAME --python
cd ..
```

## Method 3: GitHub Actions Deployment

### Step 1: Fork the Repository
Fork this repository to your GitHub account.

### Step 2: Set up Azure Service Principal
```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

### Step 3: Configure GitHub Secrets
Add the following secrets to your GitHub repository:

| Secret Name | Description | Value |
|-------------|-------------|-------|
| `AZURE_CREDENTIALS` | Service principal JSON | Output from step 2 |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID | `az account show --query id --output tsv` |
| `AZURE_RESOURCE_GROUP` | Resource group name | `rg-userapp-demo` |
| `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` | Function App publish profile | Download from Azure Portal |

### Step 4: Trigger Deployment
Push to the `main` branch or manually trigger the workflow in GitHub Actions.

## Method 4: Visual Studio Code Deployment

### Step 1: Install Required Extensions
- Azure Functions Extension
- Azure Account Extension

### Step 2: Sign in to Azure
1. Open Command Palette (`Ctrl+Shift+P`)
2. Run "Azure: Sign In"

### Step 3: Deploy Infrastructure
Run the Bicep deployment manually using Azure CLI:
```bash
az group create --name rg-userapp-demo --location eastus
az deployment group create \
  --resource-group rg-userapp-demo \
  --template-file infrastructure/main.bicep \
  --parameters appName=userapp-vscode environment=dev
```

### Step 4: Deploy Function App
1. Open the `function_app` folder in VS Code
2. Press `F1` and select "Azure Functions: Deploy to Function App"
3. Choose your subscription and Function App
4. Confirm the deployment

## Post-Deployment Configuration

### Update Frontend Configuration
After deployment, update the API URL in the frontend:

1. Open `frontend/index.html`
2. Replace `https://your-function-app.azurewebsites.net` with your actual Function App URL
3. Save the file

### Test the API Endpoints
```bash
# Test GET endpoint
curl https://your-function-app.azurewebsites.net/api/users

# Test POST endpoint
curl -X POST https://your-function-app.azurewebsites.net/api/user \
  -H "Content-Type: application/json" \
  -d '{"name": "Test User", "email": "test@example.com"}'
```

## Monitoring and Troubleshooting

### Application Insights
Monitor your application using Application Insights:
1. Go to Azure Portal
2. Navigate to your Function App
3. Click on "Application Insights"
4. View logs, metrics, and performance data

### Viewing Logs
```bash
# Stream logs in real-time
az webapp log tail --name your-function-app-name --resource-group rg-userapp-demo

# Download logs
az webapp log download --name your-function-app-name --resource-group rg-userapp-demo
```

### Common Issues

#### Issue: Function App not responding
**Solution**: Check the deployment logs and ensure all environment variables are set correctly.

#### Issue: Cosmos DB connection errors
**Solution**: Verify the connection string in the Function App configuration.

#### Issue: CORS errors in frontend
**Solution**: Check the CORS settings in the Function App configuration.

## Cost Management

### Free Tier Limits
This project is designed to stay within Azure's free tier:
- **Azure Functions**: 1M requests/month
- **Cosmos DB**: 1000 RU/s + 25GB storage
- **Application Insights**: 5GB data/month
- **Storage Account**: 5GB LRS storage

### Monitoring Costs
Use Azure Cost Management to monitor your spending:
```bash
az consumption usage list --billing-period-name current
```

## Cleanup

### Delete All Resources
```bash
az group delete --name rg-userapp-demo --yes --no-wait
```

### Cleanup Script
```bash
./scripts/deploy.sh cleanup
```

## Security Considerations

### Production Deployment
For production deployments:
1. Enable authentication on the Function App
2. Restrict CORS to specific domains
3. Use Azure Key Vault for secrets
4. Enable SSL/TLS encryption
5. Implement proper logging and monitoring

### Network Security
Consider implementing:
- Virtual Network integration
- Private endpoints for Cosmos DB
- Azure Front Door for global distribution

## Support

If you encounter issues:
1. Check the [troubleshooting section](#monitoring-and-troubleshooting)
2. Review Azure Function logs
3. Check Application Insights for errors
4. Open an issue in the GitHub repository

---

**Next Steps**: After successful deployment, explore the [API documentation](../README.md#api-reference) and try the [frontend interface](../frontend/index.html). 