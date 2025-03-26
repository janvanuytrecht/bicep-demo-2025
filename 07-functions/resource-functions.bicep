// resource-functions.bicep
// Demonstrates resource-related functions in Bicep

// Input parameters
@description('Base name for resources')
param baseName string = 'demo'

@description('Azure region for resources')
param location string = resourceGroup().location

// Deployment context functions
var deploymentInfo = {
  // Get information about the current deployment
  resourceGroupName: resourceGroup().name
  resourceGroupLocation: resourceGroup().location
  resourceGroupId: resourceGroup().id

  // Get subscription information
  subscriptionId: subscription().subscriptionId
  subscriptionDisplayName: subscription().displayName

  // Get tenant information
  tenantId: tenant().tenantId
}

// Resource ID generation
var resourceIds = {
  // Generate resource ID for a storage account in the current resource group
  storageAccountId: resourceId('Microsoft.Storage/storageAccounts', '${baseName}storage')

  // Generate resource ID for a resource in a different resource group
  vmInDifferentRg: resourceId('otherResourceGroup', 'Microsoft.Compute/virtualMachines', '${baseName}-vm')

  // Generate resource ID for a resource in a different subscription
  vnetInOtherSub: resourceId('00000000-0000-0000-0000-000000000000', 'networkRG', 'Microsoft.Network/virtualNetworks', 'vnet1')

  // Generate a subscription-level resource ID
  policyId: subscriptionResourceId('Microsoft.Authorization/policyDefinitions', 'policyName')

  // Create a unique value based on the resource group ID (useful for unique names)
  uniqueName: uniqueString(resourceGroup().id)

  // Create a more targeted unique value
  specificUniqueName: uniqueString(resourceGroup().id, baseName, 'storage')
}

// Deploy a storage account using resource functions
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'st${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

// Reference an existing resource that's already deployed
resource existingKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: 'kv-${resourceGroup().name}'
  scope: resourceGroup()
}

// Using reference and list functions
var storageEndpoint = storageAccount.properties.primaryEndpoints.blob
var storageKeys = listKeys(storageAccount.id, storageAccount.apiVersion)
var storageAccountPrimaryKey = storageKeys.keys[0].value

// Outputs to review function results
output deploymentContext object = deploymentInfo
output generatedResourceIds object = resourceIds
output storageAccountName string = storageAccount.name
output storageAccountBlobEndpoint string = storageEndpoint
