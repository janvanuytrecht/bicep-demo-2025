// rg-scope.bicep
// This is a resource group scoped Bicep file (default)

// Parameters with default values
@description('Azure region to deploy resources')
param location string = resourceGroup().location

@description('Environment tag value')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

// Variables
var tags = {
  Environment: environment
  DeployedBy: 'Bicep'
}

// Storage Account at resource group scope
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'storage${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

// Key Vault at resource group scope
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'kv-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableRbacAuthorization: true
  }
}

// Outputs
output storageAccountId string = storage.id
output keyVaultId string = keyVault.id
