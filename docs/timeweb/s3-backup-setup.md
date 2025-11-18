# Настройка S3 Backup для PostgreSQL и Redis

## Шаг 1: Создание S3 Bucket в Timeweb Cloud

1. Войдите в панель управления Timeweb Cloud
2. Перейдите в раздел **"Object Storage"** (S3)
3. Создайте новый bucket:
   - **Имя:** `maratea-backups`
   - **Регион:** `ru-1` (Санкт-Петербург)
   - **Версионирование:** Включить (рекомендуется)
4. Запишите следующие данные:
   - **Endpoint:** `s3.timeweb.cloud` (или ваш endpoint)
   - **Access Key ID**
   - **Secret Access Key**
   - **Region:** `ru-1`

## Шаг 2: Настройка секрета в Kubernetes

### Вариант A: Через kubectl edit

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml
kubectl edit secret s3-backup-secret -n maratea
```

Замените значения:
```yaml
stringData:
  S3_ENDPOINT: "s3.timeweb.cloud"
  S3_ACCESS_KEY: "ваш_access_key"
  S3_SECRET_KEY: "ваш_secret_key"
  S3_BUCKET: "maratea-backups"
  S3_REGION: "ru-1"
```

### Вариант B: Через файл

1. Отредактируйте `infrastructure/kubernetes/backup/s3-secret.yaml`
2. Замените placeholder значения на реальные
3. Примените:
   ```bash
   kubectl apply -f infrastructure/kubernetes/backup/s3-secret.yaml
   ```

## Шаг 3: Применение манифестов

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Применить PostgreSQL backup с S3
kubectl apply -f infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml

# Redis backup уже применен, но будет использовать S3 если секрет настроен
```

## Шаг 4: Тестирование Backup

### Тестовый запуск PostgreSQL backup

```bash
# Создать тестовый job из CronJob
kubectl create job --from=cronjob/postgres-backup-s3 postgres-backup-test-$(date +%s) -n maratea

# Проверить статус
kubectl get jobs -n maratea | grep postgres-backup-test

# Посмотреть логи
kubectl logs -n maratea job/postgres-backup-test-<timestamp>
```

### Проверка backup в S3

```bash
# Установить aws-cli (если не установлен)
# macOS: brew install awscli
# Linux: apt-get install awscli

# Настроить credentials
export AWS_ACCESS_KEY_ID="ваш_access_key"
export AWS_SECRET_ACCESS_KEY="ваш_secret_key"
export AWS_DEFAULT_REGION="ru-1"

# Проверить backup'ы PostgreSQL
aws --endpoint-url=https://s3.timeweb.cloud s3 ls s3://maratea-backups/postgres/

# Проверить backup'ы Redis
aws --endpoint-url=https://s3.timeweb.cloud s3 ls s3://maratea-backups/redis/
```

### Тестовый запуск Redis backup

```bash
# Создать тестовый job
kubectl create job --from=cronjob/redis-backup redis-backup-test-$(date +%s) -n maratea

# Проверить логи
kubectl logs -n maratea job/redis-backup-test-<timestamp>
```

## Шаг 5: Восстановление из Backup

### Восстановление PostgreSQL

```bash
# 1. Скачать backup из S3
aws --endpoint-url=https://s3.timeweb.cloud s3 cp s3://maratea-backups/postgres/postgres-backup-YYYYMMDD-HHMMSS.sql.gz /tmp/backup.sql.gz

# 2. Распаковать
gunzip /tmp/backup.sql.gz

# 3. Восстановить в базу данных
kubectl exec -it -n maratea deployment/postgres -- psql -U maratea_user -d maratea_platform < /tmp/backup.sql

# Или через port-forward
kubectl port-forward -n maratea svc/postgres 5432:5432 &
psql -h localhost -p 5432 -U maratea_user -d maratea_platform < /tmp/backup.sql
```

### Восстановление Redis

```bash
# 1. Скачать backup из S3
aws --endpoint-url=https://s3.timeweb.cloud s3 cp s3://maratea-backups/redis/redis-backup-YYYYMMDD-HHMMSS.rdb.gz /tmp/backup.rdb.gz

# 2. Распаковать
gunzip /tmp/backup.rdb.gz

# 3. Остановить Redis (чтобы избежать конфликтов)
kubectl scale deployment redis -n maratea --replicas=0

# 4. Скопировать backup в PVC
kubectl cp /tmp/backup.rdb maratea/redis-<pod-name>:/data/dump.rdb

# 5. Запустить Redis
kubectl scale deployment redis -n maratea --replicas=1
```

## Мониторинг Backup

### Проверка статуса CronJob

```bash
kubectl get cronjob -n maratea
kubectl get jobs -n maratea
```

### Настройка алертов на failed backup

Backup jobs автоматически создают метрики, которые можно мониторить через Prometheus. Настройте алерт в Alertmanager:

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

### Backup не загружается в S3

1. Проверьте credentials:
   ```bash
   kubectl get secret s3-backup-secret -n maratea -o yaml
   ```

2. Проверьте логи job:
   ```bash
   kubectl logs -n maratea job/postgres-backup-s3-<timestamp>
   ```

3. Проверьте доступность S3:
   ```bash
   aws --endpoint-url=https://s3.timeweb.cloud s3 ls
   ```

### Ошибки доступа к S3

- Убедитесь, что Access Key имеет права на запись в bucket
- Проверьте, что bucket существует и доступен
- Проверьте правильность endpoint URL

## Безопасность

- ✅ Не коммитьте реальные credentials в репозиторий
- ✅ Используйте Kubernetes Secrets для хранения credentials
- ✅ Регулярно ротируйте Access Keys
- ✅ Включите версионирование в S3 bucket
- ✅ Настройте lifecycle policy для автоматической очистки старых backup'ов

