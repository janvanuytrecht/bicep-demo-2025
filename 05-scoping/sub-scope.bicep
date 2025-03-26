// sub-scope.bicep
// This is a subscription scoped Bicep file

// Setting the target scope to subscription level
targetScope = 'subscription'

// Parameters with default values
@description('Azure region to deploy resources')
param location string = 'eastus'

@description('Resource group name')
param resourceGroupName string

@description('Environment tag value')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

// Variables
var tags = {
  Environment: environment
  DeployedBy: 'Bicep'
}

// Resource Group - Can only be deployed at subscription scope or above
resource newResourceGroup 'Microsoft.Resources/resourceGroups@2022-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Azure Policy Definition - Subscription level resource
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'restrict-locations'
  properties: {
    policyType: 'Custom'
    mode: 'All'
    parameters: {
      allowedLocations: {
        type: 'Array'
        metadata: {
          description: 'The list of allowed locations for resources.'
          displayName: 'Allowed locations'
        }
        defaultValue: [
          'eastus'
          'westus'
        ]
      }
    }
    policyRule: {
      if: {
        not: {
          field: 'location'
          in: '[parameters(\'allowedLocations\')]'
        }
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Role Assignment - Subscription level resource
@description('This is the built-in Reader role. See https://learn.microsoft.com/azure/role-based-access-control/built-in-roles')
resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader role ID
}

// Deploy resources to the new resource group
module storageModule 'rg-scope.bicep' = {
  name: 'storageDeployment'
  scope: newResourceGroup // Setting module scope to the resource group created above
  params: {
    location: location
    environment: environment
  }
}

// Outputs
output resourceGroupId string = newResourceGroup.id
output policyDefinitionId string = policyDefinition.id
