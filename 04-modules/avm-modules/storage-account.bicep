// storage-account.bicep
// AVM-inspired Storage Account module

// Parameters
@description('Name of the storage account')
param name string

@description('Azure region for the storage account')
param location string

@description('Storage account SKU name')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param skuName string = 'Standard_LRS'

@description('Storage account kind')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param kind string = 'StorageV2'

@description('Default to OAuth authentication')
param defaultToOAuthAuthentication bool = true

@description('Allow access from all networks if true')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Allow blob public access')
param allowBlobPublicAccess bool = false

@description('Allow shared key access')
param allowSharedKeyAccess bool = true

@description('Require secure transfer (HTTPS)')
param supportsHttpsTrafficOnly bool = true

@description('Minimum TLS version')
param minimumTlsVersion string = 'TLS1_2'

@description('Storage account access tier')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

@description('Allow cross tenant replication')
param allowCrossTenantReplication bool = false

@description('Network ACLs for the storage account')
param networkAcls object = {
  defaultAction: 'Allow'
  bypass: 'AzureServices'
}

@description('Blob containers to create')
param blobContainers array = []

@description('Tags for the resource')
param tags object = {}

// Storage Account resource
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: {
    name: skuName
  }
  properties: {
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    publicNetworkAccess: publicNetworkAccess
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    minimumTlsVersion: minimumTlsVersion
    accessTier: accessTier
    allowCrossTenantReplication: allowCrossTenantReplication
    networkAcls: networkAcls
  }
}

// Create blob containers if specified
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for container in blobContainers: {
  name: container.name
  parent: blobServices
  properties: {
    publicAccess: contains(container, 'publicAccess') ? container.publicAccess : 'None'
    metadata: contains(container, 'metadata') ? container.metadata : {}
  }
}]

// Outputs
output name string = storageAccount.name
output resourceId string = storageAccount.id
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
