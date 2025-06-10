# Azure AI Image Analysis Demo - Deployment Guide

This guide explains how to deploy the Azure infrastructure for the Image Analysis Demo automatically.

## Prerequisites

Before running the deployment script, ensure you have:

1. **Azure CLI installed** - [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
2. **Logged in to Azure** - Run `az login` to authenticate
3. **Required permissions** - Your account must have permissions to:
   - Create resource groups
   - Create Azure OpenAI services
   - Create Machine Learning workspaces
   - Assign RBAC roles

## Quick Deployment

### Option 1: PowerShell (Recommended for Windows)

```powershell
# Basic deployment with defaults
.\deploy.ps1

# Specify custom environment name and location
.\deploy.ps1 -EnvironmentName "myapp" -Location "eastus2"

# Skip validation and force deployment (for CI/CD)
.\deploy.ps1 -EnvironmentName "myapp" -SkipValidation -Force
```

### Option 2: Bash (Linux/macOS/WSL)

```bash
# Make script executable
chmod +x deploy.sh

# Basic deployment with defaults
./deploy.sh

# Set environment variables for custom deployment
export AZURE_ENV_NAME="myapp"
export AZURE_LOCATION="eastus2"
./deploy.sh
```

## What Gets Deployed

The deployment script creates:

1. **Resource Group** - Container for all resources
2. **Azure OpenAI Service** - With GPT-4o model deployment
3. **User-Assigned Managed Identity** - For secure authentication
4. **Azure AI Hub** - For AI project management
5. **Azure AI Project** - Connected to the hub
6. **Storage Account** - Required for AI Hub
7. **Key Vault** - For secure credential storage
8. **Application Insights** - For monitoring and logging
9. **RBAC Role Assignments** - Proper permissions for managed identity

## Configuration

After deployment, the script creates a `.env` file with the following variables:

```
AZURE_ENV_NAME=your-environment-name
AZURE_LOCATION=eastus
RESOURCE_GROUP_NAME=rg-your-environment-name
AZURE_OPENAI_ENDPOINT=https://your-openai-service.openai.azure.com/
AZURE_CLIENT_ID=your-managed-identity-client-id
```

## Using the Deployed Infrastructure

### For Local Development

1. Ensure you're logged in to Azure: `az login`
2. The Streamlit app will automatically use your Azure CLI credentials
3. Run the app: `streamlit run streamlit_app.py`

### For Production Deployment

1. Deploy your application to Azure (App Service, Container Instances, etc.)
2. Configure the managed identity created by the script
3. Set the environment variables from the `.env` file

## Script Parameters

### PowerShell Script (`deploy.ps1`)

- `-EnvironmentName`: Custom name for your environment (default: auto-generated)
- `-Location`: Azure region (default: "eastus")
- `-SkipValidation`: Skip deployment validation (for faster deployment)
- `-Force`: Skip confirmation prompts (for automation)

### Bash Script (`deploy.sh`)

Use environment variables:
- `AZURE_ENV_NAME`: Custom name for your environment
- `AZURE_LOCATION`: Azure region

## Troubleshooting

### Common Issues

1. **"Not logged in to Azure"**
   - Solution: Run `az login` and authenticate

2. **"Insufficient permissions"**
   - Solution: Ensure your account has Contributor or Owner role

3. **"Quota exceeded"**
   - Solution: Request quota increase or choose a different region

4. **"Resource name already exists"**
   - Solution: Use a different environment name

### Getting Help

If deployment fails:

1. Check the error message for specific issues
2. Verify your Azure permissions
3. Try a different Azure region
4. Ensure all prerequisites are met

## Manual Cleanup

To remove all deployed resources:

```powershell
# Replace with your actual resource group name
az group delete --name "rg-your-environment-name" --yes --no-wait
```

## Architecture Overview

```
Resource Group
├── Azure OpenAI Service (GPT-4o)
├── User-Assigned Managed Identity
├── Azure AI Hub
├── Azure AI Project
├── Storage Account
├── Key Vault
└── Application Insights
```

The managed identity is granted:
- `Cognitive Services OpenAI User` role on the OpenAI service
- `Key Vault Secrets User` role on the Key Vault

This ensures secure, keyless authentication for your applications.
