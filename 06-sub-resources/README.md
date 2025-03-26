# Working with Sub-resources in Bicep

This section covers how to handle child (or sub) resources in Azure Bicep.

## What are Sub-resources?

Sub-resources (also called child resources) are Azure resources that exist within a parent resource's hierarchy. For example:
- Storage containers exist within a storage account
- Databases exist within a SQL server
- Virtual machines exist within a virtual network

## Ways to Declare Sub-resources

Bicep provides several approaches for declaring and managing child resources:

### 1. Nested Resource Declaration

Nested resource declarations use the full resource type with a path that includes the parent:

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'mystorageaccount'
  location: 'eastus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: '${storageAccount.name}/default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccount.name}/default/images'
  properties: {
    publicAccess: 'None'
  }
}
```

### 2. Parent Property

The more modern and readable approach uses the `parent` property to establish the relationship:

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'mystorageaccount'
  location: 'eastus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
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
  name: 'images'
  properties: {
    publicAccess: 'None'
  }
}
```

### 3. Child Resources Within Parent Resource

You can also define child resources directly inside the parent resource:

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'mystorageaccount'
  location: 'eastus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }

  resource blobService 'blobServices' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {
        enabled: true
        days: 7
      }
    }

    resource container 'containers' = {
      name: 'images'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// Reference a nested child resource
output containerUri string = storageAccount::blobService::container.properties.publicAccess
```

## Advantages and Disadvantages

Each approach has its merits:

| Approach | Pros | Cons |
|----------|------|------|
| Nested Declaration | Explicit resource paths | More verbose, can be hard to read |
| Parent Property | Clean, readable, clear relationship | Requires unique symbolic names for resources |
| Child Resources | Shows hierarchy visually | More complex to reference outside parent |

## Common Patterns and Examples

### SQL Server with Database

```bicep
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: 'mysqlserver'
  location: resourceGroup().location
  properties: {
    administratorLogin: 'adminUser'
    administratorLoginPassword: 'Password123!'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: 'mydb'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource firewallRule 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}
```

### Virtual Network with Subnets

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'myvnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  parent: vnet
  name: 'subnet1'
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  parent: vnet
  name: 'subnet2'
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
  dependsOn: [
    subnet1 // Subnet creation must be sequential within a VNet
  ]
}
```

## Loops with Child Resources

You can create multiple child resources using loops:

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'mystorageaccount'
  location: 'eastus'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
}

@description('List of container names to create')
param containerNames array = [
  'images'
  'documents'
  'backups'
]

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for containerName in containerNames: {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}]
```

## Referencing and Dependencies

Bicep automatically handles dependencies between parents and children. When you reference one resource from another, Bicep creates an implicit dependency:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'myvnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet1'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: 'vmnic'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/subnet1' // Reference to the subnet within the vnet
          }
        }
      }
    ]
  }
}
```

## Practical Examples

For practical examples, check out the sample files in this directory:

1. [Storage with Containers](./storage-containers.bicep) - Creating storage account with blob containers
2. [SQL Server with Databases](./sql-server-db.bicep) - Setting up SQL Server with databases and firewall rules
3. [App Service with Slots](./app-service-slots.bicep) - Deploying an App Service with deployment slots

## Next Steps

After learning about sub-resources, explore [Bicep Functions](../07-functions/README.md) to understand how to use built-in functions for more complex templates.