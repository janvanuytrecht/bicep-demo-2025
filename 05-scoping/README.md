# Understanding Scopes in Bicep

Bicep allows you to deploy resources at different scopes within Azure. This section explains how scoping works and demonstrates deployments at various levels.

## What is a Scope?

A scope in Azure is the boundary that defines where resources are deployed and managed. The four main scope levels in Azure are:

1. **Resource Group** - Collection of related resources
2. **Subscription** - Container for resource groups
3. **Management Group** - Container for subscriptions
4. **Tenant** - Contains all Azure AD directories and resources

## Why Scoping Matters

Understanding scoping is crucial because:

- Different resources must be deployed at specific scopes
- Permissions and RBAC are applied at different scopes
- Some resources exist only at certain scopes
- Multi-scope deployments require careful planning

## Default Scope

By default, Bicep files target the resource group scope. This is where most Azure resources are deployed.

## Resource Group Scope

This is the most common deployment scope:

```bicep
// deploy.bicep - Resource Group scope (default)
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'mystorage${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
```

Deploy with:
```bash
az deployment group create --resource-group myResourceGroup --template-file deploy.bicep
```

## Subscription Scope

Some resources like resource groups, policy assignments, and role assignments can be deployed at the subscription level:

```bicep
// subscription.bicep - Subscription scope
targetScope = 'subscription'

param location string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-03-01' = {
  name: 'myNewResourceGroup'
  location: location
}

output resourceGroupId string = resourceGroup.id
```

Deploy with:
```bash
az deployment sub create --location eastus --template-file subscription.bicep
```

## Management Group Scope

For policies and role assignments that need to apply across multiple subscriptions:

```bicep
// managementGroup.bicep - Management Group scope
targetScope = 'managementGroup'

param policyDefinitionId string

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'securityPolicy'
  properties: {
    policyDefinitionId: policyDefinitionId
    displayName: 'Security Standards Policy'
  }
}
```

Deploy with:
```bash
az deployment mg create --management-group-id myManagementGroup --location eastus --template-file managementGroup.bicep
```

## Tenant Scope

For tenant-wide deployments like management groups themselves:

```bicep
// tenant.bicep - Tenant scope
targetScope = 'tenant'

resource managementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'myNewManagementGroup'
  properties: {
    displayName: 'My Management Group'
  }
}
```

Deploy with:
```bash
az deployment tenant create --location eastus --template-file tenant.bicep
```

## Cross-Scope Deployments

One of the powerful features of Bicep is the ability to deploy resources across different scopes in a single template using modules:

```bicep
// main.bicep - Multi-scope deployment
targetScope = 'subscription'

param location string = 'eastus'

// Create a resource group at subscription scope
resource newRg 'Microsoft.Resources/resourceGroups@2022-03-01' = {
  name: 'myMultiScopeRG'
  location: location
}

// Deploy resources into the new resource group
module storageModule 'storage.bicep' = {
  name: 'storageDeployment'
  scope: newRg    // Set scope to the resource group
  params: {
    location: location
  }
}

// Deploy policy at subscription scope
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'restrictLocations'
  properties: {
    policyType: 'Custom'
    mode: 'All'
    parameters: {}
    policyRule: {
      if: {
        not: {
          field: 'location'
          in: [
            'eastus'
            'westus'
          ]
        }
      }
      then: {
        effect: 'deny'
      }
    }
  }
}
```

## Scope Expressions

Bicep provides several functions to obtain the current scope or reference other scopes:

- `resourceGroup()` - Get the current resource group
- `subscription()` - Get the current subscription
- `managementGroup()` - Get the current management group
- `tenant()` - Get the current tenant

You can also specify a different scope:

- `resourceGroup('myRG')` - Reference a specific resource group
- `subscription('subscriptionId')` - Reference a specific subscription
- `managementGroup('mgId')` - Reference a specific management group

## Examples

Check out the following examples in this directory:

1. [Resource Group Deployment](./rg-scope.bicep)
2. [Subscription Deployment](./sub-scope.bicep)
3. [Cross-Scope Deployment](./cross-scope.bicep)

## Best Practices

1. **Choose the Right Scope**: Deploy resources at the appropriate scope level
2. **Use Modules for Multi-Scope**: Use modules to manage complex multi-scope deployments
3. **Minimize Tenant Deployments**: Tenant-level deployments require elevated permissions
4. **Document Scope Requirements**: Document which scopes are needed for your templates
5. **Use Resource Targeting**: When possible, target specific resources rather than applying changes broadly

## Next Steps

After mastering scoping, move on to [Sub-Resources](../06-sub-resources/README.md) to learn how to work with child resources in Bicep.