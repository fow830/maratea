#!/bin/bash
# Script to help setup GitHub Secrets for CI/CD

set -e

echo "🔐 GitHub Secrets Setup Helper"
echo "=============================="
echo ""
echo "This script will help you set up GitHub Secrets for CI/CD pipeline."
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI (gh) is not installed."
    echo "   Install it: https://cli.github.com/"
    echo ""
    echo "   Or set secrets manually in GitHub:"
    echo "   Settings → Secrets and variables → Actions → New repository secret"
    echo ""
    exit 1
fi

echo "Checking GitHub authentication..."
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "   Run: gh auth login"
    exit 1
fi

echo "✅ Authenticated with GitHub"
echo ""

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
    echo "⚠️  Could not detect repository. Please set it manually:"
    read -p "Enter repository (owner/repo): " REPO
fi

echo "Repository: $REPO"
echo ""

# Setup Turborepo
echo "📦 Turborepo Remote Cache Setup"
echo "-------------------------------"
echo ""
echo "1. Create account at https://turbo.build"
echo "2. Create a team"
echo "3. Get your token:"
echo "   npx turbo login"
echo ""
read -p "Enter Turborepo token (or press Enter to skip): " TURBO_TOKEN
read -p "Enter Turborepo team name (or press Enter to skip): " TURBO_TEAM

if [ -n "$TURBO_TOKEN" ] && [ -n "$TURBO_TEAM" ]; then
    echo "Setting TURBO_TOKEN..."
    gh secret set TURBO_TOKEN --body "$TURBO_TOKEN" --repo "$REPO"
    echo "Setting TURBO_TEAM..."
    gh secret set TURBO_TEAM --body "$TURBO_TEAM" --repo "$REPO"
    echo "✅ Turborepo secrets set"
else
    echo "⚠️  Skipping Turborepo setup"
fi

echo ""

# Setup Kubernetes
echo "☸️  Kubernetes Setup"
echo "-------------------"
echo ""
echo "To get kubeconfig for staging cluster:"
echo "  kubectl config view --flatten | base64"
echo ""
read -p "Enter base64 encoded kubeconfig (or press Enter to skip): " KUBECONFIG

if [ -n "$KUBECONFIG" ]; then
    echo "Setting KUBECONFIG..."
    gh secret set KUBECONFIG --body "$KUBECONFIG" --repo "$REPO"
    echo "✅ KUBECONFIG secret set"
else
    echo "⚠️  Skipping Kubernetes setup"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update infrastructure/argocd/application.yaml with your GitHub org"
echo "2. Install ArgoCD in your cluster"
echo "3. Apply ArgoCD Application manifest"

