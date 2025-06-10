# CI/CD Pipeline for Azure AI Image Analysis Demo

This workflow automatically builds and deploys the containerized application whenever code is pushed to the repository.

## 🚀 Features

- **Automated Container Build**: Builds Docker image on every push
- **Azure Container Registry**: Pushes images to ACR automatically
- **App Service Deployment**: Deploys updated containers to Azure App Service
- **Branch Protection**: Different workflows for different branches
- **Security**: Uses managed identity and OIDC for secure authentication

## 📋 Setup Instructions

### 1. GitHub Repository Setup

First, ensure your code is in a GitHub repository:

```bash
# Initialize git repository (if not already done)
git init
git add .
git commit -m "Initial commit with containerized deployment"

# Add GitHub remote (replace with your repository URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

### 2. Azure Service Principal Setup

Create a service principal for GitHub Actions:

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac --name "github-actions-image-analysis" \
  --role "Contributor" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID" \
  --sdk-auth

# The output will look like this - save it for GitHub secrets:
{
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret",
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"
}
```

### 3. GitHub Secrets Configuration

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CREDENTIALS` | Full JSON output from service principal creation | Complete Azure credentials |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID | For resource targeting |
| `AZURE_RESOURCE_GROUP` | Your resource group name | Where resources are deployed |
| `AZURE_CONTAINER_REGISTRY` | Your ACR name (without .azurecr.io) | Container registry name |
| `AZURE_APP_SERVICE_NAME` | Your App Service name | For deployment targeting |

### 4. Optional: Azure OIDC Setup (More Secure)

For enhanced security, you can use OIDC instead of service principal secrets:

```bash
# Create app registration for OIDC
az ad app create --display-name "github-actions-oidc-image-analysis"

# Get the application ID
APP_ID=$(az ad app list --display-name "github-actions-oidc-image-analysis" --query "[0].appId" -o tsv)

# Create service principal
az ad sp create --id $APP_ID

# Create federated credentials for your GitHub repository
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_USERNAME/YOUR_REPO_NAME:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Assign Contributor role
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

## 🔄 Workflow Triggers

### Automatic Triggers
- **Push to main**: Full build, test, and deployment
- **Pull Request**: Build and test only
- **Manual trigger**: On-demand deployment

### Manual Deployment
You can trigger deployments manually from GitHub Actions tab or using:

```bash
gh workflow run deploy-to-azure.yml
```

## 🏗️ Pipeline Stages

### 1. Build Stage
- Checkout code
- Set up Docker Buildx
- Build container image
- Run security scans
- Push to Azure Container Registry

### 2. Deploy Stage
- Deploy to Azure App Service
- Update container image
- Run health checks
- Notify on completion

### 3. Test Stage
- Run application tests
- Verify deployment health
- Performance checks

## 📊 Monitoring

The pipeline provides:
- **Build Status**: GitHub Actions status badges
- **Deployment Logs**: Detailed deployment information
- **Health Checks**: Automatic application health verification
- **Notifications**: Slack/Teams integration (optional)

## 🔧 Customization

### Environment-Specific Deployments

Modify `.github/workflows/deploy-to-azure.yml` to support multiple environments:

```yaml
strategy:
  matrix:
    environment: [staging, production]
```

### Security Scanning

The pipeline includes:
- Container vulnerability scanning
- Secret detection
- Dependency checking
- License compliance

## 🆘 Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify GitHub secrets are set correctly
   - Check service principal permissions
   - Ensure subscription ID is correct

2. **Container Build Failed**
   - Check Dockerfile syntax
   - Verify base image availability
   - Review build logs in GitHub Actions

3. **Deployment Failed**
   - Verify resource group and App Service exist
   - Check ACR permissions
   - Review Azure Activity Logs

### Getting Help

- Check GitHub Actions logs for detailed error messages
- Review Azure Activity Logs in the portal
- Verify all secrets and permissions are configured correctly

## 🔄 Updating the Pipeline

To modify the pipeline:

1. Edit `.github/workflows/deploy-to-azure.yml`
2. Commit and push changes
3. Monitor the updated workflow execution

The pipeline will automatically use the latest workflow definition on subsequent runs.
