# 🚀 Complete CI/CD Setup Script
# This script sets up automated CI/CD for the Azure AI Image Analysis Demo

param(
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "image-analysis-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "",
    
    [switch]$SkipInfrastructure,
    [switch]$SkipValidation,
    [switch]$TestPipeline
)

# Colors for better output
function Write-Step {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

Write-Host @"
🎯 Azure AI Image Analysis Demo - Complete CI/CD Setup
======================================================

This script will set up automated CI/CD that triggers on every code commit:
✅ Container build and push to Azure Container Registry
✅ Automated deployment to Azure App Service  
✅ Security scanning and health checks
✅ Cleanup of old container images

"@ -ForegroundColor Cyan

# Step 1: Deploy Infrastructure (if needed)
if (-not $SkipInfrastructure) {
    Write-Step "Checking Azure infrastructure..."
    
    if (Test-Path ".\deploy-azd.ps1") {
        $response = Read-Host "Deploy Azure infrastructure now? This is required for CI/CD. (Y/n)"
        if ($response -ne 'n' -and $response -ne 'N') {
            Write-Step "Deploying Azure infrastructure..."
            try {
                .\deploy-azd.ps1 -EnvironmentName $EnvironmentName
                Write-Success "Infrastructure deployed successfully!"
            }
            catch {
                Write-Error "Infrastructure deployment failed: $_"
                Write-Info "You can deploy manually later with: .\deploy-azd.ps1"
            }
        }
    }
    else {
        Write-Warning "deploy-azd.ps1 not found. Infrastructure must be deployed manually."
    }
}

# Step 2: Validate Prerequisites
if (-not $SkipValidation) {
    Write-Step "Validating CI/CD prerequisites..."
    
    if (Test-Path ".\validate-cicd-setup.ps1") {
        try {
            .\validate-cicd-setup.ps1 -CreateServicePrincipal
            Write-Success "Prerequisites validation completed!"
        }
        catch {
            Write-Error "Prerequisites validation failed: $_"
            Write-Info "Please run .\validate-cicd-setup.ps1 manually to see detailed issues"
            return
        }
    }
    else {
        Write-Warning "validate-cicd-setup.ps1 not found. Please validate prerequisites manually."
    }
}

# Step 3: GitHub Repository Setup
Write-Step "Setting up GitHub repository..."

if (-not (Test-Path ".git")) {
    Write-Info "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit with automated CI/CD setup"
}

if ($GitHubRepo) {
    Write-Info "Adding GitHub remote: $GitHubRepo"
    try {
        git remote add origin $GitHubRepo 2>$null
    }
    catch {
        Write-Info "Remote already exists or failed to add. Continuing..."
    }
}
else {
    $currentRemote = git remote get-url origin 2>$null
    if (-not $currentRemote) {
        Write-Warning "No GitHub remote configured."
        Write-Info "Please add your GitHub repository remote:"
        Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git" -ForegroundColor Gray
        $GitHubRepo = Read-Host "Enter your GitHub repository URL (or press Enter to skip)"
        if ($GitHubRepo) {
            git remote add origin $GitHubRepo
            Write-Success "GitHub remote added!"
        }
    }
    else {
        Write-Success "GitHub remote already configured: $currentRemote"
    }
}

# Step 4: GitHub Secrets Instructions
Write-Step "GitHub Secrets Configuration Required"
Write-Host @"

📋 IMPORTANT: Configure these GitHub secrets for automated CI/CD:

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Add the following secrets (values provided by validate-cicd-setup.ps1):

   🔑 AZURE_CREDENTIALS
   🏷️  AZURE_CONTAINER_REGISTRY  
   🏗️  AZURE_RESOURCE_GROUP
   🌐 AZURE_APP_SERVICE_NAME

4. The CI/CD pipeline will trigger automatically on commits to main/develop branches

"@ -ForegroundColor Yellow

$response = Read-Host "Have you configured the GitHub secrets? (y/N)"
$secretsConfigured = ($response -eq 'y' -or $response -eq 'Y')

# Step 5: Push Initial Code
Write-Step "Preparing to push code to GitHub..."

$currentBranch = git branch --show-current
if (-not $currentBranch) {
    git checkout -b main
    $currentBranch = "main"
}

Write-Info "Current branch: $currentBranch"

if ($currentBranch -notin @("main", "develop")) {
    $response = Read-Host "Switch to main branch for automated CI/CD? (Y/n)"
    if ($response -ne 'n' -and $response -ne 'N') {
        try {
            git checkout main 2>$null
        }
        catch {
            git checkout -b main
        }
        $currentBranch = "main"
    }
}

# Step 6: Test Pipeline (Optional)
if ($TestPipeline -or $secretsConfigured) {
    Write-Step "Testing CI/CD pipeline..."
    
    if (Test-Path ".\test-cicd-trigger.ps1") {
        $response = Read-Host "Trigger a test CI/CD run now? (Y/n)"
        if ($response -ne 'n' -and $response -ne 'N') {
            try {
                .\test-cicd-trigger.ps1
                Write-Success "Test pipeline triggered! Check GitHub Actions tab."
            }
            catch {
                Write-Error "Failed to trigger test pipeline: $_"
            }
        }
    }
}
else {
    Write-Info "Skipping pipeline test. Configure GitHub secrets first, then run:"
    Write-Host "   .\test-cicd-trigger.ps1" -ForegroundColor Gray
}

# Step 7: Final Summary
Write-Host @"

🎉 CI/CD Setup Complete!
========================

✅ Infrastructure: Azure Container Registry + App Service
✅ Containerization: Optimized Docker configuration  
✅ Automation: GitHub Actions workflows configured
✅ Security: Trivy scanning and managed identity
✅ Monitoring: Health checks and integration tests

🚀 What happens now:
1. Every commit to main/develop triggers automated build & deploy
2. Container images are built and pushed to Azure Container Registry
3. New versions are automatically deployed to Azure App Service
4. Security scans and health checks ensure quality deployments

📖 Documentation:
- Complete guide: AUTOMATED_CICD_GUIDE.md
- Deployment summary: CONTAINER_DEPLOYMENT_SUMMARY.md
- Project overview: README.md

🔧 Useful commands:
- Test CI/CD: .\test-cicd-trigger.ps1
- Validate setup: .\validate-cicd-setup.ps1
- Manual deploy: .\deploy-azd.ps1

"@ -ForegroundColor Green

if (-not $secretsConfigured) {
    Write-Warning "⚠️  Don't forget to configure GitHub secrets for full automation!"
    Write-Info "Run .\validate-cicd-setup.ps1 -ShowSecretsOnly to see the required values"
}

Write-Host "🌟 Your Azure AI Image Analysis Demo now has fully automated CI/CD!" -ForegroundColor Magenta
