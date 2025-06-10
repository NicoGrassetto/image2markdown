# CI/CD Setup Validation Script for Windows
# This script validates that all prerequisites are in place for automated CI/CD

param(
    [switch]$CreateServicePrincipal,
    [switch]$ShowSecretsOnly
)

# Write colored output
function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Red", "Green", "Yellow", "White")]
        [string]$Color = "White"
    )
    
    $originalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Message
    $Host.UI.RawUI.ForegroundColor = $originalColor
}

Write-Host "🔍 Validating CI/CD Prerequisites for Azure AI Image Analysis Demo" -ForegroundColor Cyan
Write-Host "=================================================================="

# Validation functions
function Test-AzureCLI {
    Write-Host "🔧 Checking Azure CLI installation... " -NoNewline
    try {
        $azVersion = az --version 2>$null | Select-Object -First 1
        Write-ColorOutput "✅ Installed" -Color Green
        Write-Host "   $azVersion"
        return $true
    }
    catch {
        Write-ColorOutput "❌ Azure CLI not found" -Color Red
        Write-Host "   Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return $false
    }
}

function Test-AzureLogin {
    Write-Host "🔐 Checking Azure login status... " -NoNewline
    try {
        $subscription = az account show --query name -o tsv 2>$null
        if ($subscription) {
            Write-ColorOutput "✅ Logged in to: $subscription" -Color Green
            return $true
        }
        else {
            Write-ColorOutput "❌ Not logged in to Azure" -Color Red
            Write-Host "   Please run: az login"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Not logged in to Azure" -Color Red
        Write-Host "   Please run: az login"
        return $false
    }
}

function Test-Docker {
    Write-Host "🐳 Checking Docker installation... " -NoNewline
    try {
        $dockerVersion = docker --version 2>$null
        Write-ColorOutput "✅ Installed" -Color Green
        Write-Host "   $dockerVersion"
        return $true
    }
    catch {
        Write-ColorOutput "❌ Docker not found" -Color Red
        Write-Host "   Please install Docker: https://docs.docker.com/get-docker/"
        return $false
    }
}

function Test-GitHubRepo {
    Write-Host "📝 Checking GitHub repository... " -NoNewline
    try {
        if (Test-Path ".git" -PathType Container) {
            $repoUrl = git remote get-url origin 2>$null
            if ($repoUrl) {
                Write-ColorOutput "✅ Found: $repoUrl" -Color Green
                return $true
            }
        }
        Write-ColorOutput "⚠️  No GitHub remote found" -Color Yellow
        Write-Host "   Initialize with: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        return $false
    }
    catch {
        Write-ColorOutput "⚠️  No GitHub remote found" -Color Yellow
        Write-Host "   Initialize with: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        return $false
    }
}

function Test-AzureResources {
    Write-Host "🏗️  Checking Azure resources..."
    
    # Check Resource Group
    Write-Host "  - Resource Group: " -NoNewline
    try {
        $rgName = az group list --query "[?contains(name, 'image-analysis') || contains(name, 'demo')].name" -o tsv 2>$null | Select-Object -First 1
        if ($rgName) {
            Write-ColorOutput "✅ $rgName" -Color Green
            $script:AZURE_RESOURCE_GROUP = $rgName
        }
        else {
            Write-ColorOutput "❌ Not found" -Color Red
            Write-Host "     Please deploy infrastructure first: .\deploy-azd.ps1"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Not found" -Color Red
        Write-Host "     Please deploy infrastructure first: .\deploy-azd.ps1"
        return $false
    }
    
    # Check Container Registry
    Write-Host "  - Container Registry: " -NoNewline
    try {
        $acrName = az acr list --resource-group $script:AZURE_RESOURCE_GROUP --query "[0].name" -o tsv 2>$null
        if ($acrName) {
            Write-ColorOutput "✅ $acrName" -Color Green
            $script:AZURE_CONTAINER_REGISTRY = $acrName
        }
        else {
            Write-ColorOutput "❌ Not found" -Color Red
            Write-Host "     Please deploy infrastructure first: .\deploy-azd.ps1"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Not found" -Color Red
        Write-Host "     Please deploy infrastructure first: .\deploy-azd.ps1"
        return $false
    }
    
    # Check App Service
    Write-Host "  - App Service: " -NoNewline
    try {
        $appName = az webapp list --resource-group $script:AZURE_RESOURCE_GROUP --query "[0].name" -o tsv 2>$null
        if ($appName) {
            Write-ColorOutput "✅ $appName" -Color Green
            $script:AZURE_APP_SERVICE_NAME = $appName
        }
        else {
            Write-ColorOutput "❌ Not found" -Color Red
            Write-Host "     Please deploy infrastructure first: .\deploy-azd.ps1"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Not found" -Color Red
        Write-Host "     Please deploy infrastructure first: .\deploy-azd.ps1"
        return $false
    }
    
    return $true
}

function New-ServicePrincipal {
    Write-Host "🔑 Creating Service Principal for GitHub Actions..."
    
    $subscriptionId = az account show --query id -o tsv
    $spName = "github-actions-image-analysis-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    Write-Host "Creating service principal: $spName"
    try {
        $spOutput = az ad sp create-for-rbac `
            --name $spName `
            --role "Contributor" `
            --scopes "/subscriptions/$subscriptionId" `
            --json-auth
        
        Write-ColorOutput "✅ Service Principal created successfully!" -Color Green
        Write-Host ""
        Write-Host "🔒 Add this to GitHub Secrets as AZURE_CREDENTIALS:" -ForegroundColor Yellow
        Write-Host "================================================="
        Write-Host $spOutput
        Write-Host "================================================="
        Write-Host ""
        
        return $spOutput
    }
    catch {
        Write-ColorOutput "❌ Failed to create service principal" -Color Red
        Write-Host "Error: $_"
        return $null
    }
}

function Show-GitHubSecrets {
    Write-Host "📋 GitHub Secrets Configuration" -ForegroundColor Cyan
    Write-Host "==============================="
    Write-Host ""
    Write-Host "Add these secrets to your GitHub repository:"
    Write-Host "(Settings > Secrets and variables > Actions)"
    Write-Host ""
    Write-Host "Secret Name: AZURE_CREDENTIALS" -ForegroundColor Yellow
    Write-Host "Value: [Service Principal JSON from above]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Secret Name: AZURE_CONTAINER_REGISTRY" -ForegroundColor Yellow
    Write-Host "Value: $script:AZURE_CONTAINER_REGISTRY" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Secret Name: AZURE_RESOURCE_GROUP" -ForegroundColor Yellow
    Write-Host "Value: $script:AZURE_RESOURCE_GROUP" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Secret Name: AZURE_APP_SERVICE_NAME" -ForegroundColor Yellow
    Write-Host "Value: $script:AZURE_APP_SERVICE_NAME" -ForegroundColor Gray
    Write-Host ""
}

function Test-ContainerBuild {
    Write-Host "🐳 Testing container build locally..."
    
    if (Test-Path "Dockerfile") {
        Write-Host "Building test container..."
        try {
            $null = docker build -t streamlit-app-test . --quiet
            Write-ColorOutput "✅ Container build successful" -Color Green
            try { docker rmi streamlit-app-test 2>$null } catch { }
            return $true
        }
        catch {
            Write-ColorOutput "❌ Container build failed" -Color Red
            Write-Host "Please check your Dockerfile"
            return $false
        }
    }
    else {
        Write-ColorOutput "❌ Dockerfile not found" -Color Red
        return $false
    }
}

# Main execution
function Main {
    $validationPassed = $true
    
    if (-not $ShowSecretsOnly) {
        $validationPassed = $validationPassed -and (Test-AzureCLI)
        $validationPassed = $validationPassed -and (Test-AzureLogin)
        $validationPassed = $validationPassed -and (Test-Docker)
        Test-GitHubRepo | Out-Null
        $validationPassed = $validationPassed -and (Test-AzureResources)
        $validationPassed = $validationPassed -and (Test-ContainerBuild)
        
        if (-not $validationPassed) {
            Write-ColorOutput "❌ Prerequisites validation failed. Please fix the issues above." -Color Red
            exit 1
        }
        
        Write-Host ""
        Write-ColorOutput "🎉 Prerequisites validation completed successfully!" -Color Green
        Write-Host ""
    }
    
    if ($CreateServicePrincipal -or $ShowSecretsOnly) {
        if ($CreateServicePrincipal) {
            $spOutput = New-ServicePrincipal
        }
        Show-GitHubSecrets
    }
    elseif (-not $ShowSecretsOnly) {
        $response = Read-Host "Do you want to create a service principal for GitHub Actions? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            $spOutput = New-ServicePrincipal
        }
        Show-GitHubSecrets
    }
    
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Configure GitHub secrets (shown above)"
    Write-Host "2. Push your code to GitHub"
    Write-Host "3. Watch the CI/CD pipeline run automatically!"
    Write-Host ""
    Write-Host "📖 For detailed setup instructions, see: AUTOMATED_CICD_GUIDE.md"
}

# Initialize global variables
$script:AZURE_RESOURCE_GROUP = ""
$script:AZURE_CONTAINER_REGISTRY = ""
$script:AZURE_APP_SERVICE_NAME = ""

# Run main function
try {
    Main
}
catch {
    Write-ColorOutput "❌ Script execution failed: $_" -Color Red
    exit 1
}
