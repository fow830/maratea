# Статус деплоя метрик Prometheus

Дата: 2025-11-18

## 📊 Текущий статус

### Код
- ✅ Метрики Prometheus добавлены в API Gateway
- ✅ Код закоммичен локально (10 коммитов впереди origin/main)
- ⏳ Изменения не запушены в GitHub

### Деплой
- ❌ API Gateway использует старый образ: `ghcr.io/fow830/maratea/api-gateway:0dbf01bec360078d2b89fc009abd7355d824c7cb`
- ❌ Endpoint `/metrics` возвращает 404 (метрики недоступны)
- ⏳ Новый образ еще не собран

### Prometheus
- ✅ ServiceMonitor создан и применен
- ✅ Prometheus Rules загружены (maratea-alerts: 1 группа)
- ⚠️  Targets видны, но в статусе `down` (метрики недоступны)
- ⚠️  Ошибка: `Get "http://10.244.36.248:8080/metrics": context deadline exceeded`

---

## 🔧 Следующие шаги

### 1. Запушить изменения в GitHub

```bash
git push origin main
```

Это запустит GitHub Actions workflow, который:
- Соберет новый Docker образ с метриками
- Запушит образ в GHCR
- Обновит deployment в Kubernetes (через ArgoCD)

### 2. Дождаться деплоя

После push:
1. GitHub Actions соберет образ (5-10 минут)
2. ArgoCD синхронизирует изменения (автоматически или вручную)
3. API Gateway перезапустится с новым образом

### 3. Проверить метрики

После деплоя выполнить:

```bash
export KUBECONFIG=./copypast/twc-cute-grosbeak-config.yaml

# Проверить endpoint /metrics
kubectl port-forward -n maratea svc/api-gateway 8080:8080
curl http://localhost:8080/metrics

# Проверить в Prometheus
kubectl port-forward -n observability svc/monitoring-kube-prometheus-prometheus 9090:9090
# Открыть http://localhost:9090/targets
# Проверить, что api-gateway в статусе "up"
```

Или использовать скрипт:

```bash
./scripts/verify-metrics.sh
```

---

## 📝 Проверка после деплоя

### Ожидаемый результат

1. **Endpoint /metrics доступен:**
   ```bash
   curl http://localhost:8080/metrics
   # Должен вернуть метрики в формате Prometheus
   ```

2. **Prometheus targets в статусе "up":**
   - Открыть http://localhost:9090/targets
   - `api-gateway` должен быть в статусе `up`

3. **Метрики доступны в Prometheus:**
   ```promql
   # Проверить в Prometheus UI
   up{job="api-gateway"}
   http_requests_total
   http_request_duration_seconds
   ```

4. **Алерты работают:**
   - Prometheus Rules загружены
   - Алерты будут срабатывать при соответствующих условиях

---

## 🐛 Устранение проблем

### Проблема: Метрики все еще недоступны после деплоя

1. Проверить, что новый образ задеплоен:
   ```bash
   kubectl get pods -n maratea -l app=api-gateway -o jsonpath='{.items[0].status.containerStatuses[0].image}'
   ```

2. Проверить логи API Gateway:
   ```bash
   kubectl logs -n maratea -l app=api-gateway --tail=50
   ```

3. Проверить ServiceMonitor:
   ```bash
   kubectl get servicemonitor -n maratea
   kubectl describe servicemonitor api-gateway -n maratea
   ```

4. Проверить Prometheus конфигурацию:
   ```bash
   kubectl port-forward -n observability svc/monitoring-kube-prometheus-prometheus 9090:9090
   # Открыть http://localhost:9090/config
   # Проверить, что ServiceMonitor обнаружен
   ```

### Проблема: Targets в статусе "down"

1. Проверить доступность endpoint:
   ```bash
   kubectl exec -n maratea -it <api-gateway-pod> -- curl http://localhost:8080/metrics
   ```

2. Проверить Network Policy:
   ```bash
   kubectl get networkpolicy -n maratea
   ```

3. Проверить Service:
   ```bash
   kubectl get svc api-gateway -n maratea
   kubectl describe svc api-gateway -n maratea
   ```

---

## 📚 Документация

- [Prometheus Metrics](https://prometheus.io/docs/concepts/metric_types/)
- [ServiceMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#servicemonitor)
- [prom-client](https://github.com/siimon/prom-client)

