// key-vault.bicep
// AVM-inspired Key Vault module

// Parameters
@description('Name of the Key Vault')
param name string

@description('Azure region for the Key Vault')
param location string

@description('Enable RBAC authorization for Key Vault')
param enableRbacAuthorization bool = false

@description('Enable soft delete for Key Vault')
param enableSoftDelete bool = true

@description('Soft delete retention period in days')
param softDeleteRetentionInDays int = 90

@description('Tags for the resource')
param tags object = {}

@description('Network ACLs for the Key Vault')
param networkAcls object = {
  defaultAction: 'Allow'
  bypass: 'AzureServices'
  ipRules: []
  virtualNetworkRules: []
}

// Key Vault resource
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    networkAcls: networkAcls
  }
}

// Outputs
output name string = keyVault.name
output resourceId string = keyVault.id
output uri string = keyVault.properties.vaultUri
