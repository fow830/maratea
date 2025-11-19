# Технологический стек

## Языки и runtime
- **Node.js 22** (Alpine)
- **TypeScript 5.3**
- **ESM** (ES Modules)

## Монорепозиторий
- **Turborepo 2.0** (remote caching)
- **pnpm 8.15** (workspaces)
- **Biome** (lint/format)
- **Husky** + **lint-staged** (pre-commit hooks)

## Приложения

### API Gateway
- **Fastify 4.24** (HTTP server)
- **@fastify/cors**, **@fastify/rate-limit**
- **ioredis** (Redis client)
- **opossum** (Circuit Breaker)
- **prom-client** (Prometheus metrics)

### App (Next.js)
- **Next.js 14** (App Router, SSR)
- **React 18**
- **TypeScript**

### Landing (Static)
- **Next.js 14** (Static Export)
- **React 18**
- **Nginx Alpine** (production)

## Базы данных
- **PostgreSQL 16** (Alpine)
- **Redis 7** (Alpine)

## Инфраструктура

### Kubernetes
- **Timeweb Cloud K8s** (managed)
- **ArgoCD** (GitOps)
- **ingress-nginx** (Ingress Controller)
- **cert-manager** (Let's Encrypt TLS)
- **local-path** (StorageClass)

### Мониторинг
- **Prometheus** (kube-prometheus-stack)
- **Grafana**
- **Alertmanager** (Telegram webhooks)
- **Loki** (logs)
- **Promtail** (log collection)

### CI/CD
- **GitHub Actions**
- **Docker** (multi-stage builds)
- **GHCR** (container registry)
- **Trivy** (security scanning)
- **CodeQL** (code analysis)

### Бэкапы
- **CronJob** (Kubernetes)
- **pg_dump** (PostgreSQL)
- **redis-cli BGSAVE** (Redis)
- **Timeweb S3** (Object Storage)
- **awscli** (S3 upload)

## Безопасность
- **Network Policies** (K8s)
- **Basic Auth** (Ingress)
- **TLS** (Let's Encrypt)
- **Security Context** (non-root, read-only FS)
- **Secrets** (K8s Secrets, GitHub Secrets)

## Домены (staging)
- `api.staging.betaserver.ru` → API Gateway
- `app.staging.betaserver.ru` → Next.js App
- `staging.betaserver.ru` → Landing
- `argocd.staging.betaserver.ru` → ArgoCD UI
- `grafana.staging.betaserver.ru` → Grafana

