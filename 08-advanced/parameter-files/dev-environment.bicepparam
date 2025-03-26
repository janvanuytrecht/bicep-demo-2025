// dev-environment.bicepparam
// Parameter file for development environment

using '../conditional-deployment.bicep'

// Primary and secondary regions
param primaryLocation = 'eastus2'
param secondaryLocation = 'centralus'

// Environment settings
param environment = 'dev'
param appTier = 'basic'

// DR settings
param enableDisasterRecovery = false
