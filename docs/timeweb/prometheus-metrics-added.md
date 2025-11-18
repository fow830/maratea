# Prometheus Metrics - Добавлены в API Gateway ✅

Дата: 2025-11-18

## ✅ Выполнено

### Добавлен endpoint `/metrics` для Prometheus

**Файлы:**
- `services/api-gateway/src/plugins/metrics.ts` - плагин для сбора метрик
- `services/api-gateway/src/types/fastify.d.ts` - типы для TypeScript
- Обновлен `services/api-gateway/src/index.ts` - регистрация плагина
- Обновлен `services/api-gateway/src/handlers/proxy.ts` - интеграция метрик в proxy handler

**Зависимости:**
- `prom-client@15.1.3` - библиотека для Prometheus метрик

---

## 📊 Доступные метрики

### HTTP метрики
- `http_request_duration_seconds` - длительность HTTP запросов (histogram)
  - Labels: `method`, `route`, `status_code`
- `http_requests_total` - общее количество HTTP запросов (counter)
  - Labels: `method`, `route`, `status_code`
- `http_request_errors_total` - количество ошибок HTTP запросов (counter)
  - Labels: `method`, `route`, `error_type`

### Proxy метрики
- `proxy_request_duration_seconds` - длительность proxy запросов (histogram)
  - Labels: `target`, `method`, `status_code`
- `proxy_requests_total` - общее количество proxy запросов (counter)
  - Labels: `target`, `method`, `status_code`

### Circuit Breaker метрики
- `circuit_breaker_state` - состояние circuit breaker (gauge)
  - Labels: `target`
  - Значения: 0=closed, 1=open, 2=half-open
- `circuit_breaker_failures_total` - количество сбоев circuit breaker (counter)
  - Labels: `target`

### Rate Limiting метрики
- `rate_limit_hits_total` - количество срабатываний rate limit (counter)
  - Labels: `route`

### Process метрики
- `process_memory_usage_bytes` - использование памяти процессом (gauge)
  - Labels: `type` (heapUsed, heapTotal, rss, external)

---

## 🔍 Проверка работы

### 1. Локальная проверка

```bash
# Запустить API Gateway локально
cd services/api-gateway
pnpm dev

# В другом терминале проверить метрики
curl http://localhost:8080/metrics
```

### 2. Проверка в Kubernetes

```bash
export KUBECONFIG=./copypast/twc-cute-grosbeak-config.yaml

# Port-forward
kubectl port-forward -n maratea svc/api-gateway 8080:8080

# Проверить метрики
curl http://localhost:8080/metrics
```

### 3. Проверка в Prometheus

```bash
# Port-forward Prometheus
kubectl port-forward -n observability svc/monitoring-kube-prometheus-prometheus 9090:9090

# Открыть в браузере
# http://localhost:9090

# Проверить:
# 1. Status → Targets - должен быть виден api-gateway
# 2. Graph → ввести запрос: up{job="api-gateway"}
# 3. Graph → ввести запрос: http_requests_total
```

---

## 📝 Использование метрик в Prometheus

### Примеры запросов

```promql
# Общее количество запросов
sum(rate(http_requests_total[5m])) by (method, status_code)

# 95-й перцентиль времени ответа
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Частота ошибок
sum(rate(http_request_errors_total[5m])) by (error_type)

# Состояние circuit breaker
circuit_breaker_state

# Использование памяти
process_memory_usage_bytes
```

---

## 🎯 Интеграция с алертами

Метрики автоматически используются в Prometheus Alert Rules:

- `APIGatewayDown` - проверяет `up{job="api-gateway"} == 0`
- `APIGatewayHighLatency` - использует `http_request_duration_seconds`
- `APIGatewayHighErrorRate` - использует `http_request_errors_total`

---

## 📚 Документация

- [prom-client](https://github.com/siimon/prom-client)
- [Prometheus Metrics](https://prometheus.io/docs/concepts/metric_types/)
- [ServiceMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#servicemonitor)

---

## ✅ Следующие шаги

1. ✅ Метрики добавлены в API Gateway
2. ✅ Endpoint `/metrics` доступен
3. ✅ ServiceMonitor настроен
4. ⏳ Дождаться деплоя нового образа API Gateway
5. ⏳ Проверить сбор метрик в Prometheus
6. ⏳ Создать Grafana dashboards для визуализации

---

## 🚀 Деплой

После коммита изменений:
1. GitHub Actions автоматически соберет новый Docker образ
2. ArgoCD синхронизирует изменения
3. API Gateway будет перезапущен с новыми метриками
4. Prometheus начнет собирать метрики через ServiceMonitor

