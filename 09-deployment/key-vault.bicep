// key-vault.bicep
// Simple Key Vault deployment example

@description('Location for all resources')
param location string = 'westeurope'

@description('Resource Group name')
param resourceGroupName string = 'rg-keyvault-demo'

@description('Key Vault name')
param keyVaultName string = 'kv-${uniqueString(resourceGroup().id)}'

@description('Enable RBAC authorization')
param enableRbacAuthorization bool = true

@description('Enable soft delete')
param enableSoftDelete bool = true

@description('Soft delete retention in days')
param softDeleteRetentionInDays int = 7

@description('Resource tags')
param tags object = {
  environment: 'dev'
  deployedBy: 'Azure DevOps'
}

// Create Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Create Key Vault
module keyVault 'key-vault-module.bicep' = {
  name: 'keyVaultDeployment'
  scope: rg
  params: {
    keyVaultName: keyVaultName
    location: location
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    tags: tags
  }
}

// Outputs
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultId string = keyVault.outputs.keyVaultId
output keyVaultUri string = keyVault.outputs.keyVaultUri
