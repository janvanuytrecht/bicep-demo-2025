// prod-environment.bicepparam
// Parameter file for production environment

using '../conditional-deployment.bicep'

// Primary and secondary regions
param primaryLocation = 'eastus'
param secondaryLocation = 'westus'

// Environment settings
param environment = 'prod'
param appTier = 'premium'

// DR settings
param enableDisasterRecovery = true
