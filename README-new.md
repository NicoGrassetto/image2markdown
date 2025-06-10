# Azure AI Image Analysis Demo with Containerized Deployment

A comprehensive Streamlit application that leverages Azure OpenAI's GPT-4o vision model for intelligent image analysis, now deployed using Azure Container Registry and Azure App Service.

## 🏗️ Architecture

This solution now includes:

- **Azure OpenAI Service** - GPT-4o model for image analysis
- **Azure Container Registry (ACR)** - Stores the containerized Streamlit application
- **Azure App Service** - Hosts the containerized application with managed identity
- **User-Assigned Managed Identity** - Secure authentication without API keys
- **Azure AI Hub & Project** - AI project management and monitoring
- **Storage Account** - Required for AI Hub functionality
- **Key Vault** - Secure credential storage
- **Application Insights** - Monitoring and logging

## 🚀 Deployment Options

### Option 1: Azure Developer CLI (Recommended)

The fastest way to deploy everything:

```powershell
# Prerequisites: Install azd and Docker Desktop
# https://aka.ms/azure-dev/install

# Deploy everything
.\deploy-azd.ps1

# Or with custom settings
.\deploy-azd.ps1 -EnvironmentName "my-app" -Location "eastus2"
```

### Option 2: Traditional Azure CLI

For more control over the deployment process:

```powershell
# Deploy infrastructure and build container
.\deploy.ps1

# Or with custom settings
.\deploy.ps1 -EnvironmentName "my-app" -Location "eastus2" -Force
```

## 📦 Container Details

The application is containerized using Docker with:

- **Base Image**: `python:3.11-slim`
- **Security**: Non-root user execution
- **Health Checks**: Built-in application health monitoring
- **Port**: 8501 (Streamlit default)
- **Environment**: Optimized for Azure App Service

## 🔐 Security Features

- ✅ **Managed Identity Authentication** - No API keys required
- ✅ **HTTPS Only** - All traffic encrypted
- ✅ **RBAC Permissions** - Least privilege access
- ✅ **Container Security** - Non-root execution
- ✅ **Network Security** - Azure-native networking

## 🛠️ Development Workflow

### Local Development

1. **Clone and setup:**
   ```bash
   git clone <repository>
   cd image-analysis-demo
   pip install -r requirements.txt
   ```

2. **Run locally:**
   ```bash
   # Make sure you're logged in to Azure
   az login
   streamlit run streamlit_app.py
   ```

### Update Deployed Application

After making code changes:

**With AZD:**
```powershell
azd deploy
```

**With traditional deployment:**
```powershell
# Get registry info from .env file
docker build -t <registry>.azurecr.io/streamlit-app:latest .
docker push <registry>.azurecr.io/streamlit-app:latest

# Restart the App Service
az webapp restart --name <app-name> --resource-group <rg-name>
```

## 📊 Monitoring

Access your application logs and metrics:

- **Application URL**: Check `.env` file or deployment output
- **Azure Portal**: Monitor App Service metrics and logs
- **Application Insights**: Detailed telemetry and performance data
- **Container Logs**: `az webapp log tail --name <app-name> --resource-group <rg-name>`

## 🧪 Testing

Run the test suite:

```bash
python -m pytest test_streamlit.py -v
```

## 🔧 Configuration

Environment variables (automatically set in App Service):

- `AZURE_CLIENT_ID` - Managed identity client ID
- `AZURE_OPENAI_ENDPOINT` - OpenAI service endpoint
- `WEBSITES_PORT` - Container port (8501)
- `WEBSITES_ENABLE_APP_SERVICE_STORAGE` - Disabled for containers

## 📋 Prerequisites

- **Azure Subscription** with appropriate permissions
- **Docker Desktop** installed and running
- **Azure CLI** or **Azure Developer CLI**
- **PowerShell 7+** (for deployment scripts)

## 🆘 Troubleshooting

### Common Issues

1. **Docker not running**: Start Docker Desktop
2. **Authentication failed**: Run `az login`
3. **Container build fails**: Check Dockerfile and .dockerignore
4. **App Service not starting**: Check container logs in Azure Portal

### Getting Help

- Check deployment logs in Azure Portal
- Review Application Insights for runtime errors
- Use `azd logs` for AZD deployments
- Verify managed identity permissions

## 🧹 Cleanup

Remove all resources:

**With AZD:**
```powershell
azd down
```

**With traditional deployment:**
```powershell
az group delete --name "rg-<your-environment-name>" --yes --no-wait
```

## ✨ Features

- 🔍 **Image Analysis**: Upload and analyze images using GPT-4o vision
- 🔐 **Secure Authentication**: Uses Azure managed identity (no API keys!)
- 🎯 **Customizable Prompts**: Flexible analysis with custom instructions
- 📊 **Rich Interface**: Clean, intuitive Streamlit web interface
- 🛡️ **Enterprise Ready**: Built for production with proper security
- 🐳 **Containerized**: Consistent deployment across environments
- 📈 **Scalable**: Auto-scaling with Azure App Service

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
