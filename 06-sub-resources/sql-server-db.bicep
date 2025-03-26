// sql-server-db.bicep
// Example of SQL Server with Databases and Firewall Rules

@description('SQL Server name (must be globally unique)')
param sqlServerName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('SQL Server administrator login')
param administratorLogin string

@description('SQL Server administrator password')
@secure()
param administratorLoginPassword string

@description('Database configurations')
param databases array = [
  {
    name: 'db1'
    tier: 'Standard'
    skuName: 'S0'
    maxSizeBytes: 1073741824  // 1GB
  }
  {
    name: 'db2'
    tier: 'Basic'
    skuName: 'Basic'
    maxSizeBytes: 2147483648  // 2GB
  }
]

@description('Firewall rules to allow access to the SQL Server')
param firewallRules array = [
  {
    name: 'AllowAll'
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
]

// Create SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    environment: 'demo'
    purpose: 'bicep-training'
  }
}

// Create SQL Databases as child resources
resource sqlDatabases 'Microsoft.Sql/servers/databases@2022-05-01-preview' = [for database in databases: {
  parent: sqlServer
  name: database.name
  location: location
  sku: {
    name: database.skuName
    tier: database.tier
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: database.maxSizeBytes
  }
  tags: {
    environment: 'demo'
    purpose: 'bicep-training'
  }
}]

// Create Firewall Rules as child resources
resource firewallRuleResources 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = [for rule in firewallRules: {
  parent: sqlServer
  name: rule.name
  properties: {
    startIpAddress: rule.startIpAddress
    endIpAddress: rule.endIpAddress
  }
}]

// Enable Azure Services access (alternative approach using fully qualified name)
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: '${sqlServer.name}/AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Create SQL Auditing settings as a child resource
resource sqlAuditing 'Microsoft.Sql/servers/auditingSettings@2022-05-01-preview' = {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
    retentionDays: 90
    storageAccountSubscriptionId: subscription().subscriptionId
  }
}

// Outputs
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output databaseNames array = [for (database, i) in databases: sqlDatabases[i].name]
output sqlServerName string = sqlServer.name
