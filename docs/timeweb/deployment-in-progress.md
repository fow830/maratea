# Деплой метрик Prometheus - В процессе

Дата: 2025-11-18

## ✅ Выполнено

1. ✅ Код с метриками закоммичен и запушен в GitHub
2. ✅ GitHub Actions запущен для сборки нового Docker образа
3. ✅ Скрипты мониторинга созданы

## ⏳ В процессе

### GitHub Actions
- **Статус:** Сборка Docker образа
- **Время:** 5-10 минут
- **Проверка:** https://github.com/fow830/maratea/actions

### ArgoCD
- **Статус:** Ожидание нового образа
- **Синхронизация:** Автоматическая (auto-sync включен)
- **Проверка:**
  ```bash
  kubectl get application maratea-staging -n argocd
  ```

### API Gateway
- **Текущий образ:** `ghcr.io/fow830/maratea/api-gateway:latest`
- **Статус:** Ожидание обновления
- **Pods:** 2/2 Running

---

## 🔍 Мониторинг деплоя

### Автоматический мониторинг

```bash
# Отслеживание деплоя (ждет обновления образа)
./scripts/wait-for-deployment.sh

# Проверка текущего статуса
./scripts/monitor-deployment.sh

# Проверка метрик после деплоя
./scripts/verify-metrics.sh
```

### Ручная проверка

```bash
export KUBECONFIG=./copypast/twc-cute-grosbeak-config.yaml

# Проверка образа deployment
kubectl get deployment api-gateway -n maratea -o jsonpath='{.spec.template.spec.containers[0].image}'

# Проверка pods
kubectl get pods -n maratea -l app=api-gateway -o wide

# Проверка логов
kubectl logs -n maratea -l app=api-gateway --tail=50

# Проверка endpoint /metrics
kubectl port-forward -n maratea svc/api-gateway 8080:8080
curl http://localhost:8080/metrics
```

---

## 📊 Ожидаемый результат

После успешного деплоя:

1. **Новый образ задеплоен:**
   - Образ будет содержать метрики Prometheus
   - Endpoint `/metrics` будет доступен

2. **Prometheus начнет собирать метрики:**
   - Targets будут в статусе `up`
   - Метрики будут доступны в Prometheus UI

3. **Алерты начнут работать:**
   - Prometheus Rules будут активны
   - Алерты будут срабатывать при соответствующих условиях

---

## 🐛 Устранение проблем

### Проблема: GitHub Actions не запустился

1. Проверить статус: https://github.com/fow830/maratea/actions
2. Проверить секреты: `GHCR_TOKEN`, `KUBECONFIG`
3. Проверить логи workflow

### Проблема: ArgoCD не синхронизирует

1. Проверить статус Application:
   ```bash
   kubectl get application maratea-staging -n argocd
   kubectl describe application maratea-staging -n argocd
   ```

2. Принудительная синхронизация:
   ```bash
   kubectl patch application maratea-staging -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
   ```

3. Или через ArgoCD UI:
   - Открыть https://argocd.staging.betaserver.ru
   - Найти application `maratea-staging`
   - Нажать "Sync"

### Проблема: Pods не обновляются

1. Проверить статус deployment:
   ```bash
   kubectl get deployment api-gateway -n maratea
   kubectl describe deployment api-gateway -n maratea
   ```

2. Проверить события:
   ```bash
   kubectl get events -n maratea --sort-by='.lastTimestamp' | tail -20
   ```

3. Принудительный перезапуск:
   ```bash
   kubectl rollout restart deployment/api-gateway -n maratea
   ```

---

## ⏱️ Временные рамки

- **GitHub Actions:** 5-10 минут (сборка образа)
- **ArgoCD синхронизация:** 1-2 минуты (автоматически)
- **Rollout deployment:** 1-2 минуты
- **Итого:** ~10-15 минут

---

## 📝 Следующие шаги после деплоя

1. ✅ Проверить endpoint `/metrics`
2. ✅ Проверить targets в Prometheus
3. ✅ Проверить метрики в Prometheus UI
4. ✅ Создать Grafana dashboards
5. ✅ Протестировать алерты

