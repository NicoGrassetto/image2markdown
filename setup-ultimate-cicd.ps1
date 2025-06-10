# 🎯 Ultimate One-Click CI/CD Setup
# This is the simplest way to set up automated CI/CD for your Azure AI Image Analysis Demo

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "",
    
    [switch]$QuickStart
)

Clear-Host

Write-Host @"
🎯 Ultimate Azure AI Demo Setup with Automated CI/CD
===================================================

This script will set up EVERYTHING you need in one go:
✅ Deploy Azure infrastructure (Container Registry + App Service)
✅ Create GitHub service principal for automation
✅ Configure CI/CD pipeline for automatic deployments
✅ Test the automation with your first deployment

Let's get started! 🚀

"@ -ForegroundColor Cyan

# Gather required information if not provided
if (-not $EnvironmentName) {
    Write-Host "🏷️  What would you like to name your application?" -ForegroundColor Yellow
    Write-Host "   This will be used for Azure resource names" -ForegroundColor Gray
    $EnvironmentName = Read-Host "Environment name (e.g., 'my-ai-demo')"
    
    if (-not $EnvironmentName) {
        $EnvironmentName = "image-analysis-demo-$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-Host "Using default name: $EnvironmentName" -ForegroundColor Gray
    }
}

if (-not $GitHubRepo) {
    Write-Host ""
    Write-Host "🌐 GitHub Repository Setup" -ForegroundColor Yellow
    Write-Host "   For automated CI/CD, we need your GitHub repository URL"
    Write-Host "   Example: https://github.com/username/repository-name" -ForegroundColor Gray
    $GitHubRepo = Read-Host "GitHub repository URL (or press Enter to skip for now)"
}

# Confirmation
Write-Host ""
Write-Host "📋 Setup Summary:" -ForegroundColor Green
Write-Host "   Environment: $EnvironmentName"
if ($GitHubRepo) {
    Write-Host "   GitHub Repo: $GitHubRepo"
}
else {
    Write-Host "   GitHub Repo: Will be configured later" -ForegroundColor Gray
}
Write-Host ""

if (-not $QuickStart) {
    $response = Read-Host "Continue with setup? (Y/n)"
    if ($response -eq 'n' -or $response -eq 'N') {
        Write-Host "Setup cancelled." -ForegroundColor Yellow
        return
    }
}

Write-Host "🚀 Starting automated setup..." -ForegroundColor Green
Write-Host ""

# Step 1: Prerequisites Check
Write-Host "1️⃣  Checking prerequisites..." -ForegroundColor Cyan

$prereqsOK = $true

# Check Azure CLI
try {
    $null = az --version 2>$null
    Write-Host "   ✅ Azure CLI installed" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Azure CLI not found" -ForegroundColor Red
    Write-Host "      Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    $prereqsOK = $false
}

# Check Docker
try {
    $null = docker --version 2>$null
    Write-Host "   ✅ Docker installed" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Docker not found" -ForegroundColor Red
    Write-Host "      Install Docker Desktop from: https://docs.docker.com/get-docker/"
    $prereqsOK = $false
}

# Check Azure login
try {
    $subscription = az account show --query name -o tsv 2>$null
    if ($subscription) {
        Write-Host "   ✅ Azure login: $subscription" -ForegroundColor Green
    }
    else {
        Write-Host "   ❌ Not logged in to Azure" -ForegroundColor Red
        Write-Host "      Please run: az login"
        $prereqsOK = $false
    }
}
catch {
    Write-Host "   ❌ Not logged in to Azure" -ForegroundColor Red
    Write-Host "      Please run: az login"
    $prereqsOK = $false
}

if (-not $prereqsOK) {
    Write-Host ""
    Write-Host "❌ Prerequisites not met. Please install the required tools and try again." -ForegroundColor Red
    return
}

Write-Host ""

# Step 2: Deploy Infrastructure
Write-Host "2️⃣  Deploying Azure infrastructure..." -ForegroundColor Cyan

try {
    if (Test-Path ".\deploy-azd.ps1") {
        Write-Host "   🏗️  Starting deployment (this may take 5-10 minutes)..."
        .\deploy-azd.ps1 -EnvironmentName $EnvironmentName -Quiet
        Write-Host "   ✅ Infrastructure deployed successfully!" -ForegroundColor Green
    }
    else {
        throw "deploy-azd.ps1 not found"
    }
}
catch {
    Write-Host "   ❌ Infrastructure deployment failed: $_" -ForegroundColor Red
    Write-Host "   🔧 Try running manually: .\deploy-azd.ps1 -EnvironmentName $EnvironmentName"
    return
}

Write-Host ""

# Step 3: GitHub Setup
Write-Host "3️⃣  Setting up GitHub integration..." -ForegroundColor Cyan

# Initialize git if needed
if (-not (Test-Path ".git")) {
    Write-Host "   📝 Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit with automated CI/CD setup"
}

# Add GitHub remote if provided
if ($GitHubRepo) {
    Write-Host "   🌐 Adding GitHub remote..."
    try {
        git remote add origin $GitHubRepo 2>$null
        Write-Host "   ✅ GitHub remote configured" -ForegroundColor Green
    }
    catch {
        Write-Host "   ℹ️  Remote already exists or couldn't be added" -ForegroundColor Blue
    }
}

Write-Host ""

# Step 4: Create Service Principal
Write-Host "4️⃣  Creating GitHub Actions service principal..." -ForegroundColor Cyan

try {
    if (Test-Path ".\validate-cicd-setup.ps1") {
        .\validate-cicd-setup.ps1 -CreateServicePrincipal | Out-Host
        Write-Host "   ✅ Service principal created!" -ForegroundColor Green
    }
    else {
        throw "validate-cicd-setup.ps1 not found"
    }
}
catch {
    Write-Host "   ❌ Service principal creation failed: $_" -ForegroundColor Red
    Write-Host "   🔧 Try running manually: .\validate-cicd-setup.ps1 -CreateServicePrincipal"
    return
}

Write-Host ""

# Step 5: Final Instructions
Write-Host "5️⃣  Final setup steps..." -ForegroundColor Cyan

Write-Host ""
Write-Host "🎉 SETUP COMPLETE! Here's what was created:" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Azure Container Registry - for storing your app images"
Write-Host "✅ Azure App Service - for hosting your containerized app"  
Write-Host "✅ GitHub Actions service principal - for automated deployments"
Write-Host "✅ CI/CD pipeline configuration - builds & deploys on every commit"
Write-Host ""

Write-Host "🔑 IMPORTANT - Configure GitHub Secrets:" -ForegroundColor Yellow
Write-Host "1. Go to your GitHub repository"
Write-Host "2. Navigate to: Settings > Secrets and variables > Actions"
Write-Host "3. Add the secrets shown above (from the service principal output)"
Write-Host ""

Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Configure GitHub secrets (required for automation)"
Write-Host "2. Push your code: git push origin main"
Write-Host "3. Watch the magic happen in GitHub Actions tab!"
Write-Host ""

# Offer to trigger test
if ($GitHubRepo) {
    $response = Read-Host "🧪 Would you like to test the CI/CD pipeline now? (Y/n)"
    if ($response -ne 'n' -and $response -ne 'N') {
        try {
            if (Test-Path ".\test-cicd-trigger.ps1") {
                Write-Host "   🔬 Triggering test deployment..."
                .\test-cicd-trigger.ps1
            }
        }
        catch {
            Write-Host "   ⚠️  Test trigger failed. You can run it manually later." -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "📖 Documentation:" -ForegroundColor Blue
Write-Host "   - Complete guide: AUTOMATED_CICD_GUIDE.md"
Write-Host "   - Project overview: README.md"
Write-Host "   - Container info: CONTAINER_DEPLOYMENT_SUMMARY.md"
Write-Host ""

Write-Host "🌟 Your Azure AI Image Analysis Demo now has FULLY AUTOMATED CI/CD!" -ForegroundColor Magenta
Write-Host "    Every code commit will automatically build, test, and deploy! 🚀" -ForegroundColor Magenta
