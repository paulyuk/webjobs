metadata description = 'Creates an Azure App Service in an existing Azure App Service plan.'
param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param applicationInsightsName string = ''
param appServicePlanId string
param keyVaultName string = ''
param managedIdentity bool = !empty(keyVaultName)
param storageAccountName string

// Microsoft.Web/sites Properties
param kind string = 'app'

// Microsoft.Web/sites/config
param allowedOrigins array = []
param alwaysOn bool = true
param appCommandLine string = ''
@secure()
param appSettings object = {}
param clientAffinityEnabled bool = false
param enableOryxBuild bool = contains(kind, 'linux')
param netFrameworkVersion string
param numberOfWorkers int = -1
param scmDoBuildDuringDeployment bool = false
param use32BitWorkerProcess bool = false
param ftpsState string = 'FtpsOnly'
param healthCheckPath string = ''

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      netFrameworkVersion: netFrameworkVersion
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      minTlsVersion: '1.2'
      appCommandLine: appCommandLine
      numberOfWorkers: numberOfWorkers != -1 ? numberOfWorkers : null
      use32BitWorkerProcess: use32BitWorkerProcess
      healthCheckPath: healthCheckPath
      cors: {
        allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
      }
    }
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: true
    
  }

  identity: { type: managedIdentity ? 'SystemAssigned' : 'None' }

  resource basicPublishingCredentialsPoliciesFtp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }

  resource basicPublishingCredentialsPoliciesScm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }
}

// Updates to the single Microsoft.sites/web/config resources that need to be performed sequentially
// sites/web/config 'appsettings'
module configAppSettings 'appservice-appsettings.bicep' = {
  name: '${name}-appSettings'
  params: {
    name: appService.name
    appSettings: union(appSettings,
      {
        SCM_DO_BUILD_DURING_DEPLOYMENT: string(scmDoBuildDuringDeployment)
        ENABLE_ORYX_BUILD: string(enableOryxBuild)
        AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        AzureWebJobsDashboard: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
      },
      !empty(applicationInsightsName) ? { APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString } : {},
      !empty(keyVaultName) ? { AZURE_KEY_VAULT_ENDPOINT: keyVault.properties.vaultUri } : {})
  }
}

// sites/web/config 'logs'
resource configLogs 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'logs'
  parent: appService
  properties: {
    applicationLogs: { fileSystem: { level: 'Verbose' } }
    detailedErrorMessages: { enabled: true }
    failedRequestsTracing: { enabled: true }
    httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
  }
  dependsOn: [configAppSettings]
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!(empty(keyVaultName))) {
  name: keyVaultName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsightsName)) {
  name: applicationInsightsName
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

output identityPrincipalId string = managedIdentity ? appService.identity.principalId : ''
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
