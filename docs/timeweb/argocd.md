# ArgoCD Integration (Timeweb Cluster)

Дата: 2025-11-18

## 1. Цели

- Подключить кластер Cute Grosbeak к существующему ArgoCD.
- Синхронизировать приложение `maratea-staging` (см. `infrastructure/argocd/application.yaml`) с веткой `main`.

## 2. Подключение кластера

1. Сохраните kubeconfig (`copypast/twc-cute-grosbeak-config.yaml`) на машине с ArgoCD CLI.
2. Выполните:
   ```bash
   export KUBECONFIG=./twc-cute-grosbeak-config.yaml
   argocd cluster add wa370929-1060362 --name timeweb-cute-grosbeak
   ```
   (замените `wa370929-1060362` на контекст из kubeconfig).
3. Проверьте `argocd cluster list`.

## 3. Обновление Application

`infrastructure/argocd/application.yaml` уже указывает `targetRevision: main`. При добавлении нового кластера:

- либо разворачиваем ArgoCD **внутри** Timeweb кластера (destination server `https://kubernetes.default.svc` остаётся).
- либо, если ArgoCD остаётся внешним, обновляем `spec.destination.server` на `https://kubernetes.default.svc` только при установке в тот же кластер.

## 4. CI/CD поток

В GitHub Actions (`deploy.yml`):
- `build-and-scan` собирает/публикует образ в GHCR.
- `deploy-staging` применяет K8s манифесты (включая secrets и ingress). При необходимости, после apply можно вызвать `argocd app sync maratea-staging`.

## 5. Следующие шаги

1. Установить ArgoCD в кластере Timeweb (`kubectl apply -n argocd -f ...`).
2. Создать `image updater` или auto-sync для `maratea-staging`.
3. Настроить RBAC/SSO для ArgoCD (GitHub OAuth).

