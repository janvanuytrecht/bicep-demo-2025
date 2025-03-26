// avm-example.bicep
// Example of using Azure Verified Modules (AVM) in Bicep

// Parameters for deployment
@description('The Azure region to deploy resources')
param location string = resourceGroup().location

@description('The environment name')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@minLength(1)
@maxLength(24)
@description('The name of the key vault. Must be globally unique.')
param keyVaultName string = 'kv-avm-${uniqueString(resourceGroup().id)}'

@description('The storage account name. Must be globally unique.')
@minLength(3)
@maxLength(24)
param storageAccountName string = 'stavmavm${uniqueString(resourceGroup().id)}'

@description('The network security group name')
param networkSecurityGroupName string = 'nsg-avm-${environment}'

@description('The virtual network name')
param virtualNetworkName string = 'vnet-avm-${environment}'

@description('CIDR range for the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

// Tags to apply to all resources
var tags = {
  environment: environment
  deploymentType: 'AVM'
  costCenter: '123456'
}

// ============================================================================
// Azure Verified Modules Examples
// ============================================================================

// Using local modules to simulate AVM modules for the example
// In a real scenario, you would use Azure Verified Modules from the public registry
// Example: module keyVault 'br/public:avm/res/key-vault/vault:0.4.0' = { ... }

// Key Vault module
// Based on AVM specifications
module keyVaultModule 'avm-modules/key-vault.bicep' = {
  name: 'avm-keyvault-deployment'
  params: {
    name: keyVaultName
    location: location
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    tags: tags
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// Storage Account module
// Based on AVM specifications
module storageAccountModule 'avm-modules/storage-account.bicep' = {
  name: 'avm-storage-deployment'
  params: {
    name: storageAccountName
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    tags: tags
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Enabled'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
    allowCrossTenantReplication: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    blobContainers: [
      {
        name: 'data'
        publicAccess: 'None'
      }
      {
        name: 'logs'
        publicAccess: 'None'
      }
    ]
  }
}

// Network Security Group module
// Based on AVM specifications
module networkSecurityGroupModule 'avm-modules/network-security-group.bicep' = {
  name: 'avm-nsg-deployment'
  params: {
    name: networkSecurityGroupName
    location: location
    tags: tags
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          description: 'Allow HTTPS inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Virtual Network module
// Based on AVM specifications
module virtualNetworkModule 'avm-modules/virtual-network.bicep' = {
  name: 'avm-vnet-deployment'
  params: {
    name: virtualNetworkName
    location: location
    tags: tags
    addressPrefixes: [
      vnetAddressPrefix
    ]
    subnets: [
      {
        name: 'subnet-app'
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroupId: networkSecurityGroupModule.outputs.resourceId
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
      {
        name: 'subnet-data'
        addressPrefix: '10.0.1.0/24'
        networkSecurityGroupId: networkSecurityGroupModule.outputs.resourceId
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
  }
}

// Outputs from the deployment
output keyVaultName string = keyVaultModule.outputs.name
output keyVaultResourceId string = keyVaultModule.outputs.resourceId
output keyVaultUri string = keyVaultModule.outputs.uri

output storageAccountName string = storageAccountModule.outputs.name
output storageAccountResourceId string = storageAccountModule.outputs.resourceId
output storageAccountPrimaryEndpoints object = storageAccountModule.outputs.primaryEndpoints

output networkSecurityGroupName string = networkSecurityGroupModule.outputs.name
output networkSecurityGroupResourceId string = networkSecurityGroupModule.outputs.resourceId

output virtualNetworkName string = virtualNetworkModule.outputs.name
output virtualNetworkResourceId string = virtualNetworkModule.outputs.resourceId
output virtualNetworkSubnets array = virtualNetworkModule.outputs.subnetResourceIds
