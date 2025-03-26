# Bicep Function Exercises

Practice using Bicep functions with these exercises. Try to solve them before looking at the solutions.

## Exercise 1: Unique Resource Names

Create a Bicep template that generates consistent, unique names for various Azure resources:

1. Create a globally unique storage account name from a base name:
   - Must be all lowercase
   - No hyphens or special characters
   - 3-24 characters in length
   - Must be unique globally

2. Create a Key Vault name:
   - Must start with 'kv-'
   - Must contain the environment name
   - Must include some uniqueness factor
   - 3-24 characters in length

3. Create an App Service name:
   - Include the base name, environment, and unique string
   - Remove any spaces or invalid characters
   - Ensure it doesn't exceed 60 characters

## Exercise 2: Dynamic Resource Filtering

Create a Bicep template that:

1. Takes an array of Azure regions as input
2. Takes an environment parameter (dev, test, prod)
3. For dev environments:
   - Filter to only include US regions
   - Limit to a maximum of 2 regions
4. For test environments:
   - Filter to only include European regions
   - Sort the regions alphabetically
5. For prod environments:
   - Use all provided regions
   - Ensure there are at least 3 regions (show an error otherwise)

## Exercise 3: Connection String Builder

Create a template that builds various connection strings dynamically:

1. SQL Connection String:
   - Take server name, database name, username and password as parameters
   - Build the full connection string with proper formatting
   - Support both SQL authentication and Azure AD authentication modes

2. Storage Account Connection String:
   - Deploy a storage account
   - Use listKeys() to get the access key
   - Generate the full connection string with account name and key

3. Cosmos DB Connection String:
   - Reference an existing Cosmos DB account (use 'existing' keyword)
   - List the connection strings
   - Output the primary connection string

## Solutions

**Exercise 1 Solution:**

```bicep
param baseName string = 'contoso'
param environment string = 'dev'

// Storage Account Name
var storageAccountName = take(toLower(replace(concat(baseName, uniqueString(resourceGroup().id)), '-', '')), 24)

// Key Vault Name
var keyVaultName = take(toLower(format('kv-{0}-{1}-{2}', baseName, environment, uniqueString(resourceGroup().id))), 24)

// App Service Name
var appServiceName = take(replace(format('{0}-{1}-app-{2}', baseName, environment, uniqueString(resourceGroup().id)), ' ', ''), 60)

output generatedNames object = {
  storageAccountName: storageAccountName
  keyVaultName: keyVaultName
  appServiceName: appServiceName
}
```

**Exercise 2 Solution:**

```bicep
@description('Environment type')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Available Azure regions')
param availableRegions array = [
  'eastus'
  'westus'
  'northeurope'
  'westeurope'
  'eastasia'
  'southeastasia'
]

var usRegions = filter(availableRegions, region => contains(toLower(region), 'us'))
var euRegions = filter(availableRegions, region => contains(toLower(region), 'europe'))
var sortedEuRegions = sort(euRegions)

// Select regions based on environment
var selectedRegions = environment == 'dev' ?
                      take(usRegions, 2) :
                      (environment == 'test' ?
                      sortedEuRegions :
                      availableRegions)

// Validate prod has at least 3 regions
@batchSize(1)
resource errorIfNotEnoughRegions 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (environment == 'prod' && length(selectedRegions) < 3) {
  name: 'errorIfNotEnoughRegions'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '7.0'
    scriptContent: 'throw "Production environment requires at least 3 regions"'
    retentionInterval: 'PT1H'
  }
}

output regionsForDeployment array = selectedRegions
```

**Exercise 3 Solution:**

```bicep
// SQL Connection String Exercise
param sqlServerName string = 'my-sql-server'
param databaseName string = 'my-database'
param sqlUsername string = 'admin'
@secure()
param sqlPassword string = 'P@ssw0rd123!'
param useAzureAD bool = false

var sqlConnectionString = useAzureAD ?
  'Server=tcp:${sqlServerName}.database.windows.net,1433;Database=${databaseName};Authentication=Active Directory Default;' :
  'Server=tcp:${sqlServerName}.database.windows.net,1433;Database=${databaseName};User ID=${sqlUsername};Password=${sqlPassword};Encrypt=true;Connection Timeout=30;'

// Storage Account Connection String Exercise
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'st${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

var storageKey = listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageKey};EndpointSuffix=core.windows.net'

// Cosmos DB Connection String Exercise
resource existingCosmosDb 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: 'cosmos-${uniqueString(resourceGroup().id)}'
}

var cosmosConnectionString = listConnectionStrings(existingCosmosDb.id, existingCosmosDb.apiVersion).connectionStrings[0].connectionString

output connectionStrings object = {
  sqlConnectionString: sqlConnectionString
  storageConnectionString: storageConnectionString
  cosmosDbConnectionString: cosmosConnectionString
}
```

## Bonus Challenge

Create a template that uses advanced function composition to dynamically generate a set of resources based on a complex configuration object. For example, a template that provisions a complete web application environment with conditional features enabled based on the environment type.