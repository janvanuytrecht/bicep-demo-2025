// user-defined-types.bicep
// Example demonstrating User-Defined Types in Bicep

// Define a user-defined type for database settings
@description('Settings for a database instance')
type databaseSettings = {
  @description('Name of the database server')
  serverName: string

  @description('Name of the database')
  databaseName: string

  @description('SKU tier of the database')
  skuTier: 'Basic' | 'Standard' | 'Premium' | 'GeneralPurpose' | 'BusinessCritical' | 'Hyperscale'

  @description('SKU name of the database')
  skuName: string

  @description('Database capacity in DTUs or vCores')
  @minValue(1)
  capacity: int

  @description('Enable high availability')
  @metadata({
    defaultValue: false
    example: 'Set to true for production workloads'
  })
  highAvailability: bool

  @description('Tags for the resource')
  tags: object
}

// Define a user-defined type for virtual networks
@description('Settings for a virtual network')
type vnetSettings = {
  @description('Name of the virtual network')
  name: string

  @description('Address space for the virtual network')
  @minLength(1)
  addressPrefixes: string[]

  @description('Subnets to create in the virtual network')
  subnets: subnetSettings[]
}

type subnetSettings = {
  @description('Name of the subnet')
  name: string

  @description('Address prefix for the subnet')
  addressPrefix: string

  @description('Security rules for the subnet')
  securityRules: securityRuleSettings[]?
}

type securityRuleSettings = {
  @description('Name of the security rule')
  name: string

  @description('Priority of the security rule')
  @minValue(100)
  @maxValue(4096)
  priority: int

  @description('Type of traffic to allow or deny')
  direction: 'Inbound' | 'Outbound'

  @description('Action to take')
  access: 'Allow' | 'Deny'

  @description('Protocol to apply rule to')
  protocol: string

  @description('Source address prefix')
  sourceAddressPrefix: string

  @description('Destination address prefix')
  destinationAddressPrefix: string

  @description('Source port range')
  sourcePortRange: string

  @description('Destination port range')
  destinationPortRange: string
}

// User-defined type for Application Gateway settings
@description('Settings for Application Gateway')
type appGatewaySettings = {
  @description('Name of the Application Gateway')
  name: string

  @description('SKU name')
  skuName: 'Standard_Small' | 'Standard_Medium' | 'Standard_Large' | 'WAF_Medium' | 'WAF_Large' | 'Standard_v2' | 'WAF_v2'

  @description('SKU tier')
  tier: 'Standard' | 'WAF' | 'Standard_v2' | 'WAF_v2'

  @description('Instance count')
  @minValue(1)
  @maxValue(125)
  capacity: int

  @description('Enable autoscaling')
  enableAutoscaling: bool

  @description('Minimum capacity when autoscaling is enabled')
  @minValue(0)
  @maxValue(100)
  minCapacity: int?

  @description('Maximum capacity when autoscaling is enabled')
  @minValue(1)
  @maxValue(125)
  maxCapacity: int?
}

// Parameter using the user-defined types
@description('SQL Database settings')
param sqlSettings databaseSettings

@description('Virtual Network settings')
param networkSettings vnetSettings

@description('Application Gateway settings')
param appGwSettings appGatewaySettings

// Default values using the user-defined types
var defaultSqlSettings = {
  serverName: 'sql-${uniqueString(resourceGroup().id)}'
  databaseName: 'sampledb'
  skuTier: 'Standard'
  skuName: 'S1'
  capacity: 10
  highAvailability: false
  tags: {
    environment: 'dev'
    department: 'IT'
  }
}

var defaultNetworkSettings = {
  name: 'vnet-${uniqueString(resourceGroup().id)}'
  addressPrefixes: [
    '10.0.0.0/16'
  ]
  subnets: [
    {
      name: 'default'
      addressPrefix: '10.0.0.0/24'
    }
    {
      name: 'appGateway'
      addressPrefix: '10.0.1.0/24'
    }
  ]
}

// SQL Server resource using the user-defined type parameters
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: sqlSettings.serverName
  location: resourceGroup().location
  tags: sqlSettings.tags
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: 'P@ssw0rd1234!'  // Would normally use a secure parameter
  }
}

// SQL Database resource using the user-defined type parameters
resource sqlDb 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: sqlSettings.databaseName
  location: resourceGroup().location
  tags: sqlSettings.tags
  sku: {
    name: sqlSettings.skuName
    tier: sqlSettings.skuTier
    capacity: sqlSettings.capacity
  }
  properties: {
    highAvailabilityReplicas: sqlSettings.highAvailability ? 2 : 0
  }
}

// Virtual Network resource using the user-defined type parameters
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: networkSettings.name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: networkSettings.addressPrefixes
    }
    subnets: [for subnet in networkSettings.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

// Application Gateway resource using the user-defined type parameters
resource appGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: appGwSettings.name
  location: resourceGroup().location
  properties: {
    sku: {
      name: appGwSettings.skuName
      tier: appGwSettings.tier
      capacity: appGwSettings.capacity
    }
    autoscaleConfiguration: appGwSettings.enableAutoscaling ? {
      minCapacity: appGwSettings.minCapacity
      maxCapacity: appGwSettings.maxCapacity
    } : null
    // Additional properties would be configured here in a real deployment
  }
}

// Outputs
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDb.name
output vnetName string = vnet.name
output subnetNames array = [for subnet in networkSettings.subnets: subnet.name]
output appGatewayName string = appGateway.name
