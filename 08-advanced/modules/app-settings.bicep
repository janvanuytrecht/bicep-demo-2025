// app-settings.bicep
// Module to update App Service settings for Application Insights

@description('Name of the App Service to configure')
param appServiceName string

@description('Application Insights Instrumentation Key')
param appInsightsKey string

@description('Application Insights Connection String')
param appInsightsConnectionString string

// Use an existing resource
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Update the application settings
resource appSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: appService
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
  }
}
