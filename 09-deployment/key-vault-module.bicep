// key-vault-module.bicep
// Key Vault module for subscription scope deployment

@description('Key Vault name')
param keyVaultName string

@description('Location for the Key Vault')
param location string

@description('Enable RBAC authorization')
param enableRbacAuthorization bool

@description('Enable soft delete')
param enableSoftDelete bool

@description('Soft delete retention in days')
param softDeleteRetentionInDays int

@description('Resource tags')
param tags object

// Create Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enabledForTemplateDeployment: true
    enabledForDeployment: true
    enabledForDiskEncryption: true
  }
  tags: tags
}

// Outputs
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
