# Ingress, Load Balancer и DNS

Дата: 2025-11-18

## 1. Текущий статус

- ✅ В кластере установлен `ingress-nginx` (namespace `ingress-nginx`).
- ✅ Добавлен манифест `infrastructure/kubernetes/ingress.yaml`, который публикует `Service/api-gateway` на `api.staging.betaserver.ru`.
- ✅ **Внешний IP балансировщика получен: `62.76.233.233`**
- ✅ Установлен `cert-manager` v1.13.3 для автоматического получения TLS сертификатов.
- ✅ Создан `ClusterIssuer` `letsencrypt-prod` для Let's Encrypt.
- ✅ Создан `Certificate` ресурс `api-gateway-tls` для автоматического получения сертификата.
- ⏳ **DNS запись для `api.staging.betaserver.ru` → `62.76.233.233` еще не настроена** (см. шаг 2).
- ⏳ TLS сертификат будет автоматически получен после настройки DNS.

## 2. План действий

1. ✅ **Выделить внешний IP / Load Balancer** — **ВЫПОЛНЕНО**
   - Внешний IP балансировщика: `62.76.233.233`
   - IP автоматически назначен ingress-nginx LoadBalancer service.

2. ⏳ **Обновить DNS** — **ТРЕБУЕТСЯ ВЫПОЛНЕНИЕ**
   - Создать DNS запись типа `A` для `api.staging.betaserver.ru`:
     - **Имя:** `api.staging` (или полное `api.staging.betaserver.ru`)
     - **Тип:** A
     - **Значение:** `62.76.233.233`
     - **TTL:** 300 секунд (или меньше для быстрого обновления)
   - Использовать скрипт для проверки: `./scripts/setup-dns-betaserver.sh`
   - После создания DNS записи проверить:
     ```bash
     dig +short api.staging.betaserver.ru
     # Должен вернуть: 62.76.233.233
     ```

3. ✅ **TLS сертификат** — **НАСТРОЕНО (автоматически)**
   - Установлен `cert-manager` v1.13.3
   - Создан `ClusterIssuer` `letsencrypt-prod` для Let's Encrypt
   - Создан `Certificate` ресурс `api-gateway-tls`
   - Сертификат будет автоматически получен после настройки DNS (Let's Encrypt HTTP-01 challenge)
   - Проверить статус:
     ```bash
     kubectl get certificate -n maratea
     kubectl describe certificate api-gateway-tls -n maratea
     ```

4. ✅ **Проверка** — **ГОТОВО К ПРОВЕРКЕ ПОСЛЕ DNS**
   - Проверить статус ingress:
     ```bash
     kubectl get ingress -n maratea
     # Должен показать ADDRESS: 62.76.233.233
     ```
   - Проверить статус сертификата (после настройки DNS):
     ```bash
     kubectl get certificate -n maratea
     kubectl describe certificate api-gateway-tls -n maratea
     # READY должен стать True после успешного получения сертификата
     ```
   - Проверить доступность API (после настройки DNS и получения сертификата):
     ```bash
     curl -I https://api.staging.betaserver.ru/health
     curl https://api.staging.betaserver.ru/health
     ```

5. **Прод/боевые домены**
   - Дублировать ingress с `api.maratea.com` или добавить ещё один host в существующий ресурс.

## 3. Параметры, которые можно менять

- `spec.rules[0].host` и `spec.tls[0].hosts` в `infrastructure/kubernetes/ingress.yaml`.
- Аннотации nginx для лимитов/тайм-аутов.

## 4. Следующие шаги

- После подтверждения IP/DNS — обновить файл ingress (при необходимости) и применить `kubectl apply -f infrastructure/kubernetes/ingress.yaml`.
- Зафиксировать в документации финальные значения DNS и сертификатов.

