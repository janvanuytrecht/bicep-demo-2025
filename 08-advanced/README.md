# Advanced Bicep Topics

This section covers advanced features and techniques for working with Bicep.

## Loops and Iteration

Bicep offers several ways to create multiple resources or properties using loops:

### Array Loops

Create multiple resources from an array of values:

```bicep
param locations array = [
  'eastus'
  'westus'
  'northeurope'
]

resource storageAccounts 'Microsoft.Storage/storageAccounts@2022-09-01' = [for location in locations: {
  name: 'storage${uniqueString(resourceGroup().id, location)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}]
```

### Index-Based Loops

Access the index in addition to the item:

```bicep
param vmNames array = [
  'web-vm'
  'app-vm'
  'db-vm'
]

resource networkInterfaces 'Microsoft.Network/networkInterfaces@2022-05-01' = [for (name, i) in vmNames: {
  name: '${name}-nic'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.0.${i + 4}' // Use index for IP addressing
        }
      }
    ]
  }
}]
```

### Object Loops

Iterate over object properties:

```bicep
param appServiceConfigs object = {
  dev: {
    sku: 'B1'
    capacity: 1
  }
  test: {
    sku: 'S1'
    capacity: 1
  }
  prod: {
    sku: 'P1v2'
    capacity: 3
  }
}

resource appServicePlans 'Microsoft.Web/serverfarms@2022-03-01' = [for (envName, config) in items(appServiceConfigs): {
  name: 'asp-${envName}'
  location: resourceGroup().location
  sku: {
    name: config.sku
    capacity: config.capacity
  }
}]
```

### Nested Loops

Combine loops for more complex scenarios:

```bicep
param environments array = [
  'dev'
  'test'
  'prod'
]

param regions array = [
  'eastus'
  'westus'
]

// Create a storage account for each environment in each region
resource storageAccounts 'Microsoft.Storage/storageAccounts@2022-09-01' = [for env in environments: [for region in regions: {
  name: 'st${env}${region}${uniqueString(resourceGroup().id)}'
  location: region
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}]]
```

## Conditional Deployment

Deploy resources based on conditions:

```bicep
param environment string = 'dev'
param deployRedis bool = true

resource redisCache 'Microsoft.Cache/Redis@2022-06-01' = if (environment == 'prod' || deployRedis) {
  name: 'redis-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    sku: {
      name: environment == 'prod' ? 'Premium' : 'Basic'
      family: environment == 'prod' ? 'P' : 'C'
      capacity: environment == 'prod' ? 2 : 0
    }
  }
}
```

## User-Defined Types

Bicep allows you to create custom types for reusable parameter definitions using the `type` keyword:

```bicep
// Define a type for VM configurations
type VmConfig = {
  @minLength(3)
  @maxLength(15)
  name: string

  size: string

  @allowed([
    'Windows'
    'Linux'
  ])
  osType: string

  diskSizeGB: int
  subnetId: string
}

// Use the custom type for a parameter
param virtualMachines VmConfig[]

// Use the typed parameter in a deployment
resource vms 'Microsoft.Compute/virtualMachines@2022-11-01' = [for vm in virtualMachines: {
  name: vm.name
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vm.size
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: vm.diskSizeGB
      }
    }
    osProfile: {
      computerName: vm.name
      // Other OS settings based on vm.osType
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vm.name}-nic')
        }
      ]
    }
  }
}]
```

## Bicep Decorators

Decorators modify the behavior of parameters, variables, and resources:

```bicep
// Metadata decorator
@metadata({
  title: 'Storage Account Template'
  description: 'Deploys a storage account with customizable options'
})

// Description and allowed values for parameters
@description('The environment to deploy to')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

// Secure string for sensitive information
@secure()
@minLength(8)
param adminPassword string

// Batch size for loop deployments (helps with dependencies)
@batchSize(2)
resource storageAccounts 'Microsoft.Storage/storageAccounts@2022-09-01' = [for i in range(1, 5): {
  name: 'storage${i}${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}]
```

## Extension Resources

Extension resources are resources that extend another Azure resource:

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'mystorageaccount'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// Lock is an extension resource for the storage account
resource storageLock 'Microsoft.Authorization/locks@2020-05-01' = {
  scope: storageAccount // Set the scope to the resource being extended
  name: 'storageAccountDoNotDelete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents deletion of the storage account'
  }
}

// Role assignment is another extension resource
resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, 'contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role ID
    principalId: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' // Service principal or user ID
    principalType: 'ServicePrincipal'
  }
}
```

## Using the `existing` Keyword

Reference existing resources without recreating them:

```bicep
// Reference an existing resource group
resource existingRg 'Microsoft.Resources/resourceGroups@2022-03-01' existing = {
  name: 'myExistingResourceGroup'
  scope: subscription()
}

// Reference an existing storage account
resource existingStorage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: 'existingstorageaccount'
}

// Create a container in the existing storage account
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${existingStorage.name}/default/mycontainer'
}

// List keys of the existing storage account
output storageAccountKey string = listKeys(existingStorage.id, existingStorage.apiVersion).keys[0].value
```

## Parameter Files in Bicep

While Bicep itself doesn't have parameter files, you can use ARM parameter files with Bicep:

**main.bicep**:
```bicep
param storageAccountName string
param location string = resourceGroup().location
param sku string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
}
```

**parameters.json**:
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "value": "mystorageaccountname"
    },
    "location": {
      "value": "eastus"
    },
    "sku": {
      "value": "Standard_GRS"
    }
  }
}
```

## Advanced Error Handling

Use deployment scripts for custom validations:

```bicep
param appName string
param environment string

// Validate parameters with custom logic
resource validator 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'validateParameters'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '7.0'
    scriptContent: '''
      param(
        [string]$AppName,
        [string]$Environment
      )

      if ($Environment -eq 'prod' -and $AppName.Contains('test')) {
        throw "Production environment cannot use app names with 'test' in them"
      }

      $DeploymentOutputs = @{}
      $DeploymentOutputs['result'] = 'Validation passed'
      $DeploymentOutputs | ConvertTo-Json -Depth 10
    '''
    arguments: format(' -AppName "{0}" -Environment "{1}"', appName, environment)
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess'
  }
}
```

## Examples and Exercises

Check out these advanced examples:

1. [Conditional-Deployment](./conditional-deployment.bicep) - Complex conditional deployment patterns
2. [Custom-Deployment-Script](./custom-deployment-script.bicep) - Using deployment scripts for custom logic
3. [Multi-Environment](./multi-environment-deployment.bicep) - Pattern for multi-environment deployments

## Next Steps

After learning these advanced topics, you'll have a solid understanding of Bicep for real-world scenarios. Consider exploring these additional resources:

- [Azure Verified Modules (AVM)](https://github.com/Azure/bicep-registry-modules)
- [Bicep Registry (Public)](https://github.com/Azure/bicep-registry-modules)
- [Bicep Extension for Azure DevOps](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks)