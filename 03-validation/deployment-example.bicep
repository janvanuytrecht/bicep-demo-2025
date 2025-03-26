// Deployment example file for validation and deployment exercises

// Parameters with constraints and documentation
@description('Name of the storage account (must be globally unique)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for the resources')
param location string = resourceGroup().location

@description('The SKU for the storage account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageSku string = 'Standard_LRS'

@description('Enable blob versioning')
param enableVersioning bool = false

@description('Environment tag')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

// Variables
var storageAccountTags = {
  Environment: environment
  Project: 'BicepDemo'
  DeploymentType: 'Bicep'
}

// Resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: storageAccountTags
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

// Create blob service under the storage account
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

// Create a container
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  parent: blobService
  name: 'content'
  properties: {
    publicAccess: 'None'
  }
}

// Outputs
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
