// virtual-network.bicep
// AVM-inspired Virtual Network module

// Parameters
@description('Name of the Virtual Network')
param name string

@description('Azure region for the Virtual Network')
param location string

@description('Address prefixes for the Virtual Network')
param addressPrefixes array

@description('Subnets to create in the Virtual Network')
param subnets array = []

@description('DNS servers for the Virtual Network')
param dnsServers array = []

@description('Enable DDoS Protection')
param enableDdosProtection bool = false

@description('Tags for the resource')
param tags object = {}

// Virtual Network resource
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    enableDdosProtection: enableDdosProtection
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: contains(subnet, 'networkSecurityGroupId') && !empty(subnet.networkSecurityGroupId) ? {
          id: subnet.networkSecurityGroupId
        } : null
        routeTable: contains(subnet, 'routeTableId') && !empty(subnet.routeTableId) ? {
          id: subnet.routeTableId
        } : null
        privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies') ? subnet.privateEndpointNetworkPolicies : null
        privateLinkServiceNetworkPolicies: contains(subnet, 'privateLinkServiceNetworkPolicies') ? subnet.privateLinkServiceNetworkPolicies : null
        serviceEndpoints: contains(subnet, 'serviceEndpoints') ? subnet.serviceEndpoints : null
        delegations: contains(subnet, 'delegations') ? subnet.delegations : null
      }
    }]
  }
}

// Get all subnets
var subnetIds = [for (subnet, i) in subnets: {
  name: subnet.name
  resourceId: '${virtualNetwork.id}/subnets/${subnet.name}'
}]

// Outputs
output name string = virtualNetwork.name
output resourceId string = virtualNetwork.id
output subnetResourceIds array = [for (subnet, i) in subnets: '${virtualNetwork.id}/subnets/${subnet.name}']
output subnets array = subnetIds
