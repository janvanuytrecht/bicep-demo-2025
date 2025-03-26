# Bicep Functions

Bicep includes a wide range of built-in functions that help you perform various operations within your templates. This section covers common functions and their practical applications.

## Function Categories

Bicep functions can be grouped into the following categories:

1. **Array and Object Functions** - For manipulating and working with complex data types
2. **Comparison Functions** - For evaluating conditions and making decisions
3. **Date Functions** - For working with dates and times
4. **Deployment Functions** - For getting information about the deployment context
5. **Resource Functions** - For retrieving resource properties and metadata
6. **String Functions** - For manipulating text values
7. **Numeric Functions** - For mathematical operations

## String Functions

### String Manipulation

```bicep
// String concatenation (using the string interpolation operator is preferred)
var name1 = 'storage${uniqueString(resourceGroup().id)}'
var name2 = concat('storage', uniqueString(resourceGroup().id))

// Convert to lower or upper case
var nameLower = toLower('STORAGE')   // 'storage'
var nameUpper = toUpper('storage')   // 'STORAGE'

// Substring extraction
var subName = substring('mystorageaccount', 2, 7)   // 'storage'

// String replacement
var fixedName = replace('storage-account', '-', '')   // 'storageaccount'

// Check if a string contains a value
var hasPrefix = contains('mystorageaccount', 'storage')   // true

// Trimming whitespace
var trimmed = trim(' storage ')   // 'storage'
```

## Array Functions

### Array Manipulation

```bicep
// Create array with multiple values
var locations = [
  'eastus'
  'westus'
  'northeurope'
]

// Get the first element
var primaryLocation = first(locations)   // 'eastus'

// Get the last element
var lastLocation = last(locations)   // 'northeurope'

// Get length of an array
var regionCount = length(locations)   // 3

// Filtering arrays
var usRegions = filter(locations, location => contains(location, 'us'))   // ['eastus', 'westus']

// Mapping arrays (transform each element)
var regionDisplayNames = map(locations, location => toUpper(location))

// Joining array elements into a string
var locationsString = join(locations, ',')   // 'eastus,westus,northeurope'

// Check if an array contains a value
var hasEastUS = contains(locations, 'eastus')   // true
```

## Object Functions

### Working with Objects

```bicep
// Create an object
var storageConfig = {
  sku: 'Standard_LRS'
  kind: 'StorageV2'
  accessTier: 'Hot'
}

// Adding or modifying a property using union
var extendedConfig = union(storageConfig, {
  enableHttpsTrafficOnly: true
})

// Get an array of keys
var configKeys = keys(storageConfig)   // ['sku', 'kind', 'accessTier']

// Get an array of values
var configValues = values(storageConfig)   // ['Standard_LRS', 'StorageV2', 'Hot']

// Check if an object contains a property
var hasSku = contains(storageConfig, 'sku')   // true
```

## Resource Functions

### Working with Resources

```bicep
// Get the current resource group
var rgName = resourceGroup().name

// Get subscription information
var subId = subscription().subscriptionId

// Reference an existing resource
resource existingStorage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: 'existingStorageName'
}

// Use resourceId to create a reference to a resource by its type and name
var storageAccountId = resourceId('Microsoft.Storage/storageAccounts', 'mystorageaccount')

// Generate a unique string based on resource group ID (useful for unique names)
var uniqueName = uniqueString(resourceGroup().id)

// List keys for a resource (works with storage accounts, etc.)
var storageKeys = listKeys(existingStorage.id, existingStorage.apiVersion)
var primaryKey = storageKeys.keys[0].value
```

## Conditional Functions

### Making Decisions

```bicep
// Simple if condition
var environmentSettings = environment == 'Production' ? {
  tier: 'Premium'
  instanceCount: 3
} : {
  tier: 'Standard'
  instanceCount: 1
}

// Ternary operator for inline conditions
var skuName = environment == 'Production' ? 'P1' : 'S1'

// Coalesce - returns the first non-null value
var region = coalesce(customRegion, 'eastus')
```

## Practical Examples

### Example 1: Creating Unique Names

```bicep
// Creating a globally unique name for a storage account
param baseName string
param environment string

var uniqueNamePart = uniqueString(resourceGroup().id)
var cleanBaseName = replace(baseName, '-', '') // Remove hyphens
var storageAccountName = take('${toLower(cleanBaseName)}${uniqueNamePart}', 24) // Ensure it's at most 24 characters

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  // ...
}
```

### Example 2: Filtering Resources

```bicep
// Only deploy specific resources based on environment
param environment string
param locations array = [
  'eastus'
  'westus'
  'westeurope'
]

// Only deploy to US regions for dev/test environments
var deployRegions = environment == 'Production' ? locations : filter(locations, loc => contains(loc, 'us'))

// Then use in a loop
module storageAccounts 'storage.bicep' = [for region in deployRegions: {
  name: 'storage-${region}'
  params: {
    location: region
  }
}]
```

### Example 3: Building Connection Strings

```bicep
param sqlServerName string
param databaseName string
param administratorLogin string
@secure()
param administratorPassword string

// Build a connection string dynamically
var sqlConnectionString = 'Server=tcp:${sqlServerName}.database.windows.net,1433;Database=${databaseName};User ID=${administratorLogin};Password=${administratorPassword};Encrypt=true;Connection Timeout=30;'

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  // ...
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'SqlConnectionString'
          value: sqlConnectionString
        }
      ]
    }
  }
}
```

## Function Composition

You can chain multiple functions together for complex operations:

```bicep
// Combine functions for advanced operations
var result = toLower(substring(replace(resourceGroup().name, '-', ''), 0, 6))
```

## Exercises

For practice, check out [function-exercises.md](./function-exercises.md) with exercises focused on using Bicep functions.

## Examples Files

1. [String Manipulation](./string-functions.bicep) - Examples of working with strings
2. [Array Operations](./array-functions.bicep) - Array filtering and transformation
3. [Resource References](./resource-functions.bicep) - Working with resource properties and references

## Next Steps

After mastering functions, move on to [Advanced Topics](../08-advanced/README.md) for more complex Bicep features.