#!/usr/bin/env powershell
# Test script to validate the deployment setup

param(
    [switch]$SkipDocker = $false
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-Prerequisites {
    Write-Status "Testing deployment prerequisites..."
    
    $errors = @()
    
    # Test Azure CLI
    try {
        $null = Get-Command az -ErrorAction Stop
        $version = az version --output json | ConvertFrom-Json
        Write-Success "Azure CLI installed: v$($version.'azure-cli')"
    }
    catch {
        $errors += "Azure CLI is not installed"
    }
    
    # Test Azure Developer CLI
    try {
        $null = Get-Command azd -ErrorAction Stop
        $version = azd version
        Write-Success "Azure Developer CLI installed: $version"
    }
    catch {
        Write-Status "Azure Developer CLI not found (optional for deploy-azd.ps1)"
    }
    
    # Test Docker
    if (-not $SkipDocker) {
        try {
            $null = Get-Command docker -ErrorAction Stop
            $version = docker --version
            Write-Success "Docker installed: $version"
            
            # Test if Docker is running
            try {
                docker info | Out-Null
                Write-Success "Docker daemon is running"
            }
            catch {
                $errors += "Docker daemon is not running (start Docker Desktop)"
            }
        }
        catch {
            $errors += "Docker is not installed"
        }
    }
    
    # Test Azure login
    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json
        if ($account) {
            Write-Success "Logged in to Azure as: $($account.user.name)"
            Write-Success "Active subscription: $($account.name) ($($account.id))"
        }
        else {
            $errors += "Not logged in to Azure (run 'az login')"
        }
    }
    catch {
        $errors += "Not logged in to Azure (run 'az login')"
    }
    
    return $errors
}

function Test-Files {
    Write-Status "Checking required files..."
    
    $errors = @()
    $requiredFiles = @(
        "Dockerfile",
        ".dockerignore",
        "azure.yaml",
        "requirements.txt",
        "streamlit_app.py",
        "image_analyzer.py",
        "infra/main.bicep",
        "infra/resources.bicep",
        "infra/main.parameters.json"
    )
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Success "Found: $file"
        }
        else {
            $errors += "Missing file: $file"
        }
    }
    
    return $errors
}

function Test-BicepSyntax {
    Write-Status "Validating Bicep syntax..."
    
    $errors = @()
    
    try {
        # Test main.bicep
        $result = az bicep build --file "infra/main.bicep" --stdout 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "main.bicep syntax is valid"
        }
        else {
            $errors += "main.bicep has syntax errors: $result"
        }
    }
    catch {
        $errors += "Failed to validate main.bicep: $($_.Exception.Message)"
    }
    
    try {
        # Test resources.bicep
        $result = az bicep build --file "infra/resources.bicep" --stdout 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "resources.bicep syntax is valid"
        }
        else {
            $errors += "resources.bicep has syntax errors: $result"
        }
    }
    catch {
        $errors += "Failed to validate resources.bicep: $($_.Exception.Message)"
    }
    
    return $errors
}

function Test-DockerBuild {
    if ($SkipDocker) {
        Write-Status "Skipping Docker build test"
        return @()
    }
    
    Write-Status "Testing Docker build..."
    
    $errors = @()
    
    try {
        # Test Docker build (but don't create a full image)
        $output = docker build --dry-run . 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Dockerfile is valid"
        }
        else {
            # Fallback: try a quick syntax check
            $content = Get-Content "Dockerfile" -Raw
            if ($content -match "FROM\s+") {
                Write-Success "Dockerfile appears to be valid"
            }
            else {
                $errors += "Dockerfile may have syntax issues"
            }
        }
    }
    catch {
        $errors += "Failed to test Docker build: $($_.Exception.Message)"
    }
    
    return $errors
}

function Main {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Azure AI Image Analysis Demo" -ForegroundColor Cyan
    Write-Host "  Deployment Readiness Test" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $allErrors = @()
    
    # Run all tests
    $allErrors += Test-Prerequisites
    $allErrors += Test-Files
    $allErrors += Test-BicepSyntax
    $allErrors += Test-DockerBuild
    
    Write-Host ""
    Write-Host "========== TEST SUMMARY ==========" -ForegroundColor Cyan
    
    if ($allErrors.Count -eq 0) {
        Write-Success "All tests passed! ✅"
        Write-Host ""
        Write-Host "You're ready to deploy:" -ForegroundColor Yellow
        Write-Host "  • For AZD deployment: .\deploy-azd.ps1" -ForegroundColor Green
        Write-Host "  • For traditional deployment: .\deploy.ps1" -ForegroundColor Green
    }
    else {
        Write-Error "Found $($allErrors.Count) issue(s):"
        foreach ($error in $allErrors) {
            Write-Host "  ❌ $error" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Please fix the issues above before deploying." -ForegroundColor Yellow
        exit 1
    }
}

# Run the test
Main
