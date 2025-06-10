# Test CI/CD Trigger Script for Windows
# This script makes a small change and pushes to trigger the automated CI/CD pipeline

param(
    [string]$Branch = "",
    [switch]$Force
)

Write-Host "🚀 Testing Automated CI/CD Pipeline" -ForegroundColor Cyan
Write-Host "==================================="

# Check if we're in a git repository
if (-not (Test-Path ".git" -PathType Container)) {
    Write-Host "❌ Not in a git repository. Please initialize git first." -ForegroundColor Red
    exit 1
}

# Check if we have a remote
try {
    $remoteUrl = git remote get-url origin 2>$null
    if (-not $remoteUrl) {
        throw "No remote found"
    }
}
catch {
    Write-Host "❌ No GitHub remote found. Please add remote first:" -ForegroundColor Red
    Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    exit 1
}

# Check current branch
$currentBranch = git branch --show-current

if ($Branch) {
    $targetBranch = $Branch
}
else {
    $targetBranch = $currentBranch
}

if ($targetBranch -notin @("main", "develop") -and -not $Force) {
    Write-Host "⚠️  Current branch: $currentBranch" -ForegroundColor Yellow
    Write-Host "   CI/CD triggers on 'main' and 'develop' branches only"
    
    if (-not $Force) {
        $response = Read-Host "Switch to main branch? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            try {
                git checkout main 2>$null
                $targetBranch = "main"
            }
            catch {
                git checkout -b main
                $targetBranch = "main"
            }
        }
    }
}

# Create a timestamp for the test
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$testFile = "cicd-test.md"

Write-Host "📝 Creating test change..."

# Get current commit hash
try {
    $currentCommit = git rev-parse --short HEAD 2>$null
}
catch {
    $currentCommit = "pending"
}

# Create or update test file
$testContent = @"
# CI/CD Test

Last automated test run: $timestamp

This file is used to test the automated CI/CD pipeline.
Every time this file is updated and pushed, it should trigger:

1. ✅ Container image build
2. ✅ Push to Azure Container Registry
3. ✅ Security scanning with Trivy
4. ✅ Deployment to Azure App Service
5. ✅ Health checks
6. ✅ Integration tests
7. ✅ Cleanup of old images

## Test Results

- Branch: $targetBranch
- Timestamp: $timestamp
- Git Commit: $currentCommit

## Expected Behavior

After pushing this change:
- GitHub Actions workflow should start automatically
- New container image should be built and pushed to ACR
- Application should be deployed to Azure App Service
- Health checks should verify the deployment

Check the Actions tab in your GitHub repository to monitor progress.
"@

$testContent | Set-Content -Path $testFile -Encoding UTF8

Write-Host "✅ Test file updated: $testFile" -ForegroundColor Green

# Add and commit the change
git add $testFile
git commit -m "test: trigger automated CI/CD pipeline - $timestamp"

Write-Host "📤 Pushing to trigger CI/CD pipeline..." -ForegroundColor Yellow
try {
    git push origin $targetBranch
    Write-Host "✅ Push successful!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Push failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Test change pushed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 Monitor the CI/CD pipeline:" -ForegroundColor Cyan
Write-Host "   1. Go to your GitHub repository"
Write-Host "   2. Click the 'Actions' tab"
Write-Host "   3. Watch the 'Build and Deploy to Azure' workflow"
Write-Host ""
Write-Host "⏱️  Expected completion time: 5-10 minutes" -ForegroundColor Yellow
Write-Host ""

# Get the repository URL for convenience
$repoUrl = $remoteUrl
$repoUrl = $repoUrl -replace "https://github.com/", ""
$repoUrl = $repoUrl -replace "git@github.com:", ""
$repoUrl = $repoUrl -replace "\.git$", ""

Write-Host "🌐 Direct links:" -ForegroundColor Cyan
Write-Host "   Repository: https://github.com/$repoUrl"
Write-Host "   Actions: https://github.com/$repoUrl/actions"
Write-Host ""

# Wait a moment and check if we can get the workflow run
Start-Sleep -Seconds 5
Write-Host "🔄 Checking for workflow run..." -ForegroundColor Yellow

# Note: This requires GitHub CLI to be installed and authenticated
try {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        Write-Host "📊 Recent workflow runs:" -ForegroundColor Cyan
        gh run list --limit 3 --json status,conclusion,workflowName,createdAt,url 2>$null
    }
    else {
        Write-Host "   Install GitHub CLI (gh) for workflow status: https://cli.github.com/" -ForegroundColor Gray
    }
}
catch {
    Write-Host "   (GitHub CLI not authenticated or not available)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ Test completed! Check GitHub Actions for results." -ForegroundColor Green
