# Исправление подключения к PostgreSQL для Backup

Дата: 2025-11-18

## ✅ Проблема решена

### Проблема
Backup job не мог подключиться к PostgreSQL:
```
pg_dump: error: connection to server at "postgres" (10.110.93.53), port 5432 failed: Operation timed out
```

### Причина
Network Policy для PostgreSQL разрешала подключения только от pod'ов с label `app: api-gateway`. Backup job'ы не имели этого label, поэтому не могли подключиться.

### Решение

1. **Обновлена Network Policy** (`infrastructure/kubernetes/network-policy.yaml`):
   - Добавлено правило для разрешения подключений от pod'ов с label `app: postgres-backup`
   - Теперь backup job'ы могут подключаться к PostgreSQL

2. **Обновлен CronJob** (`infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml`):
   - Добавлен label `app: postgres-backup` к pod template
   - Это позволяет Network Policy идентифицировать backup pod'ы

## ✅ Результат

### Подключение работает
```
PostgreSQL 15.15 on x86_64-pc-linux-musl
База данных: maratea_platform (7477 kB)
```

### Backup успешно выполнен
```
Backup completed: postgres-backup-20251118-205152.sql.gz
Backup size: 4.0K
Uploading backup to S3...
upload: tmp/postgres-backup-20251118-205152.sql.gz to s3://af0d31be-cb217873-8a91-4500-9782-12793c7d715d/postgres/postgres-backup-20251118-205152.sql.gz
Backup uploaded to S3 successfully ✅
Backup process completed at Tue Nov 18 20:51:54 UTC 2025
```

**Job статус:** ✅ `Complete 1/1`

## 📊 Изменения

### Network Policy
```yaml
ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 5432
  - from:
    - namespaceSelector:
        matchLabels:
          name: maratea
    - podSelector:
        matchLabels:
          app: postgres-backup
    ports:
    - protocol: TCP
      port: 5432
```

### CronJob
```yaml
template:
  metadata:
    labels:
      app: postgres-backup
  spec:
    containers:
    ...
```

## ✅ Итоговый статус

| Компонент | Статус |
|-----------|--------|
| Network Policy | ✅ Обновлена |
| Backup CronJob | ✅ Обновлен |
| Подключение к PostgreSQL | ✅ Работает |
| Backup создание | ✅ Работает |
| Загрузка в S3 | ✅ Работает |
| CronJob | ✅ Настроен |

## 🎉 Результат

**PostgreSQL backup полностью настроен и работает!**

- ✅ Подключение к PostgreSQL работает
- ✅ Backup создается успешно
- ✅ Backup загружается в S3
- ✅ CronJob настроен на автоматическое выполнение каждый день в 2:00 UTC

## 📝 Команды для проверки

```bash
# Проверить подключение к PostgreSQL
kubectl run postgres-test-$(date +%s) --rm -i --restart=Never \
  --image=postgres:16-alpine -n maratea \
  --labels="app=postgres-backup" \
  --env="PGPASSWORD=..." \
  -- psql -h postgres -p 5432 -U maratea_user -d maratea_platform -c "SELECT 1;"

# Запустить тестовый backup
kubectl create job --from=cronjob/postgres-backup-s3 postgres-backup-test-$(date +%s) -n maratea

# Проверить логи
kubectl logs -n maratea job/postgres-backup-test-<timestamp>

# Проверить статус CronJob
kubectl get cronjob postgres-backup-s3 -n maratea
```

