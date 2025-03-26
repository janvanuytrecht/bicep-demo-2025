// custom-deployment-script.bicep
// Example of using deployment scripts for advanced scenarios

// Parameters
@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Name prefix for resources')
param namePrefix string = 'demo'

@description('Environment type')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Storage container names to create')
param containerNames array = [
  'documents'
  'images'
  'backups'
]

@description('Generate unique password for resources?')
param generateUniquePassword bool = true

// Variables
var storageName = '${namePrefix}storage${uniqueString(resourceGroup().id)}'
var identity = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${managedIdentity.id}': {}
  }
}

// User-assigned managed identity for executing deployment scripts
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${namePrefix}-script-identity'
  location: location
}

// Role assignment to allow identity to create resources
resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, managedIdentity.id, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Storage account for the deployment scripts
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

// 1. Deployment Script - PowerShell
// Generate a complex password for resources
resource passwordGenerator 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (generateUniquePassword) {
  name: '${namePrefix}-password-generator'
  location: location
  kind: 'AzurePowerShell'
  identity: identity
  properties: {
    azPowerShellVersion: '7.0'
    retentionInterval: 'P1D'
    scriptContent: '''
      $Password = -join ((33..126) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
      $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

      # Generate a Base64 encoded password hash for application use
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($Password)
      $base64 = [System.Convert]::ToBase64String($bytes)

      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs['password'] = $Password
      $DeploymentScriptOutputs['base64Password'] = $base64
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
  }
  dependsOn: [
    contributorRoleAssignment
  ]
}

// 2. Deployment Script - Bash
// Create containers and set metadata
resource containerCreator 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${namePrefix}-container-creator'
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.40.0'
    retentionInterval: 'P1D'
    environmentVariables: [
      {
        name: 'STORAGE_ACCOUNT_NAME'
        value: storageAccount.name
      }
      {
        name: 'ENVIRONMENT'
        value: environment
      }
      {
        name: 'CONTAINER_NAMES'
        value: string(containerNames)
      }
    ]
    scriptContent: '''
      #!/bin/bash
      set -e

      # Get the storage account key
      STORAGE_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

      # Create each container with metadata
      for container in $CONTAINER_NAMES; do
        echo "Creating container: $container"
        az storage container create \
          --name $container \
          --account-name $STORAGE_ACCOUNT_NAME \
          --account-key $STORAGE_KEY \
          --metadata environment=$ENVIRONMENT created=deployment

        # Create a sample file in each container
        echo "This is a sample file in the $container container." > sample.txt
        az storage blob upload \
          --container-name $container \
          --file sample.txt \
          --name sample.txt \
          --account-name $STORAGE_ACCOUNT_NAME \
          --account-key $STORAGE_KEY
      done

      # Output container names
      echo "Containers created: $CONTAINER_NAMES"

      # Save output
      echo "{\"containersCreated\": \"$CONTAINER_NAMES\"}" > $AZ_SCRIPTS_OUTPUT_PATH
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
  }
  dependsOn: [
    contributorRoleAssignment
    storageAccount
  ]
}

// 3. Deployment Script - Custom validation
// Check resource naming conventions
resource namingValidator 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${namePrefix}-naming-validator'
  location: location
  kind: 'AzurePowerShell'
  identity: identity
  properties: {
    azPowerShellVersion: '7.0'
    retentionInterval: 'P1D'
    scriptContent: '''
      param (
        [string] $NamePrefix,
        [string] $Environment,
        [string] $StorageName
      )

      $result = @{ Valid = $true; Messages = @() }

      # Check name prefix length (should be 3-5 chars)
      if ($NamePrefix.Length -lt 3 -or $NamePrefix.Length -gt 5) {
        $result.Valid = $false
        $result.Messages += "Name prefix should be 3-5 characters, got: $($NamePrefix.Length)"
      }

      # Check if storage name is valid
      if ($StorageName.Length -lt 3 -or $StorageName.Length -gt 24) {
        $result.Valid = $false
        $result.Messages += "Storage name must be 3-24 characters, got: $($StorageName.Length)"
      }

      # Check if storage name has only lowercase letters and numbers
      if ($StorageName -match '[^a-z0-9]') {
        $result.Valid = $false
        $result.Messages += "Storage name can only contain lowercase letters and numbers"
      }

      # Environment validation
      $validEnvironments = @('dev', 'test', 'prod')
      if ($Environment -notin $validEnvironments) {
        $result.Valid = $false
        $result.Messages += "Environment must be one of: $($validEnvironments -join ', ')"
      }

      if ($result.Valid) {
        $result.Messages += "All naming conventions validated successfully"
      }

      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs['valid'] = $result.Valid
      $DeploymentScriptOutputs['messages'] = $result.Messages
    '''
    arguments: format('-NamePrefix "{0}" -Environment "{1}" -StorageName "{2}"', namePrefix, environment, storageAccount.name)
    timeout: 'PT15M'
    cleanupPreference: 'OnSuccess'
  }
  dependsOn: [
    contributorRoleAssignment
  ]
}

// Outputs
output storageAccountName string = storageAccount.name
output containerNames array = containerNames
output validationResult object = namingValidator.properties.outputs
output generatedPassword string = generateUniquePassword ? passwordGenerator.properties.outputs.password : 'No password generated'
output base64Password string = generateUniquePassword ? passwordGenerator.properties.outputs.base64Password : 'No password generated'
output containerCreationResult string = containerCreator.properties.outputs.containersCreated
