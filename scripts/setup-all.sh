#!/bin/bash
# Master setup script for all Phase 0 configurations

set -e

echo "🎯 Maratea Phase 0 - Complete Setup"
echo "===================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "📋 Setup Checklist:"
echo ""
echo "1. GitHub Secrets (Turborepo, Kubernetes)"
echo "2. ArgoCD Application (GitHub org)"
echo "3. Turborepo Remote Cache"
echo "4. ArgoCD Installation"
echo ""

read -p "Start setup? (y/n): " START
if [ "$START" != "y" ]; then
    echo "Setup cancelled"
    exit 0
fi

echo ""
echo "Step 1: GitHub Secrets"
echo "----------------------"
read -p "Setup GitHub secrets? (y/n): " SETUP_SECRETS
if [ "$SETUP_SECRETS" = "y" ]; then
    "$SCRIPT_DIR/setup-github-secrets.sh"
fi

echo ""
echo "Step 2: Turborepo Remote Cache"
echo "------------------------------"
read -p "Setup Turborepo remote cache? (y/n): " SETUP_TURBO
if [ "$SETUP_TURBO" = "y" ]; then
    "$SCRIPT_DIR/setup-turborepo.sh"
fi

echo ""
echo "Step 3: ArgoCD"
echo "--------------"
read -p "Setup ArgoCD? (y/n): " SETUP_ARGOCD
if [ "$SETUP_ARGOCD" = "y" ]; then
    "$SCRIPT_DIR/setup-argocd.sh"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Verify GitHub Actions workflow is working"
echo "2. Check ArgoCD application status"
echo "3. Monitor first deployment"
echo ""

