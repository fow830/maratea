# Чек-лист ручной настройки Phase 1

Дата: 2025-11-18

## ✅ Задачи для выполнения вручную

### 1. Настройка DNS записей

**Статус:** ⏳ Требует выполнения

**Действия:**
1. Откройте панель управления DNS для домена `betaserver.ru`
2. Создайте DNS записи типа A:

   **Для ArgoCD:**
   - Имя/Хост: `argocd.staging`
   - Тип: `A`
   - Значение/IP: `62.76.233.233`
   - TTL: `300` секунд

   **Для Grafana:**
   - Имя/Хост: `grafana.staging`
   - Тип: `A`
   - Значение/IP: `62.76.233.233`
   - TTL: `300` секунд

3. Сохраните изменения

**Проверка:**
```bash
dig +short argocd.staging.betaserver.ru
# Ожидаемый результат: 62.76.233.233

dig +short grafana.staging.betaserver.ru
# Ожидаемый результат: 62.76.233.233
```

**Автоматизация:**
```bash
./scripts/setup-dns-argocd-grafana.sh
```

**После настройки DNS:**
- Cert-manager автоматически получит TLS сертификаты
- Проверка: `kubectl get certificate -A`

---

### 2. Настройка S3 Backup

**Статус:** ⏳ Требует выполнения

#### Шаг 1: Создание S3 Bucket

1. Войдите в панель управления Timeweb Cloud
2. Перейдите в раздел **"Object Storage"** (S3)
3. Создайте новый bucket:
   - **Имя:** `maratea-backups`
   - **Регион:** `ru-1` (Санкт-Петербург)
   - **Версионирование:** Включить (рекомендуется)
4. Запишите:
   - Endpoint (обычно `s3.timeweb.cloud`)
   - Access Key ID
   - Secret Access Key
   - Region (`ru-1`)

#### Шаг 2: Настройка секрета

**Вариант A: Через интерактивный скрипт (рекомендуется)**
```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml
./scripts/setup-s3-backup.sh
```

**Вариант B: Вручную**
```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Отредактировать файл
nano infrastructure/kubernetes/backup/s3-secret.yaml
# Заменить placeholder значения на реальные

# Применить
kubectl apply -f infrastructure/kubernetes/backup/s3-secret.yaml
```

#### Шаг 3: Применение манифестов

```bash
kubectl apply -f infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml
```

#### Шаг 4: Тестирование

```bash
# Создать тестовый backup
kubectl create job --from=cronjob/postgres-backup-s3 postgres-backup-test-$(date +%s) -n maratea

# Проверить логи
kubectl logs -n maratea job/postgres-backup-test-<timestamp>

# Проверить backup в S3
aws --endpoint-url=https://s3.timeweb.cloud s3 ls s3://maratea-backups/postgres/
```

**Документация:** `docs/timeweb/s3-backup-setup.md`

---

### 3. Настройка Webhook уведомлений

**Статус:** ⏳ Требует выполнения

#### Вариант A: Slack

1. Перейдите на https://api.slack.com/apps
2. Создайте приложение или выберите существующее
3. Активируйте **Incoming Webhooks**
4. Добавьте webhook в workspace
5. Скопируйте **Webhook URL**

**Настройка:**
```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml
./scripts/setup-webhook-alerts.sh
# Выберите опцию 1 (Slack)
# Введите Webhook URL
```

Или вручную:
```bash
kubectl edit secret alertmanager-config -n observability
# Раскомментируйте секцию для Slack и вставьте Webhook URL
kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability
```

#### Вариант B: Telegram

1. Откройте Telegram и найдите [@BotFather](https://t.me/botfather)
2. Отправьте `/newbot` и следуйте инструкциям
3. Сохраните **Bot Token**
4. Создайте группу и добавьте бота
5. Получите **Chat ID** через: `https://api.telegram.org/bot<BOT_TOKEN>/getUpdates`

**Настройка:**
```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml
./scripts/setup-webhook-alerts.sh
# Выберите опцию 2 (Telegram)
# Введите Bot Token и Chat ID
```

#### Тестирование

```bash
# Port-forward Alertmanager
kubectl port-forward -n observability svc/alertmanager-monitoring-kube-prometheus-alertmanager 9093:9093

# Отправить тестовый alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "severity": "critical"
    },
    "annotations": {
      "summary": "Test alert",
      "description": "This is a test alert"
    }
  }]'
```

**Документация:** `docs/timeweb/webhook-setup.md`

---

## 📋 Быстрый чек-лист

- [ ] DNS записи созданы для `argocd.staging.betaserver.ru`
- [ ] DNS записи созданы для `grafana.staging.betaserver.ru`
- [ ] DNS проверено: `dig +short argocd.staging.betaserver.ru`
- [ ] TLS сертификаты получены: `kubectl get certificate -A`
- [ ] S3 bucket создан в Timeweb Cloud
- [ ] S3 secret заполнен и применен
- [ ] PostgreSQL backup с S3 применен
- [ ] Тестовый backup выполнен успешно
- [ ] Slack webhook создан или Telegram bot настроен
- [ ] Alertmanager конфигурация обновлена
- [ ] Тестовый alert отправлен и получен

## 🔍 Команды для проверки

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# DNS
dig +short argocd.staging.betaserver.ru
dig +short grafana.staging.betaserver.ru

# TLS сертификаты
kubectl get certificate -A
kubectl describe certificate argocd-server-tls -n argocd
kubectl describe certificate grafana-tls -n observability

# S3 Backup
kubectl get secret s3-backup-secret -n maratea
kubectl get cronjob -n maratea
kubectl get jobs -n maratea

# Webhook
kubectl get secret alertmanager-config -n observability
kubectl logs -n observability alertmanager-monitoring-kube-prometheus-alertmanager-0
```

## 📚 Дополнительная документация

- `docs/timeweb/s3-backup-setup.md` - Подробные инструкции по S3 backup
- `docs/timeweb/webhook-setup.md` - Подробные инструкции по webhook'ам
- `docs/timeweb/phase1-complete.md` - Итоговый отчет Phase 1

