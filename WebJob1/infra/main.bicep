targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param apiServiceName string = ''
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param appServicePlanName string = ''
param keyVaultName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''
param storageAccountName string = ''

@description('Flag to use Azure API Management to mediate the calls between the Web frontend and the backend API')
param useAPIM bool = false

@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// The application backend
module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: !empty(apiServiceName) ? apiServiceName : '${abbrs.webSitesAppService}api-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    appSettings: {
    }
    storageAccountName: storage.outputs.name
  }
}

// Give the API access to KeyVault
module apiKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    kind: 'app'
    reserved: false // Set to false to get a Windows OS plan
    sku: {
      name: 's1'
      tier: 'Standard'
      size: 'S1'
      family: 'S'
      capacity: 1
    }
  }
}

// Backing storage for Azure functions backend API
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
    containers: [{name: 'deploymentpackage'}]
  }
}

var blobStorageRoleDefinitionId  = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor role
var queueReaderRoleDefinitionId  = '19e7f393-937e-4f77-808e-94535e297925' // Storage Queue Data Reader role
var queueProcessorRoleDefinitionId  = '8a0f0c08-91a1-4084-bc3d-661d67233fed' // Storage Queue Data Message Processor role

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
  scope: rg
}

// Allow access from API to storage account using a managed identity and least priv Storage roles
module blobStorageRoleAssignment './app/storage-access.bicep' = {
  name: 'blobStorageRoleAssignment'
  scope: rg
  params: {
    storageAccountID: storageAccount.id
    roleDefinitionID: blobStorageRoleDefinitionId
    principalID: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
  }
}

// Allow access from API to storage account using a managed identity and least priv Storage roles
module queueReaderRoleAssignment './app/storage-access.bicep' = {
  name: 'queueReaderRoleAssignment'
  scope: rg
  params: {
    storageAccountID: storageAccount.id
    roleDefinitionID: queueReaderRoleDefinitionId
    principalID: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
  }
}

// Allow access from API to storage account using a managed identity and least priv Storage roles
module queueProcessorRoleAssignment './app/storage-access.bicep' = {
  name: 'queueProcessorRoleAssignment'
  scope: rg
  params: {
    storageAccountID: storageAccount.id
    roleDefinitionID: queueProcessorRoleDefinitionId
    principalID: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
  }
}

resource appService 'Microsoft.Web/sites@2020-06-01' existing = {
  name: api.name
  scope: rg
}

// Store secrets in a keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output USE_APIM bool = useAPIM
