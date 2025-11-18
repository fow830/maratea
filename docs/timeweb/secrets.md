# Timeweb Cloud Secrets & Configuration

> Последнее обновление: 2025-11-18 — обнови при изменениях.

## 1. Обязательные токены и ключи

| Переменная/секрет | Назначение | Где хранить | Примечание |
| --- | --- | --- | --- |
| `TIMEWEB_API_TOKEN` | API-доступ к Timeweb Cloud (Terraform, CLI, API Gateway) | GitHub Actions secret `TIMEWEB_API_TOKEN`; Kubernetes `Secret` `timeweb-api-token` | Создаётся в личном кабинете Timeweb → API и Terraform. Без IP-ограничений. |
| `KUBECONFIG` | Подключение CI/ArgoCD к кластеру | GitHub Actions secret `KUBECONFIG` (base64) | Файл скачиваем из Timeweb, кодируем `base64 -i twc-cute-grosbeak-config.yaml`. |
| `GHCR_TOKEN` | Авторизация при pull образов из GHCR | GitHub Actions secret `GHCR_TOKEN`; Kubernetes `Secret` `ghcr-secret` | Personal Access Token с правами `read:packages`. |
| `TURBO_TOKEN` | Turborepo remote cache | GitHub Actions secret `TURBO_TOKEN` | Уже используется в Phase 0. |

## 2. Приложение (API Gateway)

| Переменная | Описание | Где задаётся |
| --- | --- | --- |
| `NODE_ENV` | `production` | K8s `ConfigMap`/`Secret` |
| `API_URL`, `LANDING_URL` | Base URLs для Next.js | GitHub Actions env → `.env` → `ConfigMap` |
| `REDIS_URL`, `POSTGRES_URL` | Подключение к БД/кэшу | Kubernetes `Secret` (например, `app-secrets`) |
| `TIMEWEB_API_BASE_URL` | Базовый URL API Timeweb (опционально) | Значение по умолчанию `https://api.timeweb.cloud/api/v1` |

## 3. Текущее состояние (2025-11-18)

- GitHub Actions secrets: `TIMEWEB_API_TOKEN`, `KUBECONFIG`, `GHCR_TOKEN`, `POSTGRES_URL`, `REDIS_URL`, `TURBO_TOKEN`, `TURBO_TEAM`.
- Kubernetes namespace `maratea`: `ghcr-secret`, `timeweb-api-token`, `app-secrets`, `postgres-secret` актуальны.

## 4. Хранение секретов

- **GitHub Actions**: `Settings → Secrets → Actions`
  - `TIMEWEB_API_TOKEN`, `KUBECONFIG`, `GHCR_TOKEN`, `TURBO_TOKEN`, `POSTGRES_URL`, `REDIS_URL`, другие сервисные ключи.
- **Kubernetes (namespace `maratea`)**
  - `ghcr-secret` — `kubectl create secret docker-registry`.
  - `timeweb-api-token` — `kubectl create secret generic timeweb-api-token --from-literal=TIMEWEB_API_TOKEN=...`.
  - `app-secrets` — для `POSTGRES_URL`, `REDIS_URL`, внешних API ключей.

## 5. Процесс обновления

1. Получить новые значения (например, смена kubeconfig после пересоздания кластера).
2. Обновить секреты в GitHub (если используются в CI).
3. Применить/пересоздать Kubernetes `Secret` в кластере (`kubectl apply -f ...` или `kubectl delete secret ... && kubectl create secret ...`).
4. Зафиксировать изменения в документации (этот файл).

## 6. Контроль

- Перед запуском пайплайнов убедиться, что все secrets присутствуют (`gh secret list`).
- Регулярно проверять срок действия токенов Timeweb и PAT GitHub.


