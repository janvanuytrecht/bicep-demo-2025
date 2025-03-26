// key-vault-access-policy.bicep
// Module for granting Key Vault access to a principal

@description('Name of the Key Vault')
param keyVaultName string

@description('Tenant ID of the principal')
param tenantId string

@description('Object ID of the principal')
param objectId string

@description('Permissions to grant for secrets (default: get and list)')
param secretsPermissions array = [
  'get'
  'list'
]

// Reference the existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// Add the access policy
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: objectId
        permissions: {
          secrets: secretsPermissions
        }
      }
    ]
  }
}

// Outputs
output accessPolicyId string = keyVaultAccessPolicy.id
