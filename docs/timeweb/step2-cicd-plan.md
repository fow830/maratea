# Шаг 2: Проверка CI/CD

Дата: 2025-11-18

## Цель шага

Проверить и убедиться, что GitHub Actions workflow корректно:
1. Собирает Docker образ API Gateway
2. Публикует образ в GHCR
3. Деплоит в кластер Timeweb Cloud
4. Синхронизирует секреты
5. Обновляет deployment с новым образом
6. Проверяет работоспособность после деплоя

## Текущее состояние

### GitHub Actions Workflow
- **Файл:** `.github/workflows/deploy.yml`
- **Триггеры:** Push в `develop`/`main`, manual `workflow_dispatch`
- **Jobs:**
  - `build-and-scan`: сборка, сканирование, публикация образа
  - `deploy-staging`: деплой в кластер Timeweb

### Настроенные секреты
- ✅ `KUBECONFIG` (base64) - подключение к кластеру Timeweb
- ✅ `GHCR_TOKEN` - авторизация в GitHub Container Registry
- ✅ `TIMEWEB_API_TOKEN` - API токен Timeweb
- ✅ `POSTGRES_URL` - строка подключения к PostgreSQL
- ✅ `REDIS_URL` - строка подключения к Redis
- ✅ `TURBO_TOKEN`, `TURBO_TEAM` - Turborepo cache

### Кластер Timeweb
- ✅ Namespace `maratea` создан
- ✅ Секреты в кластере созданы (`ghcr-secret`, `timeweb-api-token`, `app-secrets`)
- ✅ Deployment `api-gateway` развернут и работает

## План проверки

### 1. Проверка workflow конфигурации

**Что проверить:**
- [ ] Workflow использует правильный `KUBECONFIG` секрет
- [ ] `GHCR_TOKEN` используется для логина в registry
- [ ] Образы публикуются с правильными тегами (`${{ github.sha }}` и `latest`)
- [ ] Деплой происходит только для веток `develop`/`main`
- [ ] Секреты синхронизируются корректно

**Команды для проверки:**
```bash
# Проверить наличие всех секретов
gh secret list

# Проверить workflow файл
cat .github/workflows/deploy.yml
```

### 2. Тестовый запуск workflow

**Действия:**
1. Создать тестовый коммит или использовать `workflow_dispatch`
2. Запустить workflow вручную или через push
3. Мониторить выполнение в GitHub Actions

**Что проверить:**
- [ ] Job `build-and-scan` успешно собирает образ
- [ ] Образ публикуется в GHCR
- [ ] Job `deploy-staging` успешно подключается к кластеру
- [ ] Секреты синхронизируются без ошибок
- [ ] Deployment обновляется с новым образом
- [ ] Health check проходит успешно

**Команды для мониторинга:**
```bash
# Отслеживать выполнение workflow
gh run watch

# Проверить логи конкретного run
gh run view <run-id> --log
```

### 3. Проверка деплоя в кластер

**После успешного workflow проверить:**
- [ ] Новый образ загружен в кластер
- [ ] Pods перезапустились с новым образом
- [ ] Deployment показывает правильный image tag
- [ ] Pods в статусе `Running`

**Команды:**
```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Проверить deployment
kubectl get deployment api-gateway -n maratea -o yaml | grep image:

# Проверить pods
kubectl get pods -n maratea -l app=api-gateway

# Проверить образы в pods
kubectl describe pod <pod-name> -n maratea | grep Image:
```

### 4. Проверка синхронизации секретов

**Что проверить:**
- [ ] Секреты в кластере соответствуют GitHub Secrets
- [ ] `ghcr-secret` обновлен с актуальным токеном
- [ ] `timeweb-api-token` содержит правильный токен
- [ ] `app-secrets` содержит актуальные URL для БД

**Команды:**
```bash
# Проверить секреты
kubectl get secrets -n maratea

# Проверить содержимое секрета (base64 декодировать)
kubectl get secret ghcr-secret -n maratea -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

### 5. Проверка работоспособности после деплоя

**Что проверить:**
- [ ] API Gateway отвечает на health check
- [ ] Новый образ работает корректно
- [ ] Логи не содержат критических ошибок

**Команды:**
```bash
# Health check через ingress
curl https://api.staging.betaserver.ru/health

# Health check через port-forward
kubectl port-forward -n maratea svc/api-gateway 8080:8080 &
curl http://localhost:8080/health
pkill -f "kubectl port-forward"

# Проверить логи
kubectl logs -n maratea -l app=api-gateway --tail=50
```

### 6. Проверка обновления образов

**Что проверить:**
- [ ] Deployment использует образ с тегом `${{ github.sha }}`
- [ ] Старые pods заменены новыми
- [ ] Rollout прошел успешно

**Команды:**
```bash
# Проверить текущий образ в deployment
kubectl get deployment api-gateway -n maratea -o jsonpath='{.spec.template.spec.containers[0].image}'

# Проверить историю rollout
kubectl rollout history deployment/api-gateway -n maratea

# Проверить статус rollout
kubectl rollout status deployment/api-gateway -n maratea
```

## Потенциальные проблемы и решения

### Проблема 1: Workflow не может подключиться к кластеру
**Симптомы:** Ошибка `Unable to connect to the server` в шаге `Configure kubectl`
**Решение:**
- Проверить, что `KUBECONFIG` секрет содержит актуальный kubeconfig
- Убедиться, что kubeconfig закодирован в base64
- Проверить, что кластер доступен из интернета

### Проблема 2: Не удается загрузить образ из GHCR
**Симптомы:** `ImagePullBackOff` в pods
**Решение:**
- Проверить, что `ghcr-secret` создан и содержит правильный токен
- Убедиться, что образ опубликован в GHCR
- Проверить права доступа к GHCR

### Проблема 3: Deployment не обновляется
**Симптомы:** Pods остаются на старом образе
**Решение:**
- Проверить, что манифест deployment обновлен с новым образом
- Убедиться, что `kubectl apply` выполняется успешно
- Проверить, нет ли конфликтов с ArgoCD (если используется)

### Проблема 4: Health check не проходит
**Симптомы:** Workflow падает на шаге `Health check`
**Решение:**
- Проверить, что API Gateway запущен и отвечает
- Убедиться, что порт-forward работает корректно
- Проверить логи API Gateway на наличие ошибок

## Критерии успешного завершения

- [ ] Workflow выполняется без ошибок
- [ ] Образ успешно публикуется в GHCR
- [ ] Deployment обновляется с новым образом
- [ ] Pods перезапускаются и работают
- [ ] Health check проходит успешно
- [ ] API доступен через HTTPS после деплоя

## Следующие шаги после проверки

После успешной проверки CI/CD:
1. Документировать результаты проверки
2. Настроить уведомления о деплоях (опционально)
3. Перейти к шагу 3: Настройка ArgoCD (если требуется)

## Дополнительные улучшения (опционально)

- Добавить автоматические тесты перед деплоем
- Настроить rollback при неудачном деплое
- Добавить мониторинг деплоев
- Настроить уведомления в Slack/Telegram
- Добавить staging environment для тестирования

