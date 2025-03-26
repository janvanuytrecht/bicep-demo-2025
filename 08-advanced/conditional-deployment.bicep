// conditional-deployment.bicep
// Demonstrates complex conditional deployment patterns in Bicep

// Input parameters
@description('Primary Azure region for deployment')
param primaryLocation string = 'eastus'

@description('Secondary Azure region for deployment (used for HA/DR)')
param secondaryLocation string = 'westus'

@description('Environment type')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Application tier')
@allowed([
  'basic'
  'standard'
  'premium'
])
param appTier string = 'standard'

@description('Enable disaster recovery')
param enableDisasterRecovery bool = false

// Variables for conditionals
var isProd = environment == 'prod'
var isStandardOrHigher = appTier == 'standard' || appTier == 'premium'
var isPremium = appTier == 'premium'
var needsSecondaryRegion = isProd || enableDisasterRecovery

// Determine SKU configurations based on tier and environment
var skuConfigs = {
  dev: {
    basic: {
      name: 'B1'
      tier: 'Basic'
      capacity: 1
    }
    standard: {
      name: 'S1'
      tier: 'Standard'
      capacity: 1
    }
    premium: {
      name: 'P1v2'
      tier: 'PremiumV2'
      capacity: 1
    }
  }
  test: {
    basic: {
      name: 'B2'
      tier: 'Basic'
      capacity: 1
    }
    standard: {
      name: 'S2'
      tier: 'Standard'
      capacity: 1
    }
    premium: {
      name: 'P1v2'
      tier: 'PremiumV2'
      capacity: 1
    }
  }
  prod: {
    basic: {
      name: 'S1'
      tier: 'Standard'  // Even basic tier gets Standard in prod
      capacity: 2
    }
    standard: {
      name: 'S3'
      tier: 'Standard'
      capacity: 2
    }
    premium: {
      name: 'P2v2'
      tier: 'PremiumV2'
      capacity: 3
    }
  }
}

// Selected configuration
var selectedSku = skuConfigs[environment][appTier]

// 1. Primary App Service Plan - always deployed
resource primaryAppServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${environment}-primary'
  location: primaryLocation
  sku: selectedSku
  properties: {
    reserved: false // For Windows. Set to true for Linux
  }
  tags: {
    Environment: environment
    Region: 'Primary'
  }
}

// 2. Primary App Service - always deployed
resource primaryAppService 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-${environment}-primary-${uniqueString(resourceGroup().id)}'
  location: primaryLocation
  properties: {
    serverFarmId: primaryAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: isStandardOrHigher // Only enable alwaysOn for Standard+ tiers
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'ENVIRONMENT'
          value: environment
        }
      ]
    }
  }
  tags: {
    Environment: environment
    Region: 'Primary'
  }
}

// 3. Secondary App Service Plan - only deployed for prod or if DR is enabled
resource secondaryAppServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = if (needsSecondaryRegion) {
  name: 'plan-${environment}-secondary'
  location: secondaryLocation
  sku: selectedSku
  properties: {
    reserved: false
  }
  tags: {
    Environment: environment
    Region: 'Secondary'
  }
}

// 4. Secondary App Service - only deployed for prod or if DR is enabled
resource secondaryAppService 'Microsoft.Web/sites@2022-03-01' = if (needsSecondaryRegion) {
  name: 'app-${environment}-secondary-${uniqueString(resourceGroup().id)}'
  location: secondaryLocation
  properties: {
    serverFarmId: needsSecondaryRegion ? secondaryAppServicePlan.id : null
    httpsOnly: true
    siteConfig: {
      alwaysOn: isStandardOrHigher
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'ENVIRONMENT'
          value: environment
        }
        {
          name: 'IS_SECONDARY'
          value: 'true'
        }
      ]
    }
  }
  tags: {
    Environment: environment
    Region: 'Secondary'
  }
}

// 5. Application Insights - only deployed for standard+ tiers
resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (isStandardOrHigher) {
  name: 'appi-${environment}-${uniqueString(resourceGroup().id)}'
  location: primaryLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: isProd ? 90 : 30
    IngestionMode: 'ApplicationInsights'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    Environment: environment
  }
}

// 6. Add Application Insights settings to both web apps if it's deployed
module primaryAppInsightsConfig 'modules/app-settings.bicep' = if (isStandardOrHigher) {
  name: 'primaryAppInsightsConfig'
  params: {
    appServiceName: primaryAppService.name
    appInsightsKey: isStandardOrHigher ? appInsights.properties.InstrumentationKey : ''
    appInsightsConnectionString: isStandardOrHigher ? appInsights.properties.ConnectionString : ''
  }
}

module secondaryAppInsightsConfig 'modules/app-settings.bicep' = if (isStandardOrHigher && needsSecondaryRegion) {
  name: 'secondaryAppInsightsConfig'
  params: {
    appServiceName: needsSecondaryRegion ? secondaryAppService.name : 'none'
    appInsightsKey: isStandardOrHigher ? appInsights.properties.InstrumentationKey : ''
    appInsightsConnectionString: isStandardOrHigher ? appInsights.properties.ConnectionString : ''
  }
}

// 7. Deployment slots - only for premium tier
resource stagingSlot 'Microsoft.Web/sites/slots@2022-03-01' = if (isPremium) {
  parent: primaryAppService
  name: 'staging'
  location: primaryLocation
  properties: {
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'ENVIRONMENT'
          value: '${environment}-staging'
        }
      ]
    }
  }
}

// 8. Redis Cache - only for standard+ tiers in prod or if explicitly requested
resource redisCache 'Microsoft.Cache/Redis@2022-06-01' = if (isProd && isStandardOrHigher) {
  name: 'redis-${environment}-${uniqueString(resourceGroup().id)}'
  location: primaryLocation
  properties: {
    sku: {
      name: isPremium ? 'Premium' : 'Standard'
      family: isPremium ? 'P' : 'C'
      capacity: isPremium ? 2 : 1
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
}

// Output the appropriate deployment resources
output primaryAppServiceName string = primaryAppService.name
output primaryAppServiceUrl string = 'https://${primaryAppService.properties.defaultHostName}'
output hasSecondaryRegion bool = needsSecondaryRegion
output secondaryAppServiceUrl string = needsSecondaryRegion ? 'https://${secondaryAppService.properties.defaultHostName}' : 'N/A'
output hasApplicationInsights bool = isStandardOrHigher
output hasRedisCache bool = isProd && isStandardOrHigher
output hasStagingSlot bool = isPremium
