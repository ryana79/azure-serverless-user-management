@description('The name of the application. This will be used as a prefix for all resources.')
param appName string = 'userapp'

@description('The location for all resources.')
param location string = resourceGroup().location

@description('The SKU for the Function App service plan.')
@allowed(['Y1', 'EP1', 'EP2', 'EP3'])
param functionAppSku string = 'Y1'

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

// Variables
var functionAppName = '${appName}-func-${environment}'
var storageAccountName = '${replace(appName, '-', '')}st${environment}'
var appInsightsName = '${appName}-insights-${environment}'
var cosmosAccountName = '${appName}-cosmos-${environment}'
var hostingPlanName = '${appName}-plan-${environment}'

// Storage Account for Function App
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Log Analytics Workspace for Application Insights
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${appName}-logs-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Cosmos DB Account
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
        backupStorageRedundancy: 'Local'
      }
    }
  }
}

// Cosmos DB Database
resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  parent: cosmosAccount
  name: 'users-db'
  properties: {
    resource: {
      id: 'users-db'
    }
  }
}

// Cosmos DB Container
resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDatabase
  name: 'users'
  properties: {
    resource: {
      id: 'users'
      partitionKey: {
        paths: ['/partitionKey']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
}

// App Service Plan for Function App (Consumption Plan)
resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: functionAppSku
    tier: functionAppSku == 'Y1' ? 'Dynamic' : 'ElasticPremium'
  }
  properties: {
    reserved: true // Required for Linux
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    reserved: true
    isXenon: false
    hyperV: false
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'COSMOS_DB_CONNECTION_STRING'
          value: cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString
        }
        {
          name: 'COSMOS_DB_DATABASE_NAME'
          value: 'users-db'
        }
        {
          name: 'COSMOS_DB_CONTAINER_NAME'
          value: 'users'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
          '*' // Allow all origins for development - restrict in production
        ]
        supportCredentials: false
      }
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
    redundancyMode: 'None'
  }
}

// Outputs
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output cosmosAccountName string = cosmosAccount.name
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint
output appInsightsName string = appInsights.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output resourceGroupName string = resourceGroup().name 
