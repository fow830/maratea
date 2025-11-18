# Monitoring & Backup Plan (Timeweb Cloud)

Дата: 2025-11-18

## 1. Observability

| Компонент | Статус | План |
| --- | --- | --- |
| Логи приложений | ❌ | Установить `loki-stack` или использовать Timeweb Logging; настроить `kubectl logs` → Elasticsearch. |
| Метрики | ❌ | Развернуть `kube-prometheus-stack` (Prometheus + Grafana + Alertmanager). |
| Трейсинг | ⚠️ | API Gateway уже использует OpenTelemetry – подключить OTLP-экспортер к Tempo/Jaeger. |

## 2. Backup

| Что | Подход | Инструмент |
| --- | --- | --- |
| PostgreSQL | Снимки/pg_dump | Использовать `pgBackRest` или `wal-g`, либо Managed DB Timeweb с автоматическими backup. |
| Redis | Не критичные данные | Включить AOF и периодические snapshot’ы; при возможности использовать managed Redis. |
| PVC (local-path) | Снимки на уровне нод | Внедрить `velero` + object storage (S3/Timeweb). |

## 3. Чек-лист внедрения

1. **Prometheus/Grafana**
   - `helm repo add prometheus-community ...`
   - `helm install monitoring prometheus-community/kube-prometheus-stack -n observability`
   - Создать ingress/доступ к Grafana (basic auth).

2. **Loki (логи)**
   - `helm repo add grafana https://grafana.github.io/helm-charts`
   - `helm install loki grafana/loki-stack -n observability`
   - Настроить retention 7–14 дней, интегрировать с Grafana.

3. **Alerting**
   - В Alertmanager добавить webhook (Slack/Telegram).

4. **Backups**
   - PostgreSQL: cronjob `pg_dump` → S3 (Timeweb Object Storage) + хранение 7/30 дней.
   - Redis: ежедневные snapshot’ы, хранение 3 дня.
   - Velero: `velero install --provider aws --plugins velero/velero-plugin-for-aws ...` с учётом S3 credentials.

5. **Документация**
   - Записать расписание и места хранения backup в `/docs/timeweb/backup-schedule.md` (создать после реализации).

## 4. SLA / SLO (рекомендуется)

- API Gateway uptime ≥ 99.5%
- RPO (PostgreSQL) ≤ 1 час
- RTO ≤ 30 минут

## 5. Следующие шаги

1. Выбрать объектное хранилище (Timeweb S3) и создать credentials.
2. Автоматизировать установку Helm-чартов через ArgoCD/HelmRelease.
3. Добавить дашборды и алерты в Grafana.

