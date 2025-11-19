# Краткая история проекта

## Старт и аудит (февраль 2025)
- Репозиторий получен «как есть», приложений не собиралось, pnpm отсутствовал.
- Проведён полный аудит (Phase 0): описаны ошибки сборки, CI, инфраструктуры.

## Базовые исправления
- Установлен глобальный pnpm, настроены Turborepo токены и GitHub Secrets.
- Починен API Gateway (ESM-импорты, rate-limit без Redis, метрики prom-client).
- Созданы Dockerfile’ы для `api-gateway`, `app`, `landing`.

## Инфраструктура Timeweb Cloud
- Подготовлен kubeconfig, кластер подключён к ArgoCD.
- Развёрнуты Postgres, Redis, PVC, NetworkPolicy, Ingress + cert-manager.
- Настроен API Gateway ingress (`api.staging.betaserver.ru`) и TLS.

## CI/CD
- Workflow `deploy.yml` переписан: сборка/сканирование всех образов, синхронизация секретов и манифестов, health-check.
- Добавлен CodeQL + Trivy (по отдельности на каждый образ).

## Наблюдаемость и бэкапы
- Установлены Prometheus/Grafana/Alertmanager, Loki/Promtail, Telegram webhooks.
- Введены pg_dump CronJob + S3-загрузка, Redis backup, документация по процедурам.

## Публичный доступ и Phase 1
- Настроены DNS + TLS для `argocd.staging.betaserver.ru`, `grafana.staging.betaserver.ru`.
- Добавлены basic auth для UI, проверены уведомления и алерты.

## Phase 2 (frontend)
- Созданы Kubernetes манифесты и Ingress’ы для `app.staging.betaserver.ru` и `staging.betaserver.ru`.
- CI/CD пополнен сборкой Next.js приложений и деплоем в кластер.
- Исправлены Dockerfile’ы: прод-зависимости, копирование `.next`, pnpm без выхода наружу.
- Ингресс-трафик стабилизирован (правка liveness, сетевые политики, запуск nginx с правами на кэш).

## Текущий статус (ноябрь 2025)
- Все сервисы (`api-gateway`, `app`, `landing`) работают в k8s `maratea`, pods `Running`.
- HTTPS-домены выдают `200 OK`, pipeline `deploy.yml` зелёный.
- Документация по секретам, DNS, бэкапам, мониторингу и фазам находится в `docs/timeweb/*`.

