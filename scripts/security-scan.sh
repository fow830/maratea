#!/bin/bash
# Security scanning script for Maratea platform

set -e

echo "🔒 Maratea Security Scan"
echo "========================"
echo ""

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo "⚠️  Trivy is not installed. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install trivy
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install trivy
    else
        echo "❌ Please install Trivy manually: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
        exit 1
    fi
fi

echo "✅ Trivy is installed"
echo ""

# Scan Docker images
echo "📦 Scanning Docker images..."
echo ""

if docker images | grep -q "postgres:15-alpine"; then
    echo "Scanning postgres:15-alpine..."
    trivy image postgres:15-alpine --severity HIGH,CRITICAL
fi

if docker images | grep -q "redis:7-alpine"; then
    echo ""
    echo "Scanning redis:7-alpine..."
    trivy image redis:7-alpine --severity HIGH,CRITICAL
fi

echo ""
echo "📋 Scanning dependencies..."
pnpm audit --audit-level=moderate

echo ""
echo "✅ Security scan completed"

