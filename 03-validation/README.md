# Bicep Validation & Deployment

This section covers how to validate and deploy Bicep files using the Azure CLI.

## Validation Commands

Before deploying your Bicep files, it's crucial to validate them to catch errors early.

### Building/Compiling Bicep Files

The `az bicep build` command compiles a Bicep file to an ARM template JSON file:

```bash
# Basic build
az bicep build --file main.bicep

# Build to a specific output file
az bicep build --file main.bicep --outfile template.json
```

### Linting

Bicep has built-in linting to catch issues. VS Code's Bicep extension shows these automatically, but you can also check via CLI:

```bash
# Linting is performed automatically during build
az bicep build --file main.bicep
```

### ARM Template Validation

You can validate the template against Azure's API before deployment:

```bash
# Validate a Bicep file for a resource group deployment
az deployment group validate \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters parameters.json
```

## What-If Deployment

The what-if operation shows you what would happen if you deployed your template without actually creating or modifying resources.

```bash
# View what changes would be made by a deployment
az deployment group what-if \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters parameters.json
```

### Sample Output

What-if output is color-coded and shows:
- Resources that will be created (green)
- Resources that will be deleted (red)
- Resources that will be modified (yellow)
- Resources that will remain unchanged (gray)

## Deployment Commands

Once validated, you can deploy Bicep files using Azure CLI.

### Resource Group Deployment

For most resources, you'll deploy to an existing resource group:

```bash
# Deploy a Bicep file to a resource group
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters location=eastus storageName=mystorageaccount
```

### Subscription Deployment

For resources that exist at the subscription level (like resource groups themselves):

```bash
# Deploy a Bicep file at subscription scope
az deployment sub create \
  --location eastus \
  --template-file subscription.bicep
```

### Management Group Deployment

For policies or role assignments at the management group level:

```bash
# Deploy a Bicep file at management group scope
az deployment mg create \
  --management-group-id myManagementGroup \
  --location eastus \
  --template-file mg-policy.bicep
```

### Tenant Deployment

For tenant-level resources:

```bash
# Deploy a Bicep file at tenant scope
az deployment tenant create \
  --location eastus \
  --template-file tenant-policy.bicep
```

## Parameter Files

Instead of specifying parameters inline, you can use parameter files:

```bash
# Deploy with a parameter file
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters parameters.json
```

### Sample Parameter File (parameters.json)

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "value": "mystorageaccount"
    },
    "location": {
      "value": "eastus"
    }
  }
}
```

## Handling Deployment Errors

When deployments fail, you can get detailed error information:

```bash
# Get deployment operations for troubleshooting
az deployment group show \
  --resource-group myResourceGroup \
  --name myDeploymentName
```

## Incremental vs. Complete Deployments

By default, Azure uses incremental mode, which adds to existing resources. Complete mode replaces the entire resource group.

```bash
# Complete mode deployment (use with caution!)
az deployment group create \
  --resource-group myResourceGroup \
  --mode Complete \
  --template-file main.bicep
```

⚠️ **Warning**: Complete mode will delete any resources in the resource group not defined in the template.

## Exercises

1. Try building and validating the [deployment example](./deployment-example.bicep) file
2. Run a what-if operation to see what changes would be made
3. Deploy the template to a resource group
4. Create a parameter file for the deployment

## Next Steps

Once you understand validation and deployment, proceed to [Custom Modules](../04-modules/README.md) to learn how to create reusable components.