// storage-module.bicep
// Reusable storage account module

// Module input parameters
@description('Name of the storage account (must be globally unique)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for the storage account')
param location string

@description('Storage account SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param sku string = 'Standard_LRS'

@description('Resource tags')
param tags object = {}

@description('Set to true to enable blob versioning')
param enableVersioning bool = false

@description('Array of container names to create')
param containerNames array = []

// Resource declaration
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

// Create blob service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    isVersioningEnabled: enableVersioning
  }
}

// Create containers if specified
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for containerName in containerNames: {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}]

// Module outputs
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output containerNames array = [for (containerName, i) in containerNames: containers[i].name]
