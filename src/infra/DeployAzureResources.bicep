@minLength(1)
@description('Primary location for all resources.')
param location string = resourceGroup().location

var cosmosDbName = '${uniqueString(resourceGroup().id)}-cosmosdb'
var cosmosDbDatabaseName = 'zava'
var storageAccountName = '${uniqueString(resourceGroup().id)}sa'
var aiFoundryName = 'aif-${uniqueString(resourceGroup().id)}'
var aiProjectName = 'proj-${uniqueString(resourceGroup().id)}'
var searchServiceName = '${uniqueString(resourceGroup().id)}-search'
var webAppName = '${uniqueString(resourceGroup().id)}-app'
var appServicePlanName = '${uniqueString(resourceGroup().id)}-cosu-asp'
var logAnalyticsName = '${uniqueString(resourceGroup().id)}-cosu-la'
var appInsightsName = '${uniqueString(resourceGroup().id)}-cosu-ai'
var webAppSku = 'S1'
var registryName = '${uniqueString(resourceGroup().id)}cosureg'
var registrySku = 'Standard'

// =============================================================================
// AZURE VERIFIED MODULES (AVM) MIGRATION
// =============================================================================
// This Bicep template has been updated to leverage Azure Verified Modules (AVM)
// from the public Bicep registry wherever possible. AVM provides enterprise-grade,
// pre-validated, and maintained Bicep modules following Microsoft best practices.
//
// Resources migrated to AVM:
// - Cosmos DB (avm/res/document-db/database-account)
// - Storage Account (avm/res/storage/storage-account)
// - AI Search Service (avm/res/search/search-service)
// - Log Analytics Workspace (avm/res/operational-insights/workspace)
// - Application Insights (avm/res/insights/component)
// - Container Registry (avm/res/container-registry/registry)
// - App Service Plan (avm/res/web/serverfarm)
// - App Service (avm/res/web/site)
//
// Resources kept as native Bicep:
// - AI Foundry / Cognitive Services (no stable AVM module available yet)
//
// Benefits of using AVM:
// - Enterprise-ready: Follows Microsoft best practices and design patterns
// - Well-tested: Modules are thoroughly tested and validated
// - Maintained: Regular updates and security patches from Microsoft
// - Consistent: Standardized parameters and outputs across modules
// - Feature-rich: Built-in support for diagnostic settings, RBAC, and more
//
// Learn more: https://aka.ms/avm
// =============================================================================


@description('Creates an Azure Cosmos DB NoSQL account using AVM.')
module cosmosDb 'br/public:avm/res/document-db/database-account:0.9.0' = {
  name: '${uniqueString(deployment().name, location)}-cosmosdb'
  params: {
    name: cosmosDbName
    location: location
    sqlDatabases: [
      {
        name: cosmosDbDatabaseName
      }
    ]
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
    disableLocalAuth: false
  }
}

@description('Creates an Azure Storage account using AVM.')
module storageAccount 'br/public:avm/res/storage/storage-account:0.14.3' = {
  name: '${uniqueString(deployment().name, location)}-storage'
  params: {
    name: storageAccountName
    location: location
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    accessTier: 'Hot'
  }
}

resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: aiFoundryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    // required to work in AI Foundry
    allowProjectManagement: true 

    // Defines developer API endpoint subdomain
    customSubDomainName: aiFoundryName

    disableLocalAuth: false
  }
}

/*
  Developer APIs are exposed via a project, which groups in- and outputs that relate to one use case, including files.
  Its advisable to create one project right away, so development teams can directly get started.
  Projects may be granted individual RBAC permissions and identities on top of what account provides.
*/ 
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  name: aiProjectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

@description('Creates an Azure AI Search service using AVM.')
module searchService 'br/public:avm/res/search/search-service:0.9.0' = {
  name: '${uniqueString(deployment().name, location)}-search'
  params: {
    name: searchServiceName
    location: location
    sku: 'standard'
  }
}

@description('Creates an Azure Log Analytics workspace using AVM.')
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: '${uniqueString(deployment().name, location)}-loganalytics'
  params: {
    name: logAnalyticsName
    location: location
    skuName: 'PerGB2018'
    dataRetention: 90
    dailyQuotaGb: 1
  }
}

@description('Creates an Azure Application Insights resource using AVM.')
module appInsights 'br/public:avm/res/insights/component:0.5.0' = {
  name: '${uniqueString(deployment().name, location)}-appinsights'
  params: {
    name: appInsightsName
    location: location
    kind: 'web'
    applicationType: 'web'
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
  }
}

@description('Creates an Azure Container Registry using AVM.')
module containerRegistry 'br/public:avm/res/container-registry/registry:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-acr'
  params: {
    name: registryName
    location: location
    acrSku: registrySku
    acrAdminUserEnabled: true
  }
}

@description('Creates an Azure App Service Plan using AVM.')
module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.0' = {
  name: '${uniqueString(deployment().name, location)}-asp'
  params: {
    name: appServicePlanName
    location: location
    kind: 'linux'
    reserved: true
    skuName: webAppSku
  }
}

@description('Creates an Azure App Service for Zava using AVM.')
module appServiceApp 'br/public:avm/res/web/site:0.12.0' = {
  name: '${uniqueString(deployment().name, location)}-webapp'
  params: {
    name: webAppName
    location: location
    kind: 'app,linux,container'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistry.outputs.name}.azurecr.io/${uniqueString(resourceGroup().id)}/techworkshopl300/zava'
      http20Enabled: true
      minTlsVersion: '1.2'
      appCommandLine: ''
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.outputs.name}.azurecr.io'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistry.outputs.name
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistry.outputs.loginServer
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.outputs.instrumentationKey
        }
      ]
    }
  }
}

output cosmosDbEndpoint string = cosmosDb.outputs.endpoint
output storageAccountName string = storageAccount.outputs.name
output searchServiceName string = searchService.outputs.name
output container_registry_name string = containerRegistry.outputs.name
output application_name string = appServiceApp.outputs.name
output application_url string = appServiceApp.outputs.defaultHostname

