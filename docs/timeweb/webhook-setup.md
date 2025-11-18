# Настройка Webhook уведомлений для Alertmanager

## Обзор

Alertmanager настроен для отправки уведомлений через webhook'и. Поддерживаются:
- **Slack** - через Incoming Webhooks
- **Telegram** - через Bot API

## Вариант 1: Настройка Slack

### Шаг 1: Создание Slack Incoming Webhook

1. Перейдите на https://api.slack.com/apps
2. Создайте новое приложение или выберите существующее
3. Перейдите в **"Incoming Webhooks"**
4. Активируйте Incoming Webhooks
5. Нажмите **"Add New Webhook to Workspace"**
6. Выберите канал для уведомлений
7. Скопируйте **Webhook URL** (формат: `https://hooks.slack.com/services/TEAM_ID/BOT_ID/WEBHOOK_TOKEN` - замените на ваш реальный URL)

### Шаг 2: Обновление конфигурации Alertmanager

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Отредактировать конфигурацию
kubectl edit secret alertmanager-config -n observability
```

Раскомментируйте и заполните секцию для Slack:

```yaml
stringData:
  alertmanager.yml: |
    receivers:
      - name: 'critical-alerts'
        webhook_configs:
          - url: 'https://hooks.slack.com/services/YOUR_TEAM_ID/YOUR_BOT_ID/YOUR_WEBHOOK_TOKEN'
            send_resolved: true
            title: '🚨 Critical Alert: {{ .GroupLabels.alertname }}'
            text: |
              {{ range .Alerts }}
              *Alert:* {{ .Annotations.summary }}
              *Description:* {{ .Annotations.description }}
              *Severity:* {{ .Labels.severity }}
              *Namespace:* {{ .Labels.namespace }}
              {{ end }}
```

### Шаг 3: Перезапуск Alertmanager

```bash
kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability
```

## Вариант 2: Настройка Telegram

### Шаг 1: Создание Telegram Bot

1. Откройте Telegram и найдите бота [@BotFather](https://t.me/botfather)
2. Отправьте команду `/newbot`
3. Следуйте инструкциям для создания бота
4. Сохраните **Bot Token** (формат: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### Шаг 2: Получение Chat ID

1. Создайте группу в Telegram или используйте личный чат
2. Добавьте вашего бота в группу
3. Отправьте любое сообщение боту
4. Откройте в браузере:
   ```
   https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
   ```
5. Найдите `chat.id` в ответе (для группы это будет отрицательное число)

### Шаг 3: Обновление конфигурации Alertmanager

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml
kubectl edit secret alertmanager-config -n observability
```

Раскомментируйте и заполните секцию для Telegram:

```yaml
stringData:
  alertmanager.yml: |
    receivers:
      - name: 'critical-alerts'
        webhook_configs:
          - url: 'https://api.telegram.org/bot<BOT_TOKEN>/sendMessage'
            send_resolved: true
            http_config:
              method: POST
            body: |
              {
                "chat_id": "<CHAT_ID>",
                "text": "🚨 *Critical Alert*\n\n*Alert:* {{ .GroupLabels.alertname }}\n{{ range .Alerts }}{{ .Annotations.description }}{{ end }}",
                "parse_mode": "Markdown"
              }
```

Замените:
- `<BOT_TOKEN>` на ваш Bot Token
- `<CHAT_ID>` на ваш Chat ID

### Шаг 4: Перезапуск Alertmanager

```bash
kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability
```

## Тестирование уведомлений

### Создание тестового алерта

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Создать тестовый alert через Prometheus
kubectl port-forward -n observability svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Откройте http://localhost:9090 и выполните:

```promql
# Создать тестовый alert
ALERT TestAlert
IF up == 0
FOR 1m
LABELS {severity="critical"}
ANNOTATIONS {
  summary="Test alert",
  description="This is a test alert"
}
```

### Ручная отправка через Alertmanager API

```bash
# Port-forward Alertmanager
kubectl port-forward -n observability svc/alertmanager-monitoring-kube-prometheus-alertmanager 9093:9093

# Отправить тестовый alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[
    {
      "labels": {
        "alertname": "TestAlert",
        "severity": "critical",
        "namespace": "maratea"
      },
      "annotations": {
        "summary": "Test alert",
        "description": "This is a test alert for webhook notification"
      }
    }
  ]'
```

## Проверка конфигурации

### Проверить текущую конфигурацию Alertmanager

```bash
# Port-forward
kubectl port-forward -n observability svc/alertmanager-monitoring-kube-prometheus-alertmanager 9093:9093

# Проверить конфигурацию
curl http://localhost:9093/api/v1/status/config
```

### Проверить статус Alertmanager

```bash
kubectl get pods -n observability | grep alertmanager
kubectl logs -n observability alertmanager-monitoring-kube-prometheus-alertmanager-0
```

## Примеры алертов

### Алерт на недоступность API Gateway

```yaml
- alert: APIGatewayDown
  expr: up{job="api-gateway"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "API Gateway is down"
    description: "API Gateway has been down for more than 1 minute"
```

### Алерт на высокое использование CPU

```yaml
- alert: HighCPUUsage
  expr: rate(container_cpu_usage_seconds_total{namespace="maratea"}[5m]) > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High CPU usage detected"
    description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has high CPU usage"
```

### Алерт на failed backup

```yaml
- alert: BackupJobFailed
  expr: kube_job_status_failed{namespace="maratea",job_name=~"postgres-backup.*|redis-backup.*"} > 0
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Backup job failed"
    description: "Backup job {{ $labels.job_name }} failed in namespace {{ $labels.namespace }}"
```

## Устранение проблем

### Уведомления не приходят

1. Проверьте логи Alertmanager:
   ```bash
   kubectl logs -n observability alertmanager-monitoring-kube-prometheus-alertmanager-0
   ```

2. Проверьте конфигурацию:
   ```bash
   kubectl get secret alertmanager-config -n observability -o jsonpath='{.data.alertmanager\.yml}' | base64 -d
   ```

3. Проверьте доступность webhook URL:
   ```bash
   curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL -d '{"text":"test"}'
   ```

### Ошибки формата в Telegram

- Убедитесь, что используете правильный формат JSON
- Проверьте, что Bot Token и Chat ID корректны
- Используйте `parse_mode: "Markdown"` для форматирования

## Безопасность

- ✅ Не коммитьте webhook URL'ы в репозиторий
- ✅ Используйте Kubernetes Secrets для хранения чувствительных данных
- ✅ Ограничьте доступ к Alertmanager API
- ✅ Регулярно ротируйте Bot Tokens (для Telegram)

