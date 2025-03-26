// string-functions.bicep
// Demonstration of string manipulation functions in Bicep

// Input parameters
@description('Base name for resource naming')
param baseName string = 'demo'

@description('Environment (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

// String functions examples
var examples = {
  // String interpolation (preferred over concat)
  interpolation: 'app-${baseName}-${environment}'

  // Concat function for combining strings
  concatExample: concat('app-', baseName, '-', environment)

  // Converting case
  lowerCase: toLower('MIXED-CASE-TEXT')
  upperCase: toUpper('mixed-case-text')

  // Working with substrings
  extractMiddle: substring('ABCDEFGHIJ', 3, 4)  // Returns 'DEFG'

  // String replacement
  dashesRemoved: replace('storage-account-name', '-', '')

  // String format placeholders
  formattedString: format('App: {0}, Env: {1}', baseName, environment)

  // Padding a string
  padLeft: padLeft('123', 8, '0')  // Returns '00000123'

  // Trim extra spaces
  trimmedString: trim(' text with spaces  ')

  // Get the length of a string
  stringLength: length('Hello World')  // Returns 11

  // Limit string length with take
  truncatedValue: take('ThisIsAVeryLongResourceName', 15)  // Returns 'ThisIsAVeryLon'

  // Check if a string starts/ends with a value
  startsWith: startsWith('storage-account', 'storage')  // Returns true
  endsWith: endsWith('storage-account', 'account')  // Returns true

  // Split a string into an array
  splitExample: split('item1,item2,item3', ',')  // Returns ['item1', 'item2', 'item3']
}

// Practical storage account naming example
@maxLength(24)
@minLength(3)
param storageNamePrefix string = 'stor'

// Create a unique storage account name that:
// 1. Is all lowercase (required for storage accounts)
// 2. Contains no special characters (hyphens, etc. not allowed)
// 3. Is maximum 24 characters in length
// 4. Is globally unique by including a hash based on resource group ID
var storageAccountName = take(toLower(replace(concat(storageNamePrefix, baseName, environment, uniqueString(resourceGroup().id)), '-', '')), 24)

// Create storage account to show naming convention application
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: '1.2'
    supportsHttpsTrafficOnly: true
  }
  tags: {
    displayName: examples.interpolation
    environment: environment
  }
}

// Outputs to show function results
output stringExamples object = examples
output storageAccountName string = storageAccount.name
output storageAccountUrl string = 'https://${storageAccount.name}.blob.core.windows.net'
