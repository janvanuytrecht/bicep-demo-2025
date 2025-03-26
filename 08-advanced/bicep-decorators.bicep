// bicep-decorators.bicep
// Example of Bicep Decorators for parameters, variables, and resources

// ===========================================================
// Parameter Decorators
// ===========================================================

// @description - Provides documentation for a parameter
@description('The Azure region to deploy resources to')
param location string = resourceGroup().location

// @allowed - Restricts parameter to a set of allowed values
@description('The environment to deploy to')
@allowed([
  'dev'
  'test'
  'uat'
  'prod'
])
param environment string = 'dev'

// @secure - Prevents parameter values from appearing in deployment logs
@description('SQL Server administrator password')
@secure()
param sqlAdminPassword string

// @minLength, @maxLength - Validates string length
@description('SQL Server administrator login')
@minLength(4)
@maxLength(20)
param sqlAdminLogin string

// @minValue, @maxValue - Validates numeric values
@description('Number of virtual machines to deploy')
@minValue(1)
@maxValue(10)
param vmCount int = 2

// @metadata - Provides additional metadata for a parameter
@description('Tags to apply to all resources')
@metadata({
  example: {
    environment: 'development'
    costCenter: '123456'
  }
})
param resourceTags object = {
  environment: environment
  deployedBy: 'Bicep'
}

// ===========================================================
// Resource Decorators
// ===========================================================

// @batchSize - Controls how many resources in a resource loop are deployed in parallel
@description('Storage account names')
param storageNames array = [
  'storage1${uniqueString(resourceGroup().id)}'
  'storage2${uniqueString(resourceGroup().id)}'
  'storage3${uniqueString(resourceGroup().id)}'
]

// Deploy storage accounts with batch size of 2 (max 2 in parallel)
@batchSize(2)
resource storageAccounts 'Microsoft.Storage/storageAccounts@2022-09-01' = [for name in storageNames: {
  name: name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: resourceTags
}]

// ===========================================================
// Experimental Decorators
// ===========================================================

// @sys.maxLength() - System namespace decorator for parameter validation
@sys.description('Virtual machine name')
@sys.maxLength(15)
param vmName string = 'vm${take(uniqueString(resourceGroup().id), 8)}'

// Custom decorator for parameter validation
@description('Virtual machine size')
@sys.allowed([
  'Standard_B1s'
  'Standard_B2s'
  'Standard_D2s_v3'
])
param vmSize string = 'Standard_B1s'

// ===========================================================
// Other Parameter Decorators
// ===========================================================

// Multiple decorators can be applied to a parameter
@description('Storage account name')
@minLength(3)
@maxLength(24)
param storageName string = 'stor${uniqueString(resourceGroup().id)}'

// Interval Range Decorators
@description('Database DTUs')
@allowed([
  10
  20
  50
  100
  200
])
param databaseDTUs int = 10

// Enable Dynamic Allocation
@description('App Service Plan SKU')
param appPlanSku object = {
  name: environment == 'prod' ? 'P1V2' : 'B1'
  tier: environment == 'prod' ? 'PremiumV2' : 'Basic'
  capacity: environment == 'prod' ? 2 : 1
}

// Resource declaration using decorators
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  tags: resourceTags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: sqlAdminLogin
      adminPassword: sqlAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${vmName}-nic'
  location: location
  tags: resourceTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-${environment}', 'default')
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// SQL Server example using secure parameters
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: 'sql-${uniqueString(resourceGroup().id)}'
  location: location
  tags: resourceTags
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

// Outputs
@description('IDs of the deployed storage accounts')
output storageAccountIds array = [for i in range(0, length(storageNames)): storageAccounts[i].id]

@description('Name of the deployed VM')
output vmName string = virtualMachine.name

@description('Name of the SQL Server')
output sqlServerName string = sqlServer.name
