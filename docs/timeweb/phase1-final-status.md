# Phase 1: Финальный статус и инструкции

Дата: 2025-11-18

## 📊 Текущий статус

### ✅ Автоматически выполнено

1. **Инфраструктура:**
   - ✅ Все Kubernetes манифесты применены
   - ✅ Ingress для ArgoCD и Grafana созданы
   - ✅ Certificate ресурсы созданы
   - ✅ PostgreSQL backup CronJob применен
   - ✅ Redis backup CronJob работает

2. **Готово к использованию:**
   - ✅ API Gateway работает на `api.staging.betaserver.ru`
   - ✅ ArgoCD установлен и настроен
   - ✅ Prometheus/Grafana установлены
   - ✅ Loki/Promtail установлены
   - ✅ Alertmanager настроен

### ⏳ Требует ручной настройки

1. **DNS записи** (5 минут)
2. **S3 credentials** (10 минут)
3. **Webhook URL'ы** (5 минут)

---

## 🚀 Быстрое выполнение оставшихся задач

### Задача 1: Настройка DNS (5 минут)

**Что нужно:**
1. Откройте панель управления DNS для домена `betaserver.ru`
2. Создайте 2 A записи:

```
Имя: argocd.staging
Тип: A
Значение: 62.76.233.233
TTL: 300

Имя: grafana.staging
Тип: A
Значение: 62.76.233.233
TTL: 300
```

3. Сохраните изменения

**Проверка:**
```bash
dig +short argocd.staging.betaserver.ru
dig +short grafana.staging.betaserver.ru
# Ожидаемый результат: 62.76.233.233
```

**После настройки DNS:**
- Cert-manager автоматически получит TLS сертификаты (5-10 минут)
- Проверка: `kubectl get certificate -A`

---

### Задача 2: Настройка S3 Backup (10 минут)

**Шаг 1: Создание S3 Bucket**

1. Войдите в панель Timeweb Cloud
2. Перейдите в **Object Storage** (S3)
3. Создайте bucket:
   - Имя: `maratea-backups`
   - Регион: `ru-1`
   - Версионирование: Включить

**Шаг 2: Заполнение секрета**

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Отредактировать секрет
kubectl edit secret s3-backup-secret -n maratea
```

Замените значения:
```yaml
stringData:
  S3_ENDPOINT: "s3.timeweb.cloud"  # или ваш endpoint
  S3_ACCESS_KEY: "ваш_real_access_key"
  S3_SECRET_KEY: "ваш_real_secret_key"
  S3_BUCKET: "maratea-backups"
  S3_REGION: "ru-1"
```

**Шаг 3: Проверка**

```bash
# Проверить секрет
kubectl get secret s3-backup-secret -n maratea

# Запустить тестовый backup
kubectl create job --from=cronjob/postgres-backup-s3 postgres-backup-test-$(date +%s) -n maratea

# Проверить логи
kubectl logs -n maratea job/postgres-backup-test-<timestamp>
```

**Или используйте интерактивный скрипт:**
```bash
./scripts/setup-s3-backup.sh
```

---

### Задача 3: Настройка Webhook уведомлений (5 минут)

#### Вариант A: Slack

1. Перейдите на https://api.slack.com/apps
2. Создайте приложение → Incoming Webhooks → Добавьте webhook
3. Скопируйте Webhook URL

**Настройка:**
```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml
kubectl edit secret alertmanager-config -n observability
```

Раскомментируйте и обновите:
```yaml
webhook_configs:
  - url: 'https://hooks.slack.com/services/YOUR_TEAM_ID/YOUR_BOT_ID/YOUR_TOKEN'
    send_resolved: true
```

Перезапустите:
```bash
kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability
```

#### Вариант B: Telegram

1. Найдите @BotFather в Telegram
2. Отправьте `/newbot` и создайте бота
3. Сохраните Bot Token
4. Получите Chat ID: `https://api.telegram.org/bot<TOKEN>/getUpdates`

**Настройка:**
```bash
kubectl edit secret alertmanager-config -n observability
```

Раскомментируйте секцию для Telegram и заполните Bot Token и Chat ID.

**Или используйте интерактивный скрипт:**
```bash
./scripts/setup-webhook-alerts.sh
```

---

## ✅ Проверка завершения Phase 1

После выполнения всех задач запустите:

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml
./scripts/complete-phase1-setup.sh
```

Скрипт покажет:
- ✅ DNS настроен
- ✅ S3 Backup настроен
- ✅ Webhook уведомления настроены

---

## 📋 Чек-лист

- [ ] DNS записи созданы для `argocd.staging.betaserver.ru`
- [ ] DNS записи созданы для `grafana.staging.betaserver.ru`
- [ ] DNS проверено: `dig +short argocd.staging.betaserver.ru`
- [ ] TLS сертификаты получены: `kubectl get certificate -A`
- [ ] S3 bucket создан в Timeweb Cloud
- [ ] S3 secret заполнен реальными credentials
- [ ] Тестовый PostgreSQL backup выполнен успешно
- [ ] Slack webhook создан или Telegram bot настроен
- [ ] Alertmanager конфигурация обновлена
- [ ] Тестовый alert отправлен и получен

---

## 🔍 Команды для проверки

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Общая проверка
./scripts/complete-phase1-setup.sh

# DNS
dig +short argocd.staging.betaserver.ru
dig +short grafana.staging.betaserver.ru

# TLS
kubectl get certificate -A
kubectl describe certificate argocd-server-tls -n argocd

# S3 Backup
kubectl get secret s3-backup-secret -n maratea
kubectl get cronjob -n maratea
kubectl get jobs -n maratea

# Webhook
kubectl get secret alertmanager-config -n observability
kubectl logs -n observability alertmanager-monitoring-kube-prometheus-alertmanager-0
```

---

## 📚 Дополнительная документация

- `docs/timeweb/manual-setup-checklist.md` - Подробный чек-лист
- `docs/timeweb/s3-backup-setup.md` - Инструкции по S3
- `docs/timeweb/webhook-setup.md` - Инструкции по webhook'ам
- `docs/timeweb/phase1-complete.md` - Полный отчет Phase 1

---

## ⏱️ Время выполнения

- DNS: ~5 минут
- S3 Backup: ~10 минут
- Webhook: ~5 минут

**Итого: ~20 минут для завершения Phase 1 на 100%**

