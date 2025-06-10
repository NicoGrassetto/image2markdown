#!/bin/bash

# CI/CD Setup Validation Script
# This script validates that all prerequisites are in place for automated CI/CD

set -e

echo "🔍 Validating CI/CD Prerequisites for Azure AI Image Analysis Demo"
echo "=================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation functions
validate_azure_cli() {
    echo -n "🔧 Checking Azure CLI installation... "
    if command -v az &> /dev/null; then
        echo -e "${GREEN}✅ Installed${NC}"
        az --version | head -1
    else
        echo -e "${RED}❌ Azure CLI not found${NC}"
        echo "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
}

validate_azure_login() {
    echo -n "🔐 Checking Azure login status... "
    if az account show &> /dev/null; then
        SUBSCRIPTION=$(az account show --query name -o tsv)
        echo -e "${GREEN}✅ Logged in to: $SUBSCRIPTION${NC}"
    else
        echo -e "${RED}❌ Not logged in to Azure${NC}"
        echo "Please run: az login"
        exit 1
    fi
}

validate_docker() {
    echo -n "🐳 Checking Docker installation... "
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Installed${NC}"
        docker --version
    else
        echo -e "${RED}❌ Docker not found${NC}"
        echo "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
}

validate_github_repo() {
    echo -n "📝 Checking GitHub repository... "
    if [ -d ".git" ] && git remote get-url origin &> /dev/null; then
        REPO_URL=$(git remote get-url origin)
        echo -e "${GREEN}✅ Found: $REPO_URL${NC}"
    else
        echo -e "${YELLOW}⚠️  No GitHub remote found${NC}"
        echo "Initialize with: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    fi
}

validate_azure_resources() {
    echo "🏗️  Checking Azure resources..."
    
    # Check Resource Group
    echo -n "  - Resource Group: "
    RG_NAME=$(az group list --query "[?contains(name, 'image-analysis') || contains(name, 'demo')].name" -o tsv | head -1)
    if [ -n "$RG_NAME" ]; then
        echo -e "${GREEN}✅ $RG_NAME${NC}"
        export AZURE_RESOURCE_GROUP="$RG_NAME"
    else
        echo -e "${RED}❌ Not found${NC}"
        echo "     Please deploy infrastructure first: ./deploy-azd.ps1"
        exit 1
    fi
    
    # Check Container Registry
    echo -n "  - Container Registry: "
    ACR_NAME=$(az acr list --resource-group "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null)
    if [ -n "$ACR_NAME" ]; then
        echo -e "${GREEN}✅ $ACR_NAME${NC}"
        export AZURE_CONTAINER_REGISTRY="$ACR_NAME"
    else
        echo -e "${RED}❌ Not found${NC}"
        echo "     Please deploy infrastructure first: ./deploy-azd.ps1"
        exit 1
    fi
    
    # Check App Service
    echo -n "  - App Service: "
    APP_NAME=$(az webapp list --resource-group "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null)
    if [ -n "$APP_NAME" ]; then
        echo -e "${GREEN}✅ $APP_NAME${NC}"
        export AZURE_APP_SERVICE_NAME="$APP_NAME"
    else
        echo -e "${RED}❌ Not found${NC}"
        echo "     Please deploy infrastructure first: ./deploy-azd.ps1"
        exit 1
    fi
}

create_service_principal() {
    echo "🔑 Creating Service Principal for GitHub Actions..."
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SP_NAME="github-actions-image-analysis-$(date +%s)"
    
    echo "Creating service principal: $SP_NAME"
    SP_OUTPUT=$(az ad sp create-for-rbac \
        --name "$SP_NAME" \
        --role "Contributor" \
        --scopes "/subscriptions/$SUBSCRIPTION_ID" \
        --json-auth)
    
    echo -e "${GREEN}✅ Service Principal created successfully!${NC}"
    echo ""
    echo "🔒 Add this to GitHub Secrets as AZURE_CREDENTIALS:"
    echo "================================================="
    echo "$SP_OUTPUT"
    echo "================================================="
    echo ""
}

generate_github_secrets() {
    echo "📋 GitHub Secrets Configuration"
    echo "==============================="
    echo ""
    echo "Add these secrets to your GitHub repository:"
    echo "(Settings > Secrets and variables > Actions)"
    echo ""
    echo "Secret Name: AZURE_CREDENTIALS"
    echo "Value: [Service Principal JSON from above]"
    echo ""
    echo "Secret Name: AZURE_CONTAINER_REGISTRY"
    echo "Value: $AZURE_CONTAINER_REGISTRY"
    echo ""
    echo "Secret Name: AZURE_RESOURCE_GROUP"
    echo "Value: $AZURE_RESOURCE_GROUP"
    echo ""
    echo "Secret Name: AZURE_APP_SERVICE_NAME"
    echo "Value: $AZURE_APP_SERVICE_NAME"
    echo ""
}

test_container_build() {
    echo "🐳 Testing container build locally..."
    
    if [ -f "Dockerfile" ]; then
        echo "Building test container..."
        if docker build -t streamlit-app-test . --quiet; then
            echo -e "${GREEN}✅ Container build successful${NC}"
            docker rmi streamlit-app-test &> /dev/null || true
        else
            echo -e "${RED}❌ Container build failed${NC}"
            echo "Please check your Dockerfile"
            exit 1
        fi
    else
        echo -e "${RED}❌ Dockerfile not found${NC}"
        exit 1
    fi
}

main() {
    validate_azure_cli
    validate_azure_login
    validate_docker
    validate_github_repo
    validate_azure_resources
    test_container_build
    
    echo ""
    echo -e "${GREEN}🎉 Prerequisites validation completed successfully!${NC}"
    echo ""
    
    read -p "Do you want to create a service principal for GitHub Actions? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_service_principal
        generate_github_secrets
    else
        generate_github_secrets
    fi
    
    echo ""
    echo "🚀 Next Steps:"
    echo "1. Configure GitHub secrets (shown above)"
    echo "2. Push your code to GitHub"
    echo "3. Watch the CI/CD pipeline run automatically!"
    echo ""
    echo "📖 For detailed setup instructions, see: AUTOMATED_CICD_GUIDE.md"
}

# Run main function
main "$@"
