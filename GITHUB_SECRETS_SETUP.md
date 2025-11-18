# Настройка GitHub Secrets

Репозиторий: https://github.com/fow830/maratea

## Требуемые Secrets:

### 1. TURBO_TOKEN
Токен для Turborepo remote cache.

**Как получить:**
```bash
npx turbo login
# Скопируйте токен из вывода
```

**Установить:**
```bash
gh secret set TURBO_TOKEN --body "ваш_токен"
```

### 2. TURBO_TEAM
Название команды в Turborepo.

**Как получить:**
- Создайте команду на https://turbo.build
- Или используйте существующую

**Установить:**
```bash
gh secret set TURBO_TEAM --body "название_команды"
```

### 3. KUBECONFIG
Base64 encoded kubeconfig для staging кластера.

**Как получить:**
```bash
kubectl config view --flatten | base64
```

**Установить:**
```bash
kubectl config view --flatten | base64 | gh secret set KUBECONFIG --body-file -
```

## Быстрая настройка:

Используйте скрипт:
```bash
./scripts/setup-github-secrets.sh
```

Или установите вручную через GitHub UI:
Settings → Secrets and variables → Actions → New repository secret
