// main.bicep
// Multi-module deployment example

// Parameters
@description('Base name for all resources')
param baseName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name used for tagging and naming resources')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

// Variables
var tags = {
  Environment: environment
  Project: 'BicepDemo'
  DeployedWith: 'Bicep'
}

var storageName = '${baseName}${uniqueString(resourceGroup().id)}'
var vnetName = '${baseName}-vnet-${environment}'

// Storage Module
module storage './storage-module.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: storageName
    location: location
    tags: tags
    enableVersioning: true
    containerNames: [
      'data'
      'logs'
      'backups'
    ]
  }
}

// Network Module (using simplified version due to linter issues)
// In a real scenario, you would use the full network module
module network './network-module.bicep' = {
  name: 'networkDeployment'
  params: {
    vnetName: vnetName
    location: location
    tags: tags
    vnetAddressPrefix: '10.0.0.0/16'
    subnets: [
      {
        name: 'web'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'app'
        addressPrefix: '10.0.2.0/24'
      }
      {
        name: 'data'
        addressPrefix: '10.0.3.0/24'
      }
    ]
  }
}

// Using module outputs
output storageAccountName string = storage.outputs.storageAccountName
output storageAccountBlobEndpoint string = storage.outputs.blobEndpoint
output vnetId string = network.outputs.vnetId
output webSubnetId string = network.outputs.subnetIds.web
