// File: storage-with-variables.bicep
// Description: Storage account with variables

param baseName string
param location string = resourceGroup().location

// Variables - reusable values within the template
var storageName = '${baseName}${uniqueString(resourceGroup().id)}'
var storageSkuName = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: location
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

output storageAccountId string = storageAccount.id
