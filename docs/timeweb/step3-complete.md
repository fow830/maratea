# Шаг 3: Установка ArgoCD, Мониторинга и Backup - Выполнено

Дата: 2025-11-18

## ✅ Выполненные задачи

### 1. ArgoCD (GitOps)

**Статус:** ✅ Установлен и настроен

**Детали:**
- Namespace: `argocd`
- Версия: последняя стабильная (из официального манифеста)
- Application: `maratea-staging` создан и синхронизируется с `main` веткой
- Все pods в статусе `Running`

**Проверка:**
```bash
kubectl get pods -n argocd
kubectl get application -n argocd
```

**Доступ к ArgoCD UI:**
```bash
# Получить пароль admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward для доступа
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Открыть https://localhost:8080
```

**Application манифест:**
- Файл: `infrastructure/argocd/application.yaml`
- Репозиторий: `https://github.com/fow830/maratea.git`
- Ветка: `main`
- Путь: `infrastructure/kubernetes`
- Auto-sync: включен (prune, selfHeal)

### 2. Мониторинг (Prometheus/Grafana)

**Статус:** ✅ Установлен через Helm

**Детали:**
- Namespace: `observability`
- Chart: `kube-prometheus-stack` (версия 79.5.0)
- Компоненты:
  - Prometheus (retention: 7 дней, storage: 20Gi, local-path)
  - Grafana (admin password: `admin`)
  - Alertmanager
  - Node Exporter
  - Kube State Metrics

**Проверка:**
```bash
kubectl get pods -n observability
helm list -n observability
```

**Доступ к Grafana:**
```bash
# Получить пароль admin
kubectl get secret --namespace observability monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d

# Port-forward
kubectl port-forward -n observability svc/monitoring-grafana 3000:80
# Открыть http://localhost:3000 (admin / <password>)
```

**Метрики:**
- Prometheus собирает метрики из всех pods
- Grafana имеет предустановленные дашборды для Kubernetes
- Alertmanager настроен для отправки уведомлений

### 3. Backup (PostgreSQL)

**Статус:** ✅ Настроен через CronJob

**Детали:**
- CronJob: `postgres-backup` в namespace `maratea`
- Расписание: каждый день в 2:00 UTC (`0 2 * * *`)
- PVC: `postgres-backup-pvc` (10Gi, local-path)
- Формат: `postgres-backup-YYYYMMDD-HHMMSS.sql.gz`
- Хранение: 7 дней (автоматическая очистка старых backup'ов)

**Проверка:**
```bash
kubectl get cronjob -n maratea
kubectl get pvc -n maratea | grep backup

# Проверить последний backup
kubectl get jobs -n maratea -l job-name=postgres-backup
kubectl logs -n maratea job/postgres-backup-<timestamp>
```

**Ручной запуск backup:**
```bash
kubectl create job --from=cronjob/postgres-backup postgres-backup-manual-$(date +%s) -n maratea
```

**Структура backup:**
- Использует `pg_dump` из образа `postgres:16-alpine`
- Подключается к сервису `postgres:5432`
- Использует credentials из секрета `postgres-secret`
- Сжимает backup через `gzip`
- Сохраняет в `/backups` на PVC

## 📊 Текущий статус кластера

| Компонент | Namespace | Статус | Детали |
|-----------|-----------|--------|--------|
| ArgoCD | `argocd` | ✅ | 7 pods, Application создан |
| Prometheus | `observability` | ✅ | 2/2 pods, retention 7d |
| Grafana | `observability` | ✅ | 3/3 pods, доступен на порту 80 |
| Alertmanager | `observability` | ✅ | 2/2 pods |
| PostgreSQL Backup | `maratea` | ✅ | CronJob настроен, PVC создан |

## 🔄 Следующие шаги (опционально)

### ArgoCD
1. Настроить Ingress для доступа к ArgoCD UI
2. Настроить RBAC/SSO (GitHub OAuth)
3. Добавить Image Updater для автоматического обновления образов

### Мониторинг
1. Настроить Ingress для Grafana
2. Добавить кастомные дашборды для API Gateway
3. Настроить алерты в Alertmanager (Slack/Telegram webhooks)
4. Установить Loki для централизованных логов

### Backup
1. Настроить Velero для backup всего кластера
2. Настроить отправку backup'ов в S3 (Timeweb Object Storage)
3. Добавить backup для Redis
4. Настроить автоматическое восстановление из backup

## 📁 Созданные файлы

1. `infrastructure/kubernetes/postgres/backup-cronjob.yaml` - CronJob для backup PostgreSQL
2. `docs/timeweb/step3-complete.md` - Этот файл

## 🔍 Команды для проверки

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# ArgoCD
kubectl get pods -n argocd
kubectl get application -n argocd
kubectl get application maratea-staging -n argocd -o yaml

# Мониторинг
kubectl get pods -n observability
kubectl get svc -n observability
helm list -n observability

# Backup
kubectl get cronjob -n maratea
kubectl get pvc -n maratea | grep backup
kubectl get jobs -n maratea -l job-name=postgres-backup
```

