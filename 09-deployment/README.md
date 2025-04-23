# Bicep Deployment with Azure DevOps

This folder contains a simple Bicep template to deploy a Key Vault and an Azure DevOps pipeline to automate the deployment.

## Files

- `key-vault.bicep`: Bicep template for Key Vault deployment
- `azure-pipelines.yml`: Azure DevOps pipeline definition

## Prerequisites

1. Azure DevOps organization
2. Azure Service Connection in Azure DevOps (named `$(azureServiceConnection)`)
3. Azure CLI installed on the pipeline agent

## Pipeline Steps

1. **Create Resource Group**: Creates a new resource group for the deployment
2. **Bicep Build**: Compiles the Bicep file
3. **Bicep Validate**: Validates the template
4. **What-If Deployment**: Shows what changes will be made
5. **Deploy Key Vault**: Deploys the Key Vault

## Usage

1. Push these files to your Azure DevOps repository
2. Create a new pipeline using the `azure-pipelines.yml` file
3. Set up the `azureServiceConnection` variable in your pipeline
4. Run the pipeline

## Key Vault Configuration

The Key Vault is configured with:
- RBAC authorization enabled
- Soft delete enabled (7 days retention)
- Standard SKU
- Enabled for template deployment, VM deployment, and disk encryption

## Outputs

The deployment outputs:
- Key Vault name
- Key Vault ID
- Key Vault URI