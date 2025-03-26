// network-security-group.bicep
// AVM-inspired Network Security Group module

// Parameters
@description('Name of the Network Security Group')
param name string

@description('Azure region for the NSG')
param location string

@description('Security rules for the NSG')
param securityRules array = []

@description('Diagnostic settings for the NSG')
param diagnosticSettings object = {}

@description('Tags for the resource')
param tags object = {}

// Network Security Group resource
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules: securityRules
  }
}

// Add security rules if provided
resource securityRule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-05-01' = [for (rule, i) in securityRules: {
  name: rule.name
  parent: networkSecurityGroup
  properties: rule.properties
}]

// Outputs
output name string = networkSecurityGroup.name
output resourceId string = networkSecurityGroup.id
