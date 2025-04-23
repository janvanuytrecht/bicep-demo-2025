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

## Custom Modules and Azure Verified Modules (AVM)

This section covers both custom module creation and using Azure Verified Modules (AVM) in Bicep.

## Custom Modules

1. **Module Structure**
   - Input parameters
   - Resource definitions
   - Output values
   - Example: `network-module.bicep`

2. **Module Usage**
   - Local module references
   - Parameter passing
   - Output consumption
   - Example: `main.bicep`

## Azure Verified Modules (AVM)

Azure Verified Modules are Microsoft-maintained, production-ready Bicep modules that follow best practices and security standards.

### Key Features
- Production-ready templates
- Built-in security and compliance
- Regular updates and maintenance
- Comprehensive documentation
- Community support

### Using AVM Modules

1. **Module Reference Format**
   ```bicep
   module <name> 'br/public:avm/res/<provider>/<resource>:<version>' = {
     name: '<deployment-name>'
     params: {
       // Module parameters
     }
   }
   ```

2. **Available Modules**
   - Key Vault: `br/public:avm/res/key-vault/vault:1.0.0`
   - Storage Account: `br/public:avm/res/storage/storage-account:1.0.0`
   - Network Security Group: `br/public:avm/res/network/network-security-group:1.0.0`
   - Virtual Network: `br/public:avm/res/network/virtual-network:1.0.0`

3. **Prerequisites**
   - Latest Bicep CLI installed
   - Run `bicep restore` to download the modules
   - Azure subscription with contributor access

### Example Usage

See `avm-example.bicep` for a complete example using multiple AVM modules.

### Benefits of AVM
- Reduced development time
- Consistent implementation
- Security best practices
- Regular updates
- Microsoft support

### Resources
- [AVM Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/azure-verified-modules)
- [AVM GitHub Repository](https://github.com/Azure/bicep-registry-modules)
- [AVM Module Catalog](https://azure.github.io/bicep-registry-modules/)

## Exercises

1. Create a custom module for a specific resource
2. Deploy resources using AVM modules
3. Combine custom and AVM modules in a deployment