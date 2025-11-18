#!/bin/bash
# Script to setup ArgoCD and apply application

set -e

echo "🚀 ArgoCD Setup Script"
echo "======================"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    echo "   Install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if connected to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Not connected to Kubernetes cluster"
    echo "   Configure kubectl or set KUBECONFIG"
    exit 1
fi

echo "✅ Connected to cluster: $(kubectl config current-context)"
echo ""

# Get GitHub org
read -p "Enter your GitHub organization/username: " GITHUB_ORG
if [ -z "$GITHUB_ORG" ]; then
    echo "❌ GitHub organization is required"
    exit 1
fi

# Update ArgoCD Application with GitHub org
echo "Updating ArgoCD Application manifest..."
sed -i.bak "s/\${GITHUB_ORG:-YOUR_ORG}/$GITHUB_ORG/g" infrastructure/argocd/application.yaml
rm -f infrastructure/argocd/application.yaml.bak

echo "✅ Application manifest updated"
echo ""

# Install ArgoCD
echo "📦 Installing ArgoCD..."
echo ""

read -p "Install ArgoCD? (y/n): " INSTALL_ARGOCD
if [ "$INSTALL_ARGOCD" = "y" ]; then
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo ""
    echo "⏳ Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd || true
    
    echo ""
    echo "✅ ArgoCD installed"
    echo ""
    echo "Get initial admin password:"
    echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
    echo ""
    echo "Port-forward to access UI:"
    echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo ""
fi

# Apply ArgoCD Application
echo "📋 Applying ArgoCD Application..."
kubectl apply -f infrastructure/argocd/application.yaml

echo ""
echo "✅ ArgoCD Application applied"
echo ""
echo "Check status:"
echo "  kubectl get application -n argocd"
echo "  kubectl describe application maratea-staging -n argocd"
echo ""

