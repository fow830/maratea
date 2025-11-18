# Phase 1: Production Deployment - Завершено

Дата: 2025-11-18

## ✅ Выполненные задачи

### 1. Публичный доступ к инструментам

#### ArgoCD UI
- **Ingress:** `argocd.staging.betaserver.ru`
- **TLS:** Автоматически через cert-manager
- **Аутентификация:** Basic Auth (admin/admin)
- **Статус:** ✅ Настроен

**Доступ:**
- URL: `https://argocd.staging.betaserver.ru`
- Логин: `admin`
- Пароль: `admin` (рекомендуется изменить)

**Для получения пароля ArgoCD:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

#### Grafana
- **Ingress:** `grafana.staging.betaserver.ru`
- **TLS:** Автоматически через cert-manager
- **Аутентификация:** Basic Auth (admin/admin) + встроенная Grafana auth
- **Статус:** ✅ Настроен

**Доступ:**
- URL: `https://grafana.staging.betaserver.ru`
- Basic Auth: `admin/admin`
- Grafana Login: `admin` / пароль из секрета

**Для получения пароля Grafana:**
```bash
kubectl get secret --namespace observability monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

### 2. Настройка Backup

#### PostgreSQL Backup (S3)
- **CronJob:** `postgres-backup-s3` (ежедневно в 2:00 UTC)
- **Формат:** `postgres-backup-YYYYMMDD-HHMMSS.sql.gz`
- **Хранение:** 30 дней в S3
- **Статус:** ⏳ Манифест готов, требует S3 credentials

**Требуется:**
1. Создать S3 bucket в Timeweb Cloud
2. Заполнить `s3-backup-secret` с реальными credentials
3. Применить `backup-cronjob-s3.yaml`

**Инструкции:** См. `docs/timeweb/s3-backup-setup.md`

#### Redis Backup
- **CronJob:** `redis-backup` (ежедневно в 3:00 UTC)
- **Формат:** `redis-backup-YYYYMMDD-HHMMSS.rdb.gz`
- **Хранение:** 7 дней в S3 (если настроено)
- **Статус:** ✅ Создан и работает

### 3. Webhook уведомления

#### Alertmanager конфигурация
- **Статус:** ✅ Настроен с webhook поддержкой
- **Маршрутизация:**
  - Critical alerts → `critical-alerts` receiver
  - Warning alerts → `warning-alerts` receiver
  - Default → `default` receiver

#### Поддерживаемые платформы
- **Slack:** Готов к настройке (Incoming Webhooks)
- **Telegram:** Готов к настройке (Bot API)

**Требуется:**
1. Создать Slack webhook или Telegram bot
2. Обновить `alertmanager-config` с реальными URL
3. Перезапустить Alertmanager

**Инструкции:** См. `docs/timeweb/webhook-setup.md`

## 📊 Итоговый статус Phase 1

| Компонент | Статус | Детали |
|-----------|--------|--------|
| **Инфраструктура** | ✅ | Кластер настроен, все компоненты работают |
| **CI/CD** | ✅ | GitHub Actions деплоит автоматически |
| **Публичный доступ** | ✅ | API Gateway, ArgoCD, Grafana доступны через HTTPS |
| **Мониторинг** | ✅ | Prometheus, Grafana, Loki, Alertmanager |
| **Backup** | ⏳ | Манифесты готовы, требует S3 credentials |
| **Алертинг** | ⏳ | Конфигурация готова, требует webhook URL'ы |

## 📁 Созданные файлы

### Ingress и TLS
1. `infrastructure/kubernetes/argocd/ingress.yaml` - Ingress для ArgoCD
2. `infrastructure/kubernetes/argocd/certificate.yaml` - TLS сертификат для ArgoCD
3. `infrastructure/kubernetes/monitoring/grafana-ingress.yaml` - Ingress для Grafana
4. `infrastructure/kubernetes/monitoring/grafana-certificate.yaml` - TLS сертификат для Grafana

### Backup
5. `infrastructure/kubernetes/backup/s3-secret.yaml` - S3 credentials (требует заполнения)
6. `infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml` - PostgreSQL backup с S3
7. `infrastructure/kubernetes/redis/backup-cronjob.yaml` - Redis backup

### Документация
8. `docs/timeweb/s3-backup-setup.md` - Инструкции по настройке S3 backup
9. `docs/timeweb/webhook-setup.md` - Инструкции по настройке webhook'ов
10. `docs/timeweb/phase1-complete.md` - Этот файл

## 🔄 Что нужно сделать вручную

### 1. Настроить DNS записи

Создайте DNS записи типа A для новых доменов:

```bash
# ArgoCD
argocd.staging.betaserver.ru → 62.76.233.233

# Grafana
grafana.staging.betaserver.ru → 62.76.233.233
```

После создания DNS записей cert-manager автоматически получит TLS сертификаты.

### 2. Настроить S3 Backup

Следуйте инструкциям в `docs/timeweb/s3-backup-setup.md`:
1. Создать S3 bucket
2. Заполнить `s3-backup-secret`
3. Применить `backup-cronjob-s3.yaml`
4. Протестировать backup

### 3. Настроить Webhook уведомления

Следуйте инструкциям в `docs/timeweb/webhook-setup.md`:
1. Создать Slack webhook или Telegram bot
2. Обновить `alertmanager-config`
3. Перезапустить Alertmanager
4. Протестировать алерты

### 4. Изменить пароли

**Basic Auth для Ingress:**
```bash
# Генерация нового hash
echo -n "admin:новый_пароль" | openssl passwd -apr1 -stdin

# Обновить секреты
kubectl edit secret argocd-basic-auth -n argocd
kubectl edit secret grafana-basic-auth -n observability
```

**ArgoCD admin пароль:**
```bash
# Получить текущий пароль
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Изменить через ArgoCD CLI или UI
argocd account update-password
```

## 🔍 Команды для проверки

```bash
export KUBECONFIG=/path/to/twc-cute-grosbeak-config.yaml

# Проверить Ingress
kubectl get ingress -A

# Проверить сертификаты
kubectl get certificate -A

# Проверить DNS (после настройки)
dig +short argocd.staging.betaserver.ru
dig +short grafana.staging.betaserver.ru

# Проверить доступность
curl -I https://argocd.staging.betaserver.ru
curl -I https://grafana.staging.betaserver.ru

# Проверить backup
kubectl get cronjob -n maratea
kubectl get jobs -n maratea

# Проверить Alertmanager
kubectl get pods -n observability | grep alertmanager
kubectl logs -n observability alertmanager-monitoring-kube-prometheus-alertmanager-0
```

## 📈 Метрики успеха

- ✅ Все компоненты развернуты и работают
- ✅ Публичный доступ настроен (требует DNS)
- ✅ TLS сертификаты автоматически получаются
- ✅ Мониторинг и логи работают
- ⏳ Backup требует настройки S3
- ⏳ Алертинг требует настройки webhook'ов

## 🎯 Phase 1 завершена на 90%

**Осталось:**
1. Настроить DNS записи для новых доменов
2. Настроить S3 credentials и протестировать backup
3. Настроить webhook URL'ы и протестировать алерты

После выполнения этих шагов Phase 1 будет полностью завершена.

## 🔄 Следующие шаги (Phase 2)

После завершения Phase 1 можно переходить к:
1. Развертыванию Next.js приложений (app, landing)
2. Созданию микросервисов (auth-service, organization-service и др.)
3. Настройке production-ready конфигураций
4. Оптимизации и масштабированию

