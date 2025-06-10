#!/bin/bash

# Azure AI Image Analysis Demo - Deployment Script
# This script deploys the entire Azure infrastructure automatically

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Set default values
set_defaults() {
    # Get current date for unique naming
    TIMESTAMP=$(date +%Y%m%d%H%M)
    
    # Set default environment name if not provided
    if [ -z "$AZURE_ENV_NAME" ]; then
        export AZURE_ENV_NAME="img-analysis-${TIMESTAMP}"
        print_warning "AZURE_ENV_NAME not set. Using: $AZURE_ENV_NAME"
    fi
    
    # Set default location if not provided
    if [ -z "$AZURE_LOCATION" ]; then
        export AZURE_LOCATION="eastus"
        print_warning "AZURE_LOCATION not set. Using: $AZURE_LOCATION"
    fi
    
    # Set resource group name
    export RESOURCE_GROUP_NAME="rg-${AZURE_ENV_NAME}"
    
    print_status "Environment Name: $AZURE_ENV_NAME"
    print_status "Location: $AZURE_LOCATION"
    print_status "Resource Group: $RESOURCE_GROUP_NAME"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Starting infrastructure deployment..."
    
    # Get current subscription
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_status "Deploying to subscription: $SUBSCRIPTION_ID"
    
    # Create deployment name
    DEPLOYMENT_NAME="deploy-${AZURE_ENV_NAME}-$(date +%Y%m%d-%H%M%S)"
    
    print_status "Deployment name: $DEPLOYMENT_NAME"
    
    # Validate deployment first
    print_status "Validating deployment..."
    az deployment sub validate \
        --location "$AZURE_LOCATION" \
        --template-file "infra/main.bicep" \
        --parameters "infra/main.parameters.json" \
        --parameters environmentName="$AZURE_ENV_NAME" \
                    location="$AZURE_LOCATION" \
                    resourceGroupName="$RESOURCE_GROUP_NAME"
    
    if [ $? -eq 0 ]; then
        print_success "Deployment validation passed"
    else
        print_error "Deployment validation failed"
        exit 1
    fi
    
    # What-if analysis
    print_status "Running what-if analysis..."
    az deployment sub what-if \
        --location "$AZURE_LOCATION" \
        --template-file "infra/main.bicep" \
        --parameters "infra/main.parameters.json" \
        --parameters environmentName="$AZURE_ENV_NAME" \
                    location="$AZURE_LOCATION" \
                    resourceGroupName="$RESOURCE_GROUP_NAME"
    
    # Ask for confirmation
    echo
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled by user"
        exit 0
    fi
    
    # Execute deployment
    print_status "Executing deployment... This may take 10-15 minutes."
    az deployment sub create \
        --name "$DEPLOYMENT_NAME" \
        --location "$AZURE_LOCATION" \
        --template-file "infra/main.bicep" \
        --parameters "infra/main.parameters.json" \
        --parameters environmentName="$AZURE_ENV_NAME" \
                    location="$AZURE_LOCATION" \
                    resourceGroupName="$RESOURCE_GROUP_NAME"
    
    if [ $? -eq 0 ]; then
        print_success "Infrastructure deployment completed successfully!"
    else
        print_error "Infrastructure deployment failed"
        exit 1
    fi
}

# Get deployment outputs
get_outputs() {
    print_status "Retrieving deployment outputs..."
    
    # Get the latest deployment
    DEPLOYMENT_NAME=$(az deployment sub list --query "[?contains(name, 'deploy-${AZURE_ENV_NAME}')].name | [0]" -o tsv)
    
    if [ -z "$DEPLOYMENT_NAME" ]; then
        print_warning "Could not find deployment outputs. Manual configuration may be required."
        return
    fi
    
    # Get outputs
    OUTPUTS=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query properties.outputs -o json)
    
    # Extract key values
    RESOURCE_GROUP=$(echo $OUTPUTS | jq -r '.resourceGroupName.value // empty')
    OPENAI_ENDPOINT=$(echo $OUTPUTS | jq -r '.openAiEndpoint.value // empty')
    CLIENT_ID=$(echo $OUTPUTS | jq -r '.userManagedIdentityClientId.value // empty')
    
    # Create .env file for local development
    print_status "Creating .env file for local development..."
    cat > .env << EOF
# Azure AI Image Analysis Demo - Environment Variables
# Generated on $(date)

AZURE_ENV_NAME=${AZURE_ENV_NAME}
AZURE_LOCATION=${AZURE_LOCATION}
RESOURCE_GROUP_NAME=${RESOURCE_GROUP}
AZURE_OPENAI_ENDPOINT=${OPENAI_ENDPOINT}
AZURE_CLIENT_ID=${CLIENT_ID}

# For local development, you may need to set these:
# AZURE_TENANT_ID=your_tenant_id
# AZURE_SUBSCRIPTION_ID=your_subscription_id
EOF
    
    print_success "Environment file created: .env"
    
    # Display summary
    echo
    echo "========================= DEPLOYMENT SUMMARY ========================="
    echo -e "${GREEN}✓ Resource Group:${NC} ${RESOURCE_GROUP}"
    echo -e "${GREEN}✓ OpenAI Endpoint:${NC} ${OPENAI_ENDPOINT}"
    echo -e "${GREEN}✓ Managed Identity Client ID:${NC} ${CLIENT_ID}"
    echo "==================================================================="
    echo
}

# Main deployment function
main() {
    echo "=========================================="
    echo "  Azure AI Image Analysis Demo Deployment"
    echo "=========================================="
    echo
    
    check_prerequisites
    set_defaults
    deploy_infrastructure
    get_outputs
    
    echo
    print_success "Deployment completed successfully!"
    echo
    echo "Next steps:"
    echo "1. The infrastructure is now deployed and ready to use"
    echo "2. Update your application configuration with the values from .env"
    echo "3. If running locally, ensure you're logged in with 'az login'"
    echo "4. If deploying to Azure (App Service, etc.), configure managed identity"
    echo
    echo "For the Streamlit app:"
    echo "1. Install dependencies: pip install -r requirements.txt"
    echo "2. Run the app: streamlit run streamlit_app.py"
    echo
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
