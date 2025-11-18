# Шаг 4: Логи, Алертинг и Backup - Выполнено

Дата: 2025-11-18

## ✅ Выполненные задачи

### 1. Централизованные логи (Loki)

**Статус:** ✅ Установлен и настроен

**Детали:**
- Loki: Deployment в namespace `observability`
- Promtail: DaemonSet для сбора логов со всех nodes
- Хранение: PVC `loki-storage` (10Gi, local-path)
- Retention: 14 дней
- Интеграция: Loki добавлен как datasource в Grafana

**Компоненты:**
- `loki`: Service + Deployment + ConfigMap + PVC
- `promtail`: DaemonSet (установлен через Helm)

**Проверка:**
```bash
kubectl get pods -n observability | grep -E "loki|promtail"
kubectl get svc -n observability | grep loki
```

**Доступ к логам в Grafana:**
1. Откройте Grafana (port-forward или через Ingress)
2. Перейдите в "Explore"
3. Выберите datasource "Loki"
4. Используйте LogQL для запросов, например: `{namespace="maratea"}`

### 2. Алертинг (Alertmanager)

**Статус:** ✅ Настроен с webhook конфигурацией

**Детали:**
- Конфигурация: Secret `alertmanager-config` в namespace `observability`
- Маршрутизация:
  - Critical alerts → `critical-alerts` receiver
  - Warning alerts → `warning-alerts` receiver
  - Default → `default` receiver
- Webhook поддержка: Готов к настройке Slack/Telegram

**Настройка webhook'ов:**

Для Slack:
```yaml
webhook_configs:
  - url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
    send_resolved: true
```

Для Telegram:
```yaml
webhook_configs:
  - url: 'https://api.telegram.org/bot<BOT_TOKEN>/sendMessage'
    send_resolved: true
    http_config:
      method: POST
    body: |
      {
        "chat_id": "<CHAT_ID>",
        "text": "🚨 Alert: {{ .GroupLabels.alertname }}"
      }
```

**Проверка:**
```bash
kubectl get secret alertmanager-config -n observability
kubectl get pods -n observability | grep alertmanager
```

### 3. Улучшение Backup

**Статус:** ✅ Настроено (требует S3 credentials)

**Детали:**

#### PostgreSQL Backup (S3)
- CronJob: `postgres-backup-s3` (ежедневно в 2:00 UTC)
- Формат: `postgres-backup-YYYYMMDD-HHMMSS.sql.gz`
- Хранение: 30 дней в S3
- Автоматическая очистка старых backup'ов

#### Redis Backup
- CronJob: `redis-backup` (ежедневно в 3:00 UTC)
- Формат: `redis-backup-YYYYMMDD-HHMMSS.rdb.gz`
- Хранение: 7 дней в S3 (если настроено)
- Fallback: локальное хранение, если S3 не настроен

#### S3 Secret
- Secret: `s3-backup-secret` в namespace `maratea`
- **Требуется заполнение:** Замените placeholder значения на реальные Timeweb S3 credentials

**Настройка S3:**

1. Создайте S3 bucket в Timeweb Cloud
2. Обновите секрет:
   ```bash
   kubectl edit secret s3-backup-secret -n maratea
   ```
3. Примените PostgreSQL backup с S3:
   ```bash
   kubectl apply -f infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml
   ```

**Проверка:**
```bash
kubectl get cronjob -n maratea
kubectl get jobs -n maratea
kubectl logs -n maratea job/postgres-backup-s3-<timestamp>
kubectl logs -n maratea job/redis-backup-<timestamp>
```

## 📊 Текущий статус

| Компонент | Статус | Детали |
|-----------|--------|--------|
| Loki | ✅ | Deployment + Service, 14d retention |
| Promtail | ✅ | DaemonSet, собирает логи со всех nodes |
| Grafana Datasource | ✅ | Loki добавлен как источник данных |
| Alertmanager | ✅ | Конфигурация с webhook поддержкой |
| PostgreSQL Backup (S3) | ⏳ | Манифест готов, требует S3 credentials |
| Redis Backup | ✅ | CronJob создан, работает с/без S3 |

## 📁 Созданные файлы

1. `infrastructure/kubernetes/loki/deployment.yaml` - Loki deployment
2. `infrastructure/kubernetes/loki/grafana-datasource.yaml` - Grafana datasource config
3. `infrastructure/helm/loki-values.yaml` - Helm values для Loki (не используется, установлен через манифест)
4. `infrastructure/helm/promtail-values.yaml` - Helm values для Promtail
5. `infrastructure/kubernetes/monitoring/alertmanager-config.yaml` - Alertmanager конфигурация
6. `infrastructure/kubernetes/backup/s3-secret.yaml` - S3 credentials secret (требует заполнения)
7. `infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml` - PostgreSQL backup с S3
8. `infrastructure/kubernetes/redis/backup-cronjob.yaml` - Redis backup
9. `docs/timeweb/backup-schedule.md` - Документация по backup
10. `docs/timeweb/step4-complete.md` - Этот файл

## 🔄 Следующие шаги

### Для завершения настройки:

1. **S3 Backup:**
   - Создать S3 bucket в Timeweb Cloud
   - Заполнить `s3-backup-secret` реальными credentials
   - Применить `backup-cronjob-s3.yaml` для PostgreSQL

2. **Webhook уведомления:**
   - Настроить Slack webhook URL или Telegram bot
   - Обновить `alertmanager-config.yaml` с реальными URL
   - Перезапустить Alertmanager

3. **Тестирование:**
   - Запустить тестовый backup вручную
   - Проверить восстановление из backup
   - Протестировать алерты

## 🔍 Команды для проверки

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Loki
kubectl get pods -n observability | grep loki
kubectl get svc -n observability | grep loki
kubectl logs -n observability deployment/loki

# Promtail
kubectl get daemonset -n observability | grep promtail
kubectl logs -n observability daemonset/promtail

# Alertmanager
kubectl get pods -n observability | grep alertmanager
kubectl get secret alertmanager-config -n observability

# Backup
kubectl get cronjob -n maratea
kubectl get jobs -n maratea
kubectl get secret s3-backup-secret -n maratea
```

## 📝 Примечания

- **Loki**: Использует файловую систему для хранения (можно переключить на S3 позже)
- **Alertmanager**: Webhook URL'ы закомментированы - раскомментируйте и заполните при настройке
- **Backup**: Redis backup работает даже без S3 (сохраняет локально), PostgreSQL требует S3 для полной функциональности

