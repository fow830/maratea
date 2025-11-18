# Setup Scripts

Автоматизированные скрипты для настройки Maratea Platform Phase 0.

## Быстрый старт

Запустите главный скрипт для полной настройки:

```bash
./scripts/setup-all.sh
```

## Отдельные скрипты

### 1. setup-github-secrets.sh

Настройка GitHub Secrets для CI/CD:

```bash
./scripts/setup-github-secrets.sh
```

**Требования:**
- GitHub CLI (`gh`) установлен и аутентифицирован
- Доступ к репозиторию

**Настраивает:**
- `TURBO_TOKEN` - токен для Turborepo remote cache
- `TURBO_TEAM` - название команды в Turborepo
- `KUBECONFIG` - base64 encoded kubeconfig для staging кластера

### 2. setup-turborepo.sh

Настройка Turborepo remote cache:

```bash
./scripts/setup-turborepo.sh
```

**Требования:**
- Аккаунт на https://turbo.build
- Созданная команда (team)

**Что делает:**
- Помогает войти в Turborepo
- Связывает проект с командой
- Тестирует remote cache

### 3. setup-argocd.sh

Установка и настройка ArgoCD:

```bash
./scripts/setup-argocd.sh
```

**Требования:**
- `kubectl` установлен и настроен
- Доступ к Kubernetes кластеру
- GitHub organization/username

**Что делает:**
- Обновляет ArgoCD Application с вашим GitHub org
- Устанавливает ArgoCD в кластер
- Применяет ArgoCD Application

### 4. security-scan.sh

Сканирование безопасности:

```bash
./scripts/security-scan.sh
```

**Что делает:**
- Устанавливает Trivy (если не установлен)
- Сканирует Docker образы
- Запускает `pnpm audit`

## Ручная настройка

Если скрипты не подходят, см. [DEPLOYMENT.md](../docs/DEPLOYMENT.md) для ручной настройки.

