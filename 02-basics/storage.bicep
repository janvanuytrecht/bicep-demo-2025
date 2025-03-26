// File: storage.bicep
// Description: Basic storage account deployment

// Parameters - values that can be provided at deployment time
param storageAccountName string
param location string = resourceGroup().location
param sku string = 'Standard_LRS'

// Resource declaration
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Outputs - values returned after deployment
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
