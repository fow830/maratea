# Deployment Guide

## E2E Deployment (End-to-End)

### Quick Setup

Use the automated setup script:

```bash
./scripts/setup-all.sh
```

This will guide you through:
1. GitHub Secrets setup
2. Turborepo remote cache setup
3. ArgoCD installation and configuration

### Manual Setup

#### Prerequisites

1. **GitHub Secrets:**
   - `TURBO_TOKEN` - Turborepo remote cache token
   - `TURBO_TEAM` - Turborepo team name
   - `KUBECONFIG` - Base64 encoded kubeconfig for staging cluster
   - `GITHUB_TOKEN` - Automatically provided by GitHub Actions

   **Setup script:**
   ```bash
   ./scripts/setup-github-secrets.sh
   ```

2. **ArgoCD Setup:**
   ```bash
   # Automated setup
   ./scripts/setup-argocd.sh
   
   # Or manual:
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   
   # Update GitHub org in application.yaml first!
   kubectl apply -f infrastructure/argocd/application.yaml
   ```

3. **Turborepo Remote Cache:**
   ```bash
   ./scripts/setup-turborepo.sh
   ```

### CI/CD Pipeline Flow

1. **Build and Scan:**
   - Checkout code
   - Install dependencies
   - Run security audit
   - Lint code
   - Build with Turborepo (uses remote cache)
   - Build Docker images
   - Scan images with Trivy
   - Push to GitHub Container Registry

2. **Deploy to Staging:**
   - Update K8s manifests with new image tag
   - Apply manifests to staging cluster
   - ArgoCD syncs automatically (GitOps)
   - Health check verification

### Remote Caching

Turborepo is configured to use remote caching:

```json
{
  "remoteCache": {
    "enabled": true
  }
}
```

**Setup:**
1. Create account at https://turbo.build
2. Create team
3. Get token: `npx turbo login`
4. Set secrets in GitHub:
   - `TURBO_TOKEN`
   - `TURBO_TEAM`

**Verification:**
- Look for `[REMOTE CACHE HIT]` in CI logs
- Builds should be faster on subsequent runs

### Manual Deployment

```bash
# Build locally
pnpm turbo build

# Build and push image
docker build -t ghcr.io/YOUR_ORG/maratea/api-gateway:latest ./services/api-gateway
docker push ghcr.io/YOUR_ORG/maratea/api-gateway:latest

# Apply manifests
kubectl apply -f infrastructure/kubernetes/
```

### Troubleshooting

**Remote Cache not working:**
- Check TURBO_TOKEN and TURBO_TEAM secrets
- Verify network access to turbo.build
- Check logs for authentication errors

**ArgoCD not syncing:**
- Check ArgoCD application status: `kubectl get application -n argocd`
- Verify repository access
- Check sync policy configuration

