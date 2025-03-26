// extension-resources.bicep
// Example file demonstrating extension resources in Bicep

// Extension resources are resources attached to other Azure resources, like:
// - Role assignments
// - Policy assignments
// - Resource locks
// - Diagnostic settings

// Parameters
@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Environment name (used for naming resources)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Enable resource locks for production resources')
param enableResourceLocks bool = false

@description('Principal ID to assign as a contributor to the storage account')
param contributorPrincipalId string

@description('Azure Monitor resource group where diagnostics are stored')
param monitoringResourceGroup string = 'rg-monitoring'

@description('Azure Log Analytics workspace name')
param logAnalyticsWorkspace string = 'law-central-monitoring'

// Resource names
var storageAccountName = 'stor${uniqueString(resourceGroup().id)}'
var keyVaultName = 'kv-${environment}-${uniqueString(resourceGroup().id)}'

// 1. Create a storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
  }
  tags: {
    environment: environment
    resourceType: 'Storage Account'
  }
}

// 2. EXTENSION RESOURCE: Add a role assignment to the storage account
// This attaches an RBAC role assignment to the storage account (extending it)
resource storageContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Use the format: <scope>/providers/Microsoft.Authorization/roleAssignments/<name>
  name: guid(storageAccount.id, contributorPrincipalId, 'Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role
    principalId: contributorPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// 3. Create a Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
    enabledForTemplateDeployment: true
    enabledForDeployment: true
    enabledForDiskEncryption: true
    accessPolicies: []
  }
  tags: {
    environment: environment
    resourceType: 'Key Vault'
  }
}

// 4. EXTENSION RESOURCE: Add a resource lock to the Key Vault
// This is an extension resource that prevents deletion of the Key Vault
resource keyVaultLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableResourceLocks) {
  name: 'keyVaultDoNotDelete'
  scope: keyVault
  properties: {
    level: 'CanNotDelete'
    notes: 'This resource cannot be deleted - it contains important secrets for operations'
  }
}

// 5. EXTENSION RESOURCE: Add a resource lock to the storage account
resource storageAccountLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableResourceLocks) {
  name: 'storageDoNotDelete'
  scope: storageAccount
  properties: {
    level: 'CanNotDelete'
    notes: 'This resource cannot be deleted - it contains important application data'
  }
}

// Get an existing Log Analytics workspace from a different resource group
resource existingLogAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspace
  scope: resourceGroup(monitoringResourceGroup)
}

// 6. EXTENSION RESOURCE: Add diagnostic settings to the Key Vault
resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyVault-diagnostics'
  scope: keyVault
  properties: {
    workspaceId: existingLogAnalytics.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
  }
}

// 7. EXTENSION RESOURCE: Add diagnostic settings to the Storage Account
resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'storage-diagnostics'
  scope: storageAccount
  properties: {
    workspaceId: existingLogAnalytics.id
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
      {
        category: 'Capacity'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
  }
}

// 8. EXTENSION RESOURCE: Assign a policy to the storage account
resource storagePolicyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'storage-https-policy'
  scope: storageAccount
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9' // Ensure HTTPS traffic only for storage accounts
    displayName: 'Secure transfer to storage accounts should be enabled'
    description: 'Audit requirement of Secure transfer in your storage account. Secure transfer is an option that forces your storage account to accept requests only from secure connections (HTTPS)'
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output resourceLockEnabled bool = enableResourceLocks
