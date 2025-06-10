#!/usr/bin/env powershell
# Azure AI Image Analysis Demo - AZD Deployment Script
# This script uses Azure Developer CLI (azd) for deployment

param(
    [string]$EnvironmentName = "",
    [string]$Location = "eastus",
    [switch]$SkipValidation = $false
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
    
    # Check Azure Developer CLI
    try {
        $null = Get-Command azd -ErrorAction Stop
    }
    catch {
        Write-Error "Azure Developer CLI (azd) is not installed. Please install it first."
        Write-Error "Install from: https://aka.ms/azure-dev/install"
        exit 1
    }
    
    # Check Docker
    try {
        $null = Get-Command docker -ErrorAction Stop
    }
    catch {
        Write-Error "Docker is not installed. Please install Docker Desktop first."
        exit 1
    }
    
    # Check if Docker is running
    try {
        docker info | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker not running"
        }
    }
    catch {
        Write-Error "Docker is not running. Please start Docker Desktop."
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

# Initialize azd environment
function Initialize-AzdEnvironment {
    Write-Status "Initializing Azure Developer CLI environment..."
    
    # Set default environment name if not provided
    if ([string]::IsNullOrEmpty($EnvironmentName)) {
        $timestamp = Get-Date -Format "yyyyMMddHHmm"
        $script:EnvironmentName = "img-analysis-$timestamp"
        Write-Warning "Environment name not provided. Using: $($script:EnvironmentName)"
    }
    else {
        $script:EnvironmentName = $EnvironmentName
    }
    
    # Check if already initialized
    $envExists = azd env list --output json | ConvertFrom-Json | Where-Object { $_.Name -eq $script:EnvironmentName }
    
    if (-not $envExists) {
        Write-Status "Creating new azd environment: $($script:EnvironmentName)"
        azd env new $script:EnvironmentName
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create azd environment"
            exit 1
        }
    }
    else {
        Write-Status "Using existing azd environment: $($script:EnvironmentName)"
        azd env select $script:EnvironmentName
    }
    
    # Set location
    azd env set AZURE_LOCATION $Location
    Write-Status "Environment: $($script:EnvironmentName), Location: $Location"
}

# Deploy with azd
function Deploy-WithAzd {
    Write-Status "Starting deployment with Azure Developer CLI..."
    
    if (-not $SkipValidation) {
        # Run preview first
        Write-Status "Running deployment preview..."
        azd provision --preview
        
        # Ask for confirmation
        Write-Host ""
        $confirmation = Read-Host "Do you want to proceed with the deployment? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Warning "Deployment cancelled by user"
            exit 0
        }
    }
    
    # Deploy infrastructure and application
    Write-Status "Deploying infrastructure and application... This may take 15-20 minutes."
    azd up
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployment completed successfully!"
        
        # Get service endpoints
        Write-Status "Retrieving service endpoints..."
        $endpoints = azd show --output json | ConvertFrom-Json
        
        if ($endpoints.services.'streamlit-app'.endpoint) {
            Write-Host ""
            Write-Host "🌐 Your Streamlit app is now running at:" -ForegroundColor Yellow
            Write-Host "   $($endpoints.services.'streamlit-app'.endpoint)" -ForegroundColor Cyan
            Write-Host ""
        }
        
        return $true
    }
    else {
        Write-Error "Deployment failed"
        return $false
    }
}

# Get deployment information
function Get-DeploymentInfo {
    Write-Status "Retrieving deployment information..."
    
    try {
        # Get azd environment variables
        $envVars = azd env get-values --output json | ConvertFrom-Json
        
        # Create .env file for local development
        Write-Status "Creating .env file for local development..."
        
        $envContent = @"
# Azure AI Image Analysis Demo - Environment Variables
# Generated on $(Get-Date)

AZURE_ENV_NAME=$($script:EnvironmentName)
AZURE_LOCATION=$Location
RESOURCE_GROUP_NAME=$($envVars.AZURE_RESOURCE_GROUP)
AZURE_OPENAI_ENDPOINT=$($envVars.AZURE_OPENAI_ENDPOINT)
AZURE_CLIENT_ID=$($envVars.AZURE_CLIENT_ID)

# Container Registry
AZURE_CONTAINER_REGISTRY_NAME=$($envVars.AZURE_CONTAINER_REGISTRY_NAME)
AZURE_CONTAINER_REGISTRY_LOGIN_SERVER=$($envVars.AZURE_CONTAINER_REGISTRY_LOGIN_SERVER)

# App Service
AZURE_APP_SERVICE_NAME=$($envVars.AZURE_APP_SERVICE_NAME)
AZURE_APP_SERVICE_URL=$($envVars.AZURE_APP_SERVICE_URL)
"@
        
        $envContent | Out-File -FilePath ".env" -Encoding UTF8
        Write-Success "Environment file created: .env"
        
        # Display summary
        Write-Host ""
        Write-Host "========================= DEPLOYMENT SUMMARY =========================" -ForegroundColor Cyan
        Write-Host "✓ Resource Group: " -ForegroundColor Green -NoNewline
        Write-Host $envVars.AZURE_RESOURCE_GROUP
        Write-Host "✓ OpenAI Endpoint: " -ForegroundColor Green -NoNewline
        Write-Host $envVars.AZURE_OPENAI_ENDPOINT
        Write-Host "✓ Container Registry: " -ForegroundColor Green -NoNewline
        Write-Host $envVars.AZURE_CONTAINER_REGISTRY_LOGIN_SERVER
        Write-Host "✓ App Service: " -ForegroundColor Green -NoNewline
        Write-Host $envVars.AZURE_APP_SERVICE_URL
        Write-Host "===================================================================" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Warning "Could not retrieve deployment information: $($_.Exception.Message)"
    }
}

# Main function
function Main {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Azure AI Image Analysis Demo" -ForegroundColor Cyan
    Write-Host "  AZD Deployment (Container + App Service)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-Prerequisites
    Initialize-AzdEnvironment
    $success = Deploy-WithAzd
    
    if ($success) {
        Get-DeploymentInfo
        
        Write-Host ""
        Write-Success "Deployment completed successfully!"
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. The containerized app is now deployed and running in Azure App Service"
        Write-Host "2. The app uses managed identity for secure authentication to Azure OpenAI"
        Write-Host "3. Container images are stored in Azure Container Registry"
        Write-Host ""
        Write-Host "To update the application:" -ForegroundColor Yellow
        Write-Host "1. Make changes to your code"
        Write-Host "2. Run: azd deploy"
        Write-Host ""
        Write-Host "To tear down resources:" -ForegroundColor Yellow
        Write-Host "1. Run: azd down"
        Write-Host ""
    }
    else {
        Write-Error "Deployment failed. Check the error messages above."
        exit 1
    }
}

# Run main function
Main
