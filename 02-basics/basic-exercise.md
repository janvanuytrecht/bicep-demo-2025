# Exercise: Create a Web App with App Service Plan

In this exercise, you'll create a Bicep file that deploys:
1. An App Service Plan
2. A Web App (App Service)
3. Application Insights for monitoring

## Requirements

- The App Service Plan should be Standard tier (S1)
- The Web App should have Application Insights enabled
- Use parameters for the web app name and environment (dev/test/prod)
- Add appropriate tags based on the environment
- Output the web app URL

## Steps

1. Create a new file named `webapp.bicep`
2. Define the required parameters
3. Add variables for any calculated values
4. Create resources for the App Service Plan, Web App, and Application Insights
5. Configure the resources with appropriate properties
6. Add outputs for the web app URL

## Hints

- App Service Plan API: `Microsoft.Web/serverfarms@2022-03-01`
- Web App API: `Microsoft.Web/sites@2022-03-01`
- Application Insights API: `Microsoft.Insights/components@2020-02-02`
- You'll need to reference the App Service Plan ID in the Web App properties
- Use string interpolation for naming resources consistently

## Solution

After attempting the exercise, you can check the sample solution in [webapp-solution.bicep](./webapp-solution.bicep).