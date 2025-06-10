# Azure AI Image Analysis Demo - Deployment Script (PowerShell)
# This script deploys the entire Azure infrastructure automatically

param(
    [string]$EnvironmentName = "",
    [string]$Location = "eastus",
    [switch]$SkipValidation = $false,
    [switch]$Force = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check Azure CLI
    try {
        $null = Get-Command az -ErrorAction Stop
    }
    catch {
        Write-Error "Azure CLI is not installed. Please install it first."
        exit 1
    }
    
    # Check if logged in to Azure
    try {
        $null = az account show --query id -o tsv 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Not logged in"
        }
    }
    catch {
        Write-Error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

# Set default values
function Set-Defaults {
    # Get current timestamp for unique naming
    $timestamp = Get-Date -Format "yyyyMMddHHmm"
    
    # Set default environment name if not provided
    if ([string]::IsNullOrEmpty($EnvironmentName)) {
        $script:EnvironmentName = "img-analysis-$timestamp"
        Write-Warning "Environment name not provided. Using: $($script:EnvironmentName)"
    }
    else {
        $script:EnvironmentName = $EnvironmentName
    }
    
    # Set resource group name
    $script:ResourceGroupName = "rg-$($script:EnvironmentName)"
    
    Write-Status "Environment Name: $($script:EnvironmentName)"
    Write-Status "Location: $Location"
    Write-Status "Resource Group: $($script:ResourceGroupName)"
}

# Deploy infrastructure
function Deploy-Infrastructure {
    Write-Status "Starting infrastructure deployment..."
    
    # Get current subscription
    $subscriptionId = az account show --query id -o tsv
    Write-Status "Deploying to subscription: $subscriptionId"
    
    # Create deployment name
    $deploymentName = "deploy-$($script:EnvironmentName)-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Status "Deployment name: $deploymentName"
    
    if (-not $SkipValidation) {
        # Validate deployment first
        Write-Status "Validating deployment..."
        
        $validateArgs = @(
            "deployment", "sub", "validate",
            "--location", $Location,
            "--template-file", "infra/main.bicep",
            "--parameters", "infra/main.parameters.json",
            "--parameters", "environmentName=$($script:EnvironmentName)",
            "location=$Location",
            "resourceGroupName=$($script:ResourceGroupName)"
        )
        
        & az @validateArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Deployment validation passed"
        }
        else {
            Write-Error "Deployment validation failed"
            exit 1
        }
        
        # What-if analysis
        Write-Status "Running what-if analysis..."
        
        $whatIfArgs = @(
            "deployment", "sub", "what-if",
            "--location", $Location,
            "--template-file", "infra/main.bicep",
            "--parameters", "infra/main.parameters.json",
            "--parameters", "environmentName=$($script:EnvironmentName)",
            "location=$Location",
            "resourceGroupName=$($script:ResourceGroupName)"
        )
        
        & az @whatIfArgs
    }
    
    # Ask for confirmation unless Force is specified
    if (-not $Force) {
        Write-Host ""
        $confirmation = Read-Host "Do you want to proceed with the deployment? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Warning "Deployment cancelled by user"
            exit 0
        }
    }
    
    # Execute deployment
    Write-Status "Executing deployment... This may take 10-15 minutes."
    
    $deployArgs = @(
        "deployment", "sub", "create",
        "--name", $deploymentName,
        "--location", $Location,
        "--template-file", "infra/main.bicep",
        "--parameters", "infra/main.parameters.json",
        "--parameters", "environmentName=$($script:EnvironmentName)",
        "location=$Location",
        "resourceGroupName=$($script:ResourceGroupName)"
    )
    
    & az @deployArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Infrastructure deployment completed successfully!"
        return $deploymentName
    }
    else {
        Write-Error "Infrastructure deployment failed"
        exit 1
    }
}

# Get deployment outputs
function Get-DeploymentOutputs {
    param([string]$DeploymentName)
    
    Write-Status "Retrieving deployment outputs..."
    
    try {
        # Get outputs
        $outputs = az deployment sub show --name $DeploymentName --query properties.outputs -o json | ConvertFrom-Json
        
        # Extract key values
        $resourceGroup = $outputs.resourceGroupName.value
        $openAiEndpoint = $outputs.openAiEndpoint.value
        $clientId = $outputs.userManagedIdentityClientId.value
        
        # Create .env file for local development
        Write-Status "Creating .env file for local development..."
        
        $envContent = @"
# Azure AI Image Analysis Demo - Environment Variables
# Generated on $(Get-Date)

AZURE_ENV_NAME=$($script:EnvironmentName)
AZURE_LOCATION=$Location
RESOURCE_GROUP_NAME=$resourceGroup
AZURE_OPENAI_ENDPOINT=$openAiEndpoint
AZURE_CLIENT_ID=$clientId

# For local development, you may need to set these:
# AZURE_TENANT_ID=your_tenant_id
# AZURE_SUBSCRIPTION_ID=your_subscription_id
"@
        
        $envContent | Out-File -FilePath ".env" -Encoding UTF8
        Write-Success "Environment file created: .env"
        
        # Display summary
        Write-Host ""
        Write-Host "========================= DEPLOYMENT SUMMARY =========================" -ForegroundColor Cyan
        Write-Host "✓ Resource Group: " -ForegroundColor Green -NoNewline
        Write-Host $resourceGroup
        Write-Host "✓ OpenAI Endpoint: " -ForegroundColor Green -NoNewline
        Write-Host $openAiEndpoint
        Write-Host "✓ Managed Identity Client ID: " -ForegroundColor Green -NoNewline
        Write-Host $clientId
        Write-Host "===================================================================" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Warning "Could not retrieve deployment outputs. Manual configuration may be required."
        Write-Warning "Error: $($_.Exception.Message)"
    }
}

# Main function
function Main {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Azure AI Image Analysis Demo Deployment" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-Prerequisites
    Set-Defaults
    $deploymentName = Deploy-Infrastructure
    Get-DeploymentOutputs -DeploymentName $deploymentName
    
    Write-Host ""
    Write-Success "Deployment completed successfully!"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. The infrastructure is now deployed and ready to use"
    Write-Host "2. Update your application configuration with the values from .env"
    Write-Host "3. If running locally, ensure you're logged in with 'az login'"
    Write-Host "4. If deploying to Azure (App Service, etc.), configure managed identity"
    Write-Host ""
    Write-Host "For the Streamlit app:" -ForegroundColor Yellow
    Write-Host "1. Install dependencies: pip install -r requirements.txt"
    Write-Host "2. Run the app: streamlit run streamlit_app.py"
    Write-Host ""
}

# Run main function
Main
