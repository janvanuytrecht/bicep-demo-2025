# Setting Up Your Bicep Development Environment

This guide will help you set up your local development environment for Azure Bicep.

## Required Tools

1. **Azure CLI** - Command-line tool for managing Azure resources
2. **Bicep CLI** - Built into Azure CLI (version 2.20.0+)
3. **Visual Studio Code** - Recommended editor for Bicep
4. **Bicep VS Code Extension** - Provides syntax highlighting, validation, and IntelliSense

## Installation Steps

### 1. Install Azure CLI

#### Windows
```bash
# Install via PowerShell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
```

#### macOS
```bash
# Install via Homebrew
brew update && brew install azure-cli
```

#### Linux (Ubuntu/Debian)
```bash
# Install via apt
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 2. Update and Verify Azure CLI (includes Bicep)

```bash
# Update Azure CLI
az upgrade

# Verify installation
az version

# Check Bicep version
az bicep version
```

### 3. Install Visual Studio Code

Download and install from [code.visualstudio.com](https://code.visualstudio.com/)

### 4. Install Bicep VS Code Extension

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X or Cmd+Shift+X)
3. Search for "Bicep"
4. Install the Microsoft Bicep extension

## Azure Authentication

Before you can deploy Bicep files, you need to authenticate with Azure:

```bash
# Log in to Azure
az login

# Optional: Set your subscription
az account set --subscription "Your-Subscription-Name-or-ID"

# Verify current subscription
az account show
```

## Testing Your Setup

Let's create a simple Bicep file to test your setup:

1. Create a file named `test.bicep` with the following content:

```bicep
// test.bicep
param location string = 'eastus'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'storage${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

output storageAccountName string = storageAccount.name
```

2. Validate the file:

```bash
az bicep build --file test.bicep
```

If everything is set up correctly, this command should successfully build the Bicep file without errors.

## Helpful VS Code Shortcuts for Bicep Development

- `Ctrl+Space` (or `Cmd+Space` on macOS): Trigger IntelliSense
- `F12`: Go to definition
- `Alt+F12` (or `Option+F12` on macOS): Peek definition
- `Shift+Alt+F` (or `Shift+Option+F` on macOS): Format document

## Next Steps

Now that your environment is set up, proceed to the [Bicep Basics](../02-basics/README.md) section to learn the fundamentals of Bicep syntax and structure.