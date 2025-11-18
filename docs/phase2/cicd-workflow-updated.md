# Phase 2, Этап 4: CI/CD workflow обновлен

Дата: 2025-11-19

## ✅ Что добавлено в GitHub Actions workflow

### 1. Build jobs для приложений

**Добавлено в job `build-and-scan`:**

1. **Build and push App:**
   - Dockerfile: `app/Dockerfile`
   - Tags: `app:${{ github.sha }}` и `app:latest`
   - Multi-platform: linux/amd64, linux/arm64
   - GitHub Actions cache

2. **Build and push Landing:**
   - Dockerfile: `landing/Dockerfile`
   - Tags: `landing:${{ github.sha }}` и `landing:latest`
   - Multi-platform: linux/amd64, linux/arm64
   - GitHub Actions cache

3. **Trivy scan:**
   - Обновлен для сканирования всех трех образов:
     - `api-gateway:${{ github.sha }}`
     - `app:${{ github.sha }}`
     - `landing:${{ github.sha }}`

---

### 2. Deploy jobs для приложений

**Добавлено в job `deploy-staging`:**

1. **Update K8s manifests:**
   - Обновляет image tags для всех трех deployments:
     - `api-gateway/deployment.yaml`
     - `app/deployment.yaml`
     - `landing/deployment.yaml`

2. **Apply K8s manifests:**
   - Применяет манифесты для app и landing:
     ```bash
     kubectl apply -f infrastructure/kubernetes/app/
     kubectl apply -f infrastructure/kubernetes/landing/
     ```

3. **Wait for deployments:**
   - Ожидает rollout для всех трех deployments:
     - `api-gateway`
     - `app`
     - `landing`

4. **Health checks:**
   - Проверяет health endpoints для всех сервисов:
     - API Gateway: `http://localhost:8080/health`
     - App: `http://localhost:3000/`
     - Landing: `http://localhost:8080/health`

---

### 3. Environment URL обновлен

**Изменено:**
- `url: https://api.staging.betaserver.ru` → `url: https://app.staging.betaserver.ru`

Теперь environment URL указывает на основное приложение.

---

## 📋 Структура workflow

```
build-and-scan:
  - Checkout
  - Setup (pnpm, Node.js)
  - Install dependencies
  - Security audit
  - Lint
  - Build with Turborepo
  - Setup Docker Buildx
  - Login to GHCR
  - Build and push API Gateway
  - Build and push App          ← НОВОЕ
  - Build and push Landing      ← НОВОЕ
  - Scan images with Trivy      ← ОБНОВЛЕНО
  - Upload Trivy results

deploy-staging:
  - Checkout
  - Setup kubectl
  - Setup Helm
  - Configure kubectl
  - Sync cluster secrets
  - Update K8s manifests        ← ОБНОВЛЕНО
  - Apply K8s manifests         ← ОБНОВЛЕНО
  - Wait for deployments         ← ОБНОВЛЕНО
  - Health checks               ← ОБНОВЛЕНО
```

---

## 🔍 Особенности

### Build процесс

1. **Параллельная сборка:**
   - Все три образа собираются последовательно в одном job
   - Используется GitHub Actions cache для ускорения

2. **Multi-platform:**
   - Все образы собираются для linux/amd64 и linux/arm64
   - Поддержка разных архитектур

3. **Security scanning:**
   - Trivy сканирует все три образа
   - Результаты загружаются в GitHub Security

### Deploy процесс

1. **Автоматическое обновление:**
   - Image tags обновляются автоматически в манифестах
   - Используется `sed` для замены тегов

2. **ArgoCD совместимость:**
   - Если deployments не найдены, workflow продолжает работу
   - ArgoCD может синхронизировать deployments из Git

3. **Health checks:**
   - Проверяются все три сервиса после деплоя
   - Используется port-forward для локальной проверки

---

## 📝 Следующие шаги

### После первого запуска workflow:

1. **Проверить сборку образов:**
   - Образы должны быть в GHCR
   - Теги должны соответствовать commit SHA

2. **Проверить деплой:**
   - Deployments должны быть созданы в Kubernetes
   - Pods должны быть в статусе Running

3. **Проверить доступность:**
   - После настройки DNS:
     - `https://app.staging.betaserver.ru`
     - `https://staging.betaserver.ru`

---

## ⚠️ Примечания

1. **Image tags:**
   - Используется `:latest` для удобства
   - Также используется `:${{ github.sha }}` для точной версии

2. **Deployment strategy:**
   - ArgoCD может перезаписать изменения из workflow
   - Рекомендуется использовать ArgoCD для управления deployments

3. **Health checks:**
   - Health checks могут падать, если приложения еще не готовы
   - Это нормально для первого деплоя

4. **DNS:**
   - Приложения будут доступны только после настройки DNS
   - См. `docs/phase2/dns-setup.md`

---

## 🔗 Связанные файлы

- [Workflow файл](../../.github/workflows/deploy.yml)
- [App Deployment](../infrastructure/kubernetes/app/deployment.yaml)
- [Landing Deployment](../infrastructure/kubernetes/landing/deployment.yaml)
- [DNS Setup](./dns-setup.md)

