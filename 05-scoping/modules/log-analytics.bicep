// log-analytics.bicep
// Log Analytics Workspace module

@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Azure region for the workspace')
param location string

@description('Resource tags')
param tags object = {}

@description('Workspace SKU')
@allowed([
  'PerGB2018'
  'CapacityReservation'
  'Free'
  'PerNode'
  'Standard'
  'Standalone'
])
param sku string = 'PerGB2018'

@description('Retention period in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

// Log Analytics Workspace resource
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
output workspaceId string = workspace.id
output workspaceName string = workspace.name
output primarySharedKey string = listKeys(workspace.id, workspace.apiVersion).primarySharedKey
