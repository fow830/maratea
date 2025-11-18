# Timeweb Cloud Cluster Status (Cute Grosbeak)

Дата: 2025-11-18

## 1. Общая информация

- Кластер: **Cute Grosbeak**
- Kubernetes: `v1.34.1+k0s.0`
- Регион: Санкт-Петербург (РУ)
- Worker pool: 1 нода `worker-192.168.0.6`
- kubeconfig: `copypast/twc-cute-grosbeak-config.yaml` (загружен в GH secret `KUBECONFIG`)

## 2. Namespaces

| Namespace | Назначение |
| --- | --- |
| `default` | системный |
| `ingress-nginx` | развёрнут провайдером |
| `k0s-*` | служебные |
| `maratea` | наше приложение (создан 18.11) |

## 3. Развёрнутые ресурсы в `maratea`

| Компонент | Статус | Примечания |
| --- | --- | --- |
| Namespace | ✅ | `infrastructure/kubernetes/namespace.yaml` |
| Secrets | ✅ | `postgres-secret`, `ghcr-secret`, `timeweb-api-token`, `app-secrets` |
| PostgreSQL | ✅ | Deployment + PVC (`local-path`, 10Gi), Service `postgres` |
| Redis | ✅ | Deployment + PVC (`local-path`, 5Gi), Service `redis` |
| API Gateway | ✅ | Deployment (2 реплики) + Service `api-gateway` |
| Network Policies | ✅ | `api-gateway`, `postgres`, `redis` |

## 4. Сервисы

```
kubectl get svc -n maratea
NAME          TYPE        CLUSTER-IP       PORT(S)
api-gateway   ClusterIP   10.111.214.146   8080/TCP
postgres      ClusterIP   10.110.93.53     5432/TCP
redis         ClusterIP   10.98.240.179    6379/TCP
```

Ingress / LoadBalancer пока не настроен.

## 5. PVC / Storage

- Установлен `local-path-provisioner`; storageClass `local-path` помечен default.
- PVC `postgres-pvc` (10Gi) и `redis-pvc` (5Gi) в статусе `Bound`.

## 6. Открытые вопросы

1. Настройка внешнего доступа (Ingress/Load Balancer, DNS).
2. Обновление GitHub Actions / ArgoCD под новый кластер.
3. Мониторинг/backup для БД и PVC.

## 7. Полезные команды

```bash
export KUBECONFIG=./copypast/twc-cute-grosbeak-config.yaml
kubectl get pods -n maratea
kubectl logs deployment/api-gateway -n maratea
```


