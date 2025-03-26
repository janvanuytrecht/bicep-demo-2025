// app-service-slots.bicep
// Example of App Service with Deployment Slots

@description('Base name for the app service')
param baseName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('App Service Plan tier')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
])
param appServicePlanSku string = 'S1'

@description('List of deployment slots to create')
param deploymentSlots array = [
  'staging'
  'test'
  'uat'
]

@description('Environment variables for the app service')
param appSettings array = [
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: '~16'
  }
  {
    name: 'ENVIRONMENT'
    value: 'production'
  }
]

// Variables for naming
var appServicePlanName = '${baseName}-plan'
var appServiceName = '${baseName}-app'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: false // false for Windows, true for Linux
  }
  tags: {
    purpose: 'bicep-demo'
  }
}

// App Service (parent resource)
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: appSettings
    }
  }
  tags: {
    purpose: 'bicep-demo'
    slot: 'production'
  }
}

// App Configuration as a child resource
resource appConfiguration 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appService
  name: 'web'  // 'web' is a fixed name for this resource type
  properties: {
    netFrameworkVersion: 'v6.0'
    phpVersion: 'off'
    pythonVersion: 'off'
    nodeVersion: '~16'
    http20Enabled: true
    alwaysOn: true
  }
}

// Deployment Slots (child resources using a loop)
resource deploymentSlot 'Microsoft.Web/sites/slots@2022-03-01' = [for slotName in deploymentSlots: {
  parent: appService
  name: slotName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: concat(
        appSettings,
        [
          {
            name: 'ENVIRONMENT'
            value: slotName
          }
        ]
      )
    }
  }
  tags: {
    purpose: 'bicep-demo'
    slot: slotName
  }
}]

// Auto-swap configuration for the staging slot (if it exists)
resource autoSwapConfig 'Microsoft.Web/sites/slots/config@2022-03-01' = if (contains(deploymentSlots, 'staging')) {
  parent: deploymentSlot[indexOf(deploymentSlots, 'staging')]
  name: 'web'
  properties: {
    autoSwapSlotName: 'production'
  }
}

// Outputs
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output deploymentSlotUrls array = [for (slot, i) in deploymentSlots: {
  name: slot
  url: 'https://${deploymentSlot[i].properties.defaultHostName}'
}]
