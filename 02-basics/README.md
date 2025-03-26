# Bicep Basics

This section covers the fundamental concepts of Azure Bicep, including syntax, resource declarations, parameters, variables, and outputs.

## Bicep vs ARM Templates

Bicep is a domain-specific language (DSL) that simplifies the authoring experience for Azure Resource Manager (ARM) templates. Key differences:

| Feature | ARM Templates | Bicep |
|---------|---------------|-------|
| Syntax | JSON (verbose) | Cleaner, more concise syntax |
| Modularity | Nested/linked templates | Native module support |
| Type safety | Limited | Strong type validation |
| IntelliSense | Limited | Rich IDE support |
| Learning curve | Steeper | More intuitive |

## Bicep File Structure

A typical Bicep file consists of:

- **Parameters**: Input values that can be provided during deployment
- **Variables**: Reusable values within the template
- **Resources**: Azure resources to deploy
- **Modules**: References to other Bicep files
- **Outputs**: Values returned after deployment

## Example 1: Basic Storage Account

Let's examine a simple Bicep file that deploys a storage account:

```bicep
// File: storage.bicep
// Description: Basic storage account deployment

// Parameters - values that can be provided at deployment time
param storageAccountName string
param location string = resourceGroup().location
param sku string = 'Standard_LRS'

// Resource declaration
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Outputs - values returned after deployment
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
```

## Example 2: Using Variables

Variables help you reuse values and reduce complexity:

```bicep
// File: storage-with-variables.bicep
// Description: Storage account with variables

param baseName string
param location string = resourceGroup().location

// Variables - reusable values within the template
var storageName = '${baseName}${uniqueString(resourceGroup().id)}'
var storageSkuName = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: location
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

output storageAccountId string = storageAccount.id
```

## Example 3: Deploying Multiple Resources

Let's deploy a storage account and a container:

```bicep
// File: storage-with-container.bicep
// Description: Storage account with blob container

param storageAccountName string
param location string = resourceGroup().location
param containerName string = 'content'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountId string = storageAccount.id
output containerPath string = '${storageAccount.name}/default/${containerName}'
```

## Parameter Types and Constraints

Bicep supports several parameter types and constraints to ensure valid inputs:

```bicep
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
```

## Key Points for Teaching

1. **Declaration Syntax**: Bicep uses a declarative syntax where you define the desired state of resources
2. **Resource Providers**: All Azure resources follow the format `<provider>/<resourceType>@<apiVersion>`
3. **Dependencies**: Bicep automatically calculates dependencies between resources
4. **Symbolic Names**: The names you give resources in Bicep (left of the = sign) are symbolic and only used within the template
5. **IntelliSense**: VS Code's Bicep extension provides autocomplete for resource types and properties

## Exercise: Create Basic Resources

In the [basic-exercise.md](./basic-exercise.md) file, you'll find an exercise to create a simple web app with app service plan using Bicep.

## Next Steps

Once you're comfortable with the basics, proceed to the [Validation & Deployment](../03-validation/README.md) section to learn how to test and deploy your Bicep files.