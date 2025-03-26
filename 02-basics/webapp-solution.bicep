// Web App with App Service Plan - Exercise Solution

// Parameters
@description('Base name for all resources')
@minLength(3)
@maxLength(24)
param baseName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

// Variables
var appServicePlanName = '${baseName}-plan-${environment}'
var webAppName = '${baseName}-app-${environment}'
var appInsightsName = '${baseName}-insights-${environment}'

// Set SKU based on environment
var skuInfo = {
  dev: {
    name: 'S1'
    tier: 'Standard'
    capacity: 1
  }
  test: {
    name: 'S1'
    tier: 'Standard'
    capacity: 1
  }
  prod: {
    name: 'S1'
    tier: 'Standard'
    capacity: 2
  }
}

// Tags based on environment
var tags = {
  dev: {
    Environment: 'Development'
    CostCenter: 'DevTeam'
  }
  test: {
    Environment: 'Test'
    CostCenter: 'QATeam'
  }
  prod: {
    Environment: 'Production'
    CostCenter: 'Operations'
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags[environment]
  sku: skuInfo[environment]
  properties: {
    reserved: false // false for Windows, true for Linux
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags[environment]
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  tags: tags[environment]
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v6.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
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
}

// Outputs
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output appServicePlanId string = appServicePlan.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
