# Bicep Modules

Bicep modules allow you to break down complex templates into smaller, reusable components. This section covers how to create and use modules effectively.

## Why Use Modules?

- **Reusability**: Define common resource patterns once and reuse them
- **Encapsulation**: Hide complex implementation details
- **Maintainability**: Smaller, focused files are easier to maintain
- **Testing**: Test modules independently
- **Organization**: Structure complex deployments logically

## Module Basics

A module is simply a Bicep file that is referenced by another Bicep file. Any Bicep file can be used as a module.

### Module Structure

A typical module contains:

1. **Parameters**: Inputs the module accepts
2. **Resources**: The Azure resources to deploy
3. **Outputs**: Values returned to the parent template

## Creating a Module

Let's create a simple storage module in [storage-module.bicep](./storage-module.bicep):

```bicep
// Module input parameters
param storageAccountName string
param location string
param sku string = 'Standard_LRS'
param tags object = {}

// Resource declaration
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

// Module outputs
output storageAccountId string = storageAccount.id
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
```

## Using a Module

You can reference modules using a `module` declaration:

```bicep
module storage './storage-module.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: 'mystorageaccount'
    location: 'eastus'
    sku: 'Standard_GRS'
    tags: {
      Environment: 'Production'
    }
  }
}

// Access module outputs
output storageAccountId string = storage.outputs.storageAccountId
```

## Module Scopes

By default, a module deploys to the same scope as the parent template. You can change this by setting the `scope` property:

```bicep
// Deploy to a different resource group
module storage './storage-module.bicep' = {
  name: 'storageDeployment'
  scope: resourceGroup('otherResourceGroup')
  params: {
    // ...parameters
  }
}

// Deploy to subscription scope
module policyModule './policy-module.bicep' = {
  name: 'policyDeployment'
  scope: subscription()
  params: {
    // ...parameters
  }
}
```

## Conditional Module Deployment

You can conditionally deploy modules using the `if` condition:

```bicep
param deployStorage bool = true

module storage './storage-module.bicep' = if (deployStorage) {
  name: 'conditionalStorage'
  params: {
    // ...parameters
  }
}
```

## Module Loops

You can deploy a module multiple times using the `for` loop:

```bicep
param regions array = [
  'eastus'
  'westus'
  'northeurope'
]

module multiRegionStorage './storage-module.bicep' = [for region in regions: {
  name: 'storage-${region}'
  params: {
    storageAccountName: 'storage${uniqueString(resourceGroup().id, region)}'
    location: region
    // ...other parameters
  }
}]

// Access outputs from a module loop
output storageIds array = [for (region, i) in regions: {
  region: region
  storageId: multiRegionStorage[i].outputs.storageAccountId
}]
```

## Module Dependencies

Bicep automatically handles dependencies between resources. However, you can explicitly declare dependencies between modules:

```bicep
module network './network-module.bicep' = {
  name: 'networkDeployment'
  params: {
    // ...parameters
  }
}

module vm './vm-module.bicep' = {
  name: 'vmDeployment'
  params: {
    // ...parameters
    subnetId: network.outputs.subnetId // Implicit dependency
  }
  dependsOn: [
    network // Explicit dependency (usually not needed)
  ]
}
```

## Module Libraries and Registries

For organization-wide reuse, you can publish modules to the Azure Container Registry (ACR) or the Bicep Public Registry:

```bicep
// Using a module from the Bicep Registry
module appServicePlan 'br/public:compute/app-service-plan:1.0.1' = {
  name: 'appServicePlanDeployment'
  params: {
    // ...parameters
  }
}

// Using a module from a private ACR
module webApp 'br:myregistry.azurecr.io/bicep/modules/webapp:v1' = {
  name: 'webAppDeployment'
  params: {
    // ...parameters
  }
}
```

## Example: Multi-Module Deployment

See the complete example in [main.bicep](./main.bicep) that uses multiple modules to deploy a complete solution.

## Best Practices for Modules

1. **Clear Interfaces**: Define clear parameter and output interfaces
2. **Single Responsibility**: Each module should have a single responsibility
3. **Validation**: Use parameter decorators to validate inputs
4. **Documentation**: Document parameters and the module's purpose
5. **Versioning**: Version your modules when publishing to registries
6. **Testing**: Test modules independently with different parameter combinations

## Exercise: Create a Network Module

In [network-module-exercise.md](./network-module-exercise.md), you'll find an exercise to create a reusable networking module.

## Next Steps

After mastering modules, move on to [Understanding Scopes](../05-scoping/README.md) to learn more about deployment scopes in Bicep.

## Azure Verified Modules (AVM)

### What are Azure Verified Modules?

Azure Verified Modules (AVM) are a library of infrastructure-as-code modules maintained by Microsoft and its partners, designed for enterprise deployment of Azure resources. These modules:

- Follow uniform patterns and practices
- Provide production-ready parameter defaults
- Are extensively tested
- Have comprehensive documentation
- Are maintained and versioned

### Benefits of Azure Verified Modules

- **Consistency**: Standardized implementation across your organization
- **Compliance**: Built-in security and best practices
- **Efficiency**: Reduces time spent creating and maintaining modules
- **Quality**: Thoroughly tested and maintained by Microsoft
- **Extensibility**: Can be customized while maintaining core functionality

### Example of using AVM in Bicep

We've created an example file `avm-example.bicep` that simulates using Azure Verified Modules. In a real implementation, you would reference modules directly from the Bicep Registry.

```bicep
// Real AVM module reference example
module keyVault 'br/public:avm/res/key-vault/vault:0.4.0' = {
  name: 'keyVaultDeployment'
  params: {
    name: 'kv-example'
    // other parameters
  }
}
```

Our example shows how to use AVM-style modules for:
- Key Vault
- Storage Account
- Network Security Group
- Virtual Network

### AVM Module Structure

The example modules follow AVM patterns such as:

1. Consistent parameter naming
2. Comprehensive documentation with @description decorators
3. Proper output structures
4. Resource tagging
5. Use of object parameters for complex settings

### Learn More About AVM

- [Azure Verified Modules](https://aka.ms/avm)
- [AVM GitHub Repository](https://github.com/Azure/Azure-Verified-Modules)
- [Bicep Registry Modules](https://aka.ms/BRM)