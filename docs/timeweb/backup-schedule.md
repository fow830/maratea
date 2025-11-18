# Расписание и места хранения Backup

Дата: 2025-11-18

## 📅 Расписание Backup

| Компонент | Расписание | Хранение | Место хранения |
|-----------|-----------|----------|----------------|
| PostgreSQL | Ежедневно в 2:00 UTC | 30 дней | S3 (Timeweb Object Storage) |
| Redis | Ежедневно в 3:00 UTC | 7 дней | S3 (Timeweb Object Storage) |
| Локальные backup'ы | - | 7 дней | PVC (local-path) |

## 🔧 Настройка S3 Backup

### 1. Создание S3 Bucket в Timeweb

1. Войдите в панель управления Timeweb Cloud
2. Перейдите в раздел "Object Storage" (S3)
3. Создайте новый bucket с именем `maratea-backups`
4. Запишите:
   - Endpoint URL (обычно `s3.timeweb.cloud`)
   - Access Key
   - Secret Key
   - Region (обычно `ru-1`)

### 2. Настройка секрета в Kubernetes

Обновите секрет `s3-backup-secret` с реальными credentials:

```bash
kubectl edit secret s3-backup-secret -n maratea
```

Или создайте через файл:

```bash
# Отредактируйте infrastructure/kubernetes/backup/s3-secret.yaml
# Замените YOUR_ACCESS_KEY, YOUR_SECRET_KEY на реальные значения
kubectl apply -f infrastructure/kubernetes/backup/s3-secret.yaml
```

### 3. Применение манифестов

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Применить S3 secret (после заполнения credentials)
kubectl apply -f infrastructure/kubernetes/backup/s3-secret.yaml

# Применить PostgreSQL backup с S3
kubectl apply -f infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml

# Применить Redis backup
kubectl apply -f infrastructure/kubernetes/redis/backup-cronjob.yaml
```

## 📊 Структура Backup в S3

```
maratea-backups/
├── postgres/
│   ├── postgres-backup-20241118-020000.sql.gz
│   ├── postgres-backup-20241119-020000.sql.gz
│   └── ...
└── redis/
    ├── redis-backup-20241118-030000.rdb.gz
    ├── redis-backup-20241119-030000.rdb.gz
    └── ...
```

## 🔍 Проверка Backup

### Проверить статус CronJob

```bash
kubectl get cronjob -n maratea
kubectl get jobs -n maratea
```

### Проверить последний backup PostgreSQL

```bash
# Посмотреть логи последнего job
kubectl logs -n maratea job/postgres-backup-s3-<timestamp>

# Проверить backup'ы в S3
aws --endpoint-url=https://s3.timeweb.cloud s3 ls s3://maratea-backups/postgres/
```

### Проверить последний backup Redis

```bash
# Посмотреть логи последнего job
kubectl logs -n maratea job/redis-backup-<timestamp>

# Проверить backup'ы в S3
aws --endpoint-url=https://s3.timeweb.cloud s3 ls s3://maratea-backups/redis/
```

## 🔄 Восстановление из Backup

### Восстановление PostgreSQL

```bash
# Скачать backup из S3
aws --endpoint-url=https://s3.timeweb.cloud s3 cp s3://maratea-backups/postgres/postgres-backup-YYYYMMDD-HHMMSS.sql.gz /tmp/backup.sql.gz

# Распаковать
gunzip /tmp/backup.sql.gz

# Восстановить в базу данных
kubectl exec -it -n maratea deployment/postgres -- psql -U maratea_user -d maratea_platform < /tmp/backup.sql
```

### Восстановление Redis

```bash
# Скачать backup из S3
aws --endpoint-url=https://s3.timeweb.cloud s3 cp s3://maratea-backups/redis/redis-backup-YYYYMMDD-HHMMSS.rdb.gz /tmp/backup.rdb.gz

# Распаковать
gunzip /tmp/backup.rdb.gz

# Скопировать в Redis pod
kubectl cp /tmp/backup.rdb maratea/redis-<pod-name>:/data/dump.rdb

# Перезапустить Redis для загрузки backup
kubectl rollout restart deployment/redis -n maratea
```

## ⚠️ Важные замечания

1. **S3 Credentials**: Храните секреты безопасно. Не коммитьте реальные credentials в репозиторий.
2. **Тестирование**: Перед использованием в production протестируйте восстановление из backup.
3. **Мониторинг**: Настройте алерты на неудачные backup'ы через Alertmanager.
4. **Резервное копирование**: Рекомендуется также хранить backup'ы в другом регионе или у другого провайдера.

## 📈 Метрики и Мониторинг

Backup jobs создают логи, которые можно мониторить через:
- Prometheus (метрики Kubernetes Jobs)
- Grafana (дашборды для CronJobs)
- Alertmanager (алерты на failed jobs)

## 🔐 Безопасность

- S3 bucket должен иметь правильные права доступа (только для backup сервиса)
- Используйте IAM роли, если возможно
- Регулярно ротируйте Access Keys
- Включите версионирование в S3 bucket

