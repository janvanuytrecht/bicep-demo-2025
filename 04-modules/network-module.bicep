// network-module.bicep
// Reusable virtual network module

// Module input parameters
@description('Virtual network name')
param vnetName string

@description('Azure region for the virtual network')
param location string

@description('Virtual network address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Array of subnet configurations')
param subnets array = [
  {
    name: 'default'
    addressPrefix: '10.0.0.0/24'
  }
]

@description('Resource tags')
param tags object = {}

// Create Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

// Module outputs
output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetIds object = {for subnet in subnets: subnet.name => resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet.name)}
