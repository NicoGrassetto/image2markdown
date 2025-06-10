#!/bin/bash

# Test CI/CD Trigger Script
# This script makes a small change and pushes to trigger the automated CI/CD pipeline

set -e

echo "🚀 Testing Automated CI/CD Pipeline"
echo "==================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository. Please initialize git first."
    exit 1
fi

# Check if we have a remote
if ! git remote get-url origin &> /dev/null; then
    echo "❌ No GitHub remote found. Please add remote first:"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    exit 1
fi

# Check if we're on main or develop branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "develop" ]]; then
    echo "⚠️  Current branch: $CURRENT_BRANCH"
    echo "   CI/CD triggers on 'main' and 'develop' branches only"
    read -p "Switch to main branch? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout main || git checkout -b main
    fi
fi

# Create a timestamp for the test
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TEST_FILE="cicd-test.md"

echo "📝 Creating test change..."

# Create or update test file
cat > "$TEST_FILE" << EOF
# CI/CD Test

Last automated test run: $TIMESTAMP

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

- Branch: $CURRENT_BRANCH
- Timestamp: $TIMESTAMP
- Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo "pending")

## Expected Behavior

After pushing this change:
- GitHub Actions workflow should start automatically
- New container image should be built and pushed to ACR
- Application should be deployed to Azure App Service
- Health checks should verify the deployment

Check the Actions tab in your GitHub repository to monitor progress.
EOF

echo "✅ Test file updated: $TEST_FILE"

# Add and commit the change
git add "$TEST_FILE"
git commit -m "test: trigger automated CI/CD pipeline - $TIMESTAMP"

echo "📤 Pushing to trigger CI/CD pipeline..."
git push origin "$CURRENT_BRANCH"

echo ""
echo "🎉 Test change pushed successfully!"
echo ""
echo "🔍 Monitor the CI/CD pipeline:"
echo "   1. Go to your GitHub repository"
echo "   2. Click the 'Actions' tab"
echo "   3. Watch the 'Build and Deploy to Azure' workflow"
echo ""
echo "⏱️  Expected completion time: 5-10 minutes"
echo ""

# Get the repository URL for convenience
REPO_URL=$(git remote get-url origin)
REPO_URL=${REPO_URL#https://github.com/}
REPO_URL=${REPO_URL#git@github.com:}
REPO_URL=${REPO_URL%.git}

echo "🌐 Direct links:"
echo "   Repository: https://github.com/$REPO_URL"
echo "   Actions: https://github.com/$REPO_URL/actions"
echo ""

# Wait a moment and check if we can get the workflow run
sleep 5
echo "🔄 Checking for workflow run..."

# Note: This requires GitHub CLI to be installed and authenticated
if command -v gh &> /dev/null; then
    echo "📊 Recent workflow runs:"
    gh run list --limit 3 --json status,conclusion,workflowName,createdAt,url || echo "   (GitHub CLI not authenticated)"
else
    echo "   Install GitHub CLI (gh) for workflow status: https://cli.github.com/"
fi

echo ""
echo "✅ Test completed! Check GitHub Actions for results."
