// cross-scope.bicep
// This is a cross-scope deployment example

// Setting the target scope to subscription level
targetScope = 'subscription'

// Parameters
@description('Azure region to deploy resources')
param location string = 'eastus'

@description('Environment name used for naming and tagging')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Base name for the application resources')
param baseName string

// Variables
var tags = {
  Environment: environment
  Application: baseName
  DeployedWith: 'Bicep'
}

var resourceGroupName = '${baseName}-${environment}-rg'
var logAnalyticsWorkspaceName = '${baseName}-${environment}-la'

// Create resource group at subscription scope
resource appResourceGroup 'Microsoft.Resources/resourceGroups@2022-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Create a resource group for shared monitoring resources
resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2022-03-01' = {
  name: '${baseName}-monitoring-rg'
  location: location
  tags: tags
}

// Deploy Log Analytics workspace to the monitoring resource group
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'logAnalyticsDeployment'
  scope: monitoringResourceGroup
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
    tags: tags
  }
}

// Deploy application infrastructure to the application resource group
module appInfrastructure 'modules/app-infrastructure.bicep' = {
  name: 'appInfrastructureDeployment'
  scope: appResourceGroup
  params: {
    location: location
    environment: environment
    baseName: baseName
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Deploy a policy at subscription scope
resource allowedLocationsPolicy 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'allowed-locations'
  properties: {
    displayName: 'Allowed Locations'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c' // Built-in "Allowed Locations" policy
    parameters: {
      listOfAllowedLocations: {
        value: [
          location
        ]
      }
    }
  }
}

// Outputs from both resource groups
output appServiceUrl string = appInfrastructure.outputs.appServiceUrl
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
output resourceGroupNames object = {
  app: appResourceGroup.name
  monitoring: monitoringResourceGroup.name
}
