// storage-containers.bicep
// Example of Storage Account with Blob Containers using parent/child relationships

@description('Base name for the storage account')
param baseName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Array of container names to create')
param containerNames array = [
  'images'
  'documents'
  'backups'
  'data'
]

// Ensure globally unique storage account name
var storageAccountName = 'st${replace(baseName, '-', '')}${uniqueString(resourceGroup().id)}'

// Method 1: Parent property approach - Clean and recommended way
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

// Blob service as a child resource
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Containers as child resources using a loop
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for containerName in containerNames: {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
    metadata: {
      createdBy: 'Bicep'
      purpose: containerName
    }
  }
}]

// Method 2: Alternative approach with fully qualified names (more verbose, less preferred)
resource alternativeContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccount.name}/default/extra-container'
  properties: {
    publicAccess: 'None'
  }
}

// Method 3: Child resources within parent (nested resources)
resource anotherStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: '${storageAccountName}alt'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }

  // Nested child resource
  resource nestedBlobService 'blobServices' = {
    name: 'default'

    // Nested grandchild resource
    resource nestedContainer 'containers' = {
      name: 'nested-container'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output containerNames array = [for (containerName, i) in containerNames: containers[i].name]
output nestedContainerName string = anotherStorageAccount::nestedBlobService::nestedContainer.name
