# Отчет о проверке S3 Backup

Дата: 2025-11-18

## ✅ Что работает

1. **S3 секрет создан:**
   - Endpoint: `s3.twcstorage.ru`
   - Access Key: настроен
   - Secret Key: настроен
   - Region: `ru-1`
   - Bucket: `af0d31be-cb217873-8a91-4500-9782-12793c7d715d`

2. **PostgreSQL backup CronJob применен:**
   - Расписание: каждый день в 2:00 UTC
   - Образ: `postgres:16-alpine`
   - awscli устанавливается успешно

3. **Backup создается:**
   - pg_dump выполняется успешно
   - Backup файлы создаются (размер ~4-7 МБ)
   - Сжатие gzip работает

## ⚠️ Проблемы

1. **Имя bucket в секрете:**
   - Текущее значение: `maratea-backups` (неправильное)
   - Правильное значение: `af0d31be-cb217873-8a91-4500-9782-12793c7d715d`
   - **Причина:** ArgoCD может синхронизировать секрет обратно из Git

2. **Ошибка загрузки в S3:**
   - Ошибка: `argument of type 'NoneType' is not iterable`
   - Возможная причина: неправильное имя bucket или проблемы с endpoint

## 🔧 Решение

### Вариант 1: Обновить секрет вручную (рекомендуется)

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Удалить и пересоздать секрет
kubectl delete secret s3-backup-secret -n maratea

kubectl create secret generic s3-backup-secret \
  --namespace maratea \
  --from-literal=S3_ENDPOINT="s3.twcstorage.ru" \
  --from-literal=S3_ACCESS_KEY="CNHJ6SLS6KZDWJYA7Z0R" \
  --from-literal=S3_SECRET_KEY="ju6TjDzEVJrDqOe26o8CxiAK1JF3yBsarzOWZS3t" \
  --from-literal=S3_BUCKET="af0d31be-cb217873-8a91-4500-9782-12793c7d715d" \
  --from-literal=S3_REGION="ru-1"
```

### Вариант 2: Обновить манифест секрета в Git

Обновить `infrastructure/kubernetes/backup/s3-secret.yaml` с правильными значениями и применить через ArgoCD.

## 📊 Текущий статус

- ✅ Backup создается успешно
- ⏳ Загрузка в S3 требует исправления bucket name
- ✅ CronJob настроен и работает

## 🚀 Следующие шаги

1. Исправить имя bucket в секрете
2. Запустить тестовый backup
3. Проверить загрузку в S3
4. Убедиться, что backup'ы доступны в S3 bucket

## 📝 Команды для проверки

```bash
# Проверить секрет
kubectl get secret s3-backup-secret -n maratea -o jsonpath='{.data.S3_BUCKET}' | base64 -d

# Запустить тестовый backup
kubectl create job --from=cronjob/postgres-backup-s3 postgres-backup-test-$(date +%s) -n maratea

# Проверить логи
kubectl logs -n maratea job/postgres-backup-test-<timestamp>

# Проверить статус job
kubectl get jobs -n maratea | grep postgres-backup
```

