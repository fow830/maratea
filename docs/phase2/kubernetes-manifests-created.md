# Phase 2, Этап 2: Kubernetes манифесты созданы

Дата: 2025-11-19

## ✅ Что создано

### 1. Deployment для `app`

**Файл:** `infrastructure/kubernetes/app/deployment.yaml`

**Характеристики:**
- **Replicas:** 2
- **Image:** `ghcr.io/fow830/maratea/app:latest`
- **Port:** 3000
- **Resources:**
  - Requests: 256Mi memory, 100m CPU
  - Limits: 512Mi memory, 500m CPU

**Environment Variables:**
- `NODE_ENV=production`
- `PORT=3000`
- `HOSTNAME=0.0.0.0`
- `API_URL=https://api.staging.betaserver.ru`
- `LANDING_URL=https://staging.betaserver.ru`

**Health Checks:**
- Liveness: `/` (30s initial delay)
- Readiness: `/` (10s initial delay)

**Security:**
- Security Context настроен
- Non-root user (1000)
- Capabilities dropped

---

### 2. Service для `app`

**Файл:** `infrastructure/kubernetes/app/service.yaml`

**Характеристики:**
- **Type:** ClusterIP
- **Port:** 80 → 3000
- **Selector:** `app: app`

---

### 3. Deployment для `landing`

**Файл:** `infrastructure/kubernetes/landing/deployment.yaml`

**Характеристики:**
- **Replicas:** 1 (статический сайт)
- **Image:** `ghcr.io/fow830/maratea/landing:latest`
- **Port:** 80 (nginx)
- **Resources:**
  - Requests: 64Mi memory, 50m CPU
  - Limits: 128Mi memory, 200m CPU

**Health Checks:**
- Liveness: `/health` (10s initial delay)
- Readiness: `/health` (5s initial delay)

**Security:**
- Security Context настроен
- Non-root user (101 - nginx user)
- Read-only root filesystem
- Capabilities dropped

---

### 4. Service для `landing`

**Файл:** `infrastructure/kubernetes/landing/service.yaml`

**Характеристики:**
- **Type:** ClusterIP
- **Port:** 80 → 80
- **Selector:** `app: landing`

---

### 5. Network Policies

**Файл:** `infrastructure/kubernetes/network-policy.yaml` (обновлен)

**Добавлены политики:**

1. **app-network-policy:**
   - Ingress: от ingress-nginx и observability
   - Egress: к внешним сервисам (443, 80) и api-gateway (8080)

2. **landing-network-policy:**
   - Ingress: от ingress-nginx
   - Egress: к внешним сервисам (443, 80)

---

## 📋 Структура файлов

```
infrastructure/kubernetes/
├── app/
│   ├── deployment.yaml
│   └── service.yaml
└── landing/
    ├── deployment.yaml
    └── service.yaml
```

---

## 🔍 Особенности

### App Deployment
- Использует Next.js production server
- 2 реплики для высокой доступности
- Health checks на корневой путь `/`
- Подключение к API Gateway через переменную окружения

### Landing Deployment
- Статический сайт через nginx
- 1 реплика (достаточно для статики)
- Health check через `/health` endpoint в nginx
- Минимальные ресурсы

### Network Policies
- Ограниченный доступ только от ingress-nginx
- Prometheus может собирать метрики (observability namespace)
- App может обращаться к API Gateway

---

## 📝 Следующие шаги

### Этап 3: Ingress и DNS
- Создать Ingress для `app`
- Создать Ingress для `landing`
- Настроить DNS записи
- Получить TLS сертификаты

---

## ⚠️ Примечания

1. **Health checks:**
   - App использует `/` для health checks (можно добавить `/api/health` позже)
   - Landing использует `/health` из nginx.conf

2. **Image tags:**
   - Сейчас используется `:latest`
   - В CI/CD будет использоваться `:${{ github.sha }}`

3. **Environment variables:**
   - URLs настроены для staging
   - Для production нужно будет обновить

4. **Resources:**
   - Можно настроить HPA позже для автомасштабирования
   - Текущие лимиты достаточны для начала

