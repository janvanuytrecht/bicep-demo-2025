// File: parameter-examples.bicep
// Description: Parameter types and constraints

// String parameter with constraints
@minLength(3)
@maxLength(24)
@description('Storage account name (must be globally unique)')
param storageAccountName string

// Integer parameter with constraints
@minValue(1)
@maxValue(10)
param retentionDays int = 7

// Boolean parameter
param enableAdvancedThreatProtection bool = false

// Secure string (for secrets - not displayed in outputs or logs)
@secure()
param adminPassword string

// Array parameter
param allowedIPs array = [
  '1.2.3.4'
  '5.6.7.8'
]

// Object parameter
param tags object = {
  environment: 'development'
  project: 'demo'
}

// Allowed values
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
param storageSku string = 'Standard_LRS'

// Example resource using these parameters
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  tags: tags
  properties: {
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: [for ip in allowedIPs: {
        value: ip
        action: 'Allow'
      }]
    }
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: !enableAdvancedThreatProtection
  }
}
