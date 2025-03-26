// existing-resources.bicep
// Example file demonstrating the 'existing' keyword in Bicep

// Parameters
@description('Name of existing Virtual Network')
param existingVnetName string

@description('Name of existing Key Vault')
param existingKeyVaultName string

@description('Resource group of the Key Vault (if different from current resource group)')
param keyVaultResourceGroup string = resourceGroup().name

@description('Name of the secret containing SQL admin password')
param sqlPasswordSecretName string = 'SqlAdminPassword'

@description('Name of existing storage account')
param existingStorageAccountName string

@description('App Service Plan name')
param appServicePlanName string = 'plan-${uniqueString(resourceGroup().id)}'

@description('App name')
param appName string = 'app-${uniqueString(resourceGroup().id)}'

@description('Subnet name for app service integration')
param appSubnetName string = 'app-subnet'

@description('Database name')
param sqlDatabaseName string = 'db-${uniqueString(resourceGroup().id)}'

@description('SQL Server name')
param sqlServerName string = 'sql-${uniqueString(resourceGroup().id)}'

@description('Location for all resources')
param location string = resourceGroup().location

// 1. Reference an existing virtual network
// This doesn't create a new vnet - it references an existing one
resource existingVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: existingVnetName
}

// 2. Reference an existing subnet in the VNet
resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: appSubnetName
  parent: existingVnet
}

// 3. Reference an existing Key Vault in a different resource group
resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: existingKeyVaultName
  scope: resourceGroup(keyVaultResourceGroup) // Use different resource group if specified
}

// 4. Reference an existing secret within the existing Key Vault
resource existingSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' existing = {
  name: sqlPasswordSecretName
  parent: existingKeyVault
}

// 5. Reference an existing storage account
resource existingStorage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: existingStorageAccountName
}

// Create a new App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'P1v2'
    tier: 'PremiumV2'
  }
  properties: {
    reserved: false
  }
}

// Create a SQL Server using the secret from the existing Key Vault
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: existingSecret.properties.value
    version: '12.0'
  }
}

// Create a SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
}

// Create a new App Service integrated with the existing VNET and storage account
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${existingStorage.name};AccountKey=${existingStorage.listKeys().keys[0].value}'
        }
        {
          name: 'SQL_CONNECTION_STRING'
          value: 'Server=tcp:${sqlServer.name}${environment().suffixes.sqlServerHostname},1433;Database=${sqlDatabase.name};Authentication=Active Directory Default;'
        }
        {
          name: 'KEY_VAULT_URL'
          value: existingKeyVault.properties.vaultUri
        }
      ]
    }
    virtualNetworkSubnetId: existingSubnet.id
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Give the app access to the Key Vault
// Using a module to avoid scope mismatch errors
module keyVaultAccessPolicyModule 'modules/key-vault-access-policy.bicep' = {
  name: 'keyVaultAccessPolicy'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    keyVaultName: existingKeyVaultName
    tenantId: appService.identity.tenantId
    objectId: appService.identity.principalId
  }
}

// Create a private endpoint for SQL Server in the existing subnet
resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: 'pe-${sqlServerName}'
  location: location
  properties: {
    subnet: {
      id: existingSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-sql'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

// Create a private DNS zone for SQL Server
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
}

// Link the private DNS zone to the VNET
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-to-${existingVnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: existingVnet.id
    }
  }
}

// Create the DNS zone group for the private endpoint
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = {
  parent: sqlPrivateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// Outputs
output appName string = appService.name
output appUrl string = 'https://${appService.properties.defaultHostName}'
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output vnetId string = existingVnet.id
output keyVaultUrl string = existingKeyVault.properties.vaultUri
output storageAccountName string = existingStorage.name
