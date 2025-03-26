# Exercise: Create a Network Module

In this exercise, you'll create a more advanced network module that includes network security groups and route tables.

## Requirements

1. Create a Bicep module named `advanced-network.bicep` that deploys:
   - A virtual network
   - Multiple subnets
   - Network security groups (NSGs) for each subnet that requires one
   - Route tables for subnets that require custom routing

2. The module should accept parameters for:
   - Virtual network name and address space
   - An array of subnet configurations (name, address space, whether NSG is required, etc.)
   - Optional NSG rules to apply to specific subnets
   - Optional route tables and routes for specific subnets
   - Location and tags

3. The module should output:
   - The virtual network ID and name
   - A map of subnet IDs by name
   - A map of NSG IDs by name

## Hints

- Use array loops to create multiple resources based on the input parameters
- Use conditions to only create resources when requested
- Consider using a nested object structure for subnet configuration
- Remember to use the parent property for child resources
- Use resource IDs to establish relationships between resources

## Example Subnet Configuration

The module should be able to handle input like this:

```bicep
param subnets array = [
  {
    name: 'web'
    addressPrefix: '10.0.1.0/24'
    nsgEnabled: true
    nsgRules: [
      {
        name: 'AllowHTTP'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        sourcePortRange: '*'
        destinationPortRange: '80'
      }
    ]
  }
  {
    name: 'data'
    addressPrefix: '10.0.2.0/24'
    nsgEnabled: true
    nsgRules: [
      {
        name: 'AllowSQL'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '10.0.1.0/24'  // Only allow from web subnet
        destinationAddressPrefix: '*'
        sourcePortRange: '*'
        destinationPortRange: '1433'
      }
    ]
    routeTableEnabled: true
    routes: [
      {
        name: 'RouteToInternet'
        addressPrefix: '0.0.0.0/0'
        nextHopType: 'VirtualAppliance'
        nextHopIpAddress: '10.0.3.4'
      }
    ]
  }
]
```

## Solution

After attempting the exercise, you can check the sample solution in the [advanced-network-solution.bicep](./advanced-network-solution.bicep) file.