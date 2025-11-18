# Тестирование системы мониторинга - Завершено

Дата: 2025-11-18

## ✅ Выполненные задачи

### 1. Создание Prometheus Alert Rules

**Статус:** ✅ Созданы и применены

**Файл:** `infrastructure/kubernetes/monitoring/prometheus-alerts.yaml`

**Группы правил:**
- **api-gateway** (4 правила)
  - `APIGatewayDown` - API Gateway недоступен (critical)
  - `APIGatewayHealthCheckFailed` - Health check failed (critical)
  - `APIGatewayHighLatency` - Высокая задержка (warning)
  - `APIGatewayHighErrorRate` - Высокая частота ошибок (warning)

- **postgresql** (4 правила)
  - `PostgreSQLDown` - PostgreSQL недоступен (critical)
  - `PostgreSQLHighCPU` - Высокое использование CPU (warning)
  - `PostgreSQLHighMemory` - Высокое использование памяти (warning)
  - `PostgreSQLTooManyConnections` - Слишком много подключений (warning)

- **redis** (3 правила)
  - `RedisDown` - Redis недоступен (critical)
  - `RedisHighMemory` - Высокое использование памяти (warning)
  - `RedisSlowResponse` - Медленный ответ (warning)

- **kubernetes-resources** (4 правила)
  - `PodCrashLooping` - Pod в CrashLoopBackOff (critical)
  - `PodNotReady` - Pod не готов (warning)
  - `NamespaceHighCPU` - Высокое использование CPU (warning)
  - `NamespaceHighMemory` - Высокое использование памяти (warning)

- **backup** (2 правила)
  - `BackupJobFailed` - Backup job failed (warning)
  - `BackupJobNotScheduled` - Backup не выполнен вовремя (warning)

- **disk-space** (2 правила)
  - `DiskSpaceLow` - Недостаточно места на диске (warning)
  - `DiskSpaceCritical` - Критически мало места (critical)

**Всего:** 19 правил алертинга

### 2. Создание ServiceMonitor для API Gateway

**Статус:** ✅ Создан

**Файл:** `infrastructure/kubernetes/monitoring/servicemonitor-api-gateway.yaml`

**Конфигурация:**
- Namespace: `maratea`
- Label: `release: monitoring` (для обнаружения Prometheus)
- Endpoint: `/metrics` на порту `http`
- Interval: 30s

### 3. Скрипт тестирования мониторинга

**Статус:** ✅ Создан

**Файл:** `scripts/test-monitoring.sh`

**Функциональность:**
- Проверка статуса компонентов (Prometheus, Grafana, Alertmanager, Loki)
- Проверка загруженных Prometheus Rules
- Проверка метрик приложения
- Проверка активных алертов в Alertmanager
- Проверка статуса Grafana и Loki

---

## 📊 Текущий статус

### Компоненты мониторинга
| Компонент | Статус | Примечание |
|-----------|--------|------------|
| Prometheus | ✅ Running | Готов к работе |
| Grafana | ✅ Running | Доступен через Ingress |
| Alertmanager | ✅ Running | Webhook настроен |
| Loki | ✅ Running | Логи собираются |

### Prometheus Rules
| Ресурс | Статус | Правил |
|--------|--------|--------|
| maratea-alerts | ✅ Создан | 19 правил |

### ServiceMonitor
| Ресурс | Статус | Endpoint |
|--------|--------|----------|
| api-gateway | ✅ Создан | /metrics |

---

## 🔍 Проверка работы

### 1. Проверка Prometheus Rules

```bash
export KUBECONFIG=./copypast/twc-cute-grosbeak-config.yaml
kubectl get prometheusrule maratea-alerts -n observability
```

### 2. Проверка ServiceMonitor

```bash
kubectl get servicemonitor -n maratea
```

### 3. Проверка метрик в Prometheus

```bash
# Port-forward
kubectl port-forward -n observability svc/monitoring-kube-prometheus-prometheus 9090:9090

# Открыть в браузере
# http://localhost:9090
# Проверить: Status → Targets
# Проверить: Status → Rules
```

### 4. Запуск тестового скрипта

```bash
./scripts/test-monitoring.sh
```

---

## 📝 Следующие шаги

1. ✅ Prometheus Rules созданы
2. ✅ ServiceMonitor создан
3. ⏳ Проверить, что API Gateway экспортирует метрики на `/metrics`
4. ⏳ Настроить дополнительные ServiceMonitor для PostgreSQL и Redis (если доступны метрики)
5. ⏳ Создать Grafana dashboards для визуализации метрик

---

## 🎯 Рекомендации

### Для API Gateway
Убедитесь, что API Gateway экспортирует метрики Prometheus на `/metrics`. Если нет, нужно добавить:
- Prometheus metrics endpoint в Fastify
- Использовать `@fastify/metrics` или `prom-client`

### Для PostgreSQL и Redis
Если доступны метрики через exporters:
- Создать ServiceMonitor для PostgreSQL exporter
- Создать ServiceMonitor для Redis exporter

### Для Grafana
Создать дашборды:
- API Gateway: latency, error rate, request rate
- PostgreSQL: connections, CPU, memory
- Redis: memory usage, commands rate
- Kubernetes: pod status, resource usage

---

## 📚 Документация

- [Prometheus Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [ServiceMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#servicemonitor)
- [Grafana Dashboards](https://grafana.com/docs/grafana/latest/dashboards/)

