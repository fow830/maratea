# Шаг 1: Публичный доступ (Ingress/LB/DNS) - Выполнено

Дата: 2025-11-18

## ✅ Выполненные задачи

### 1. Внешний IP балансировщика
- **Статус:** ✅ Получен автоматически
- **IP адрес:** `62.76.233.233`
- **Проверка:**
  ```bash
  kubectl get ingress -n maratea
  # ADDRESS: 62.76.233.233
  ```

### 2. Cert-Manager и TLS
- **Статус:** ✅ Установлен и настроен
- **Версия:** cert-manager v1.13.3
- **ClusterIssuer:** `letsencrypt-prod` (Let's Encrypt Production)
- **Certificate:** `api-gateway-tls` в namespace `maratea`
- **Метод:** HTTP-01 challenge (автоматический)
- **Проверка:**
  ```bash
  kubectl get pods -n cert-manager
  kubectl get clusterissuer letsencrypt-prod
  kubectl get certificate -n maratea
  ```

### 3. Ingress конфигурация
- **Статус:** ✅ Настроен
- **Файл:** `infrastructure/kubernetes/ingress.yaml`
- **Домен:** `api.staging.betaserver.ru`
- **TLS:** Автоматически через cert-manager
- **Аннотации:**
  - `cert-manager.io/cluster-issuer: letsencrypt-prod`
  - `nginx.ingress.kubernetes.io/proxy-body-size: 16m`
  - `nginx.ingress.kubernetes.io/proxy-read-timeout: 60`

### 4. Скрипт для DNS настройки
- **Статус:** ✅ Создан
- **Файл:** `scripts/setup-dns-betaserver.sh`
- **Использование:**
  ```bash
  ./scripts/setup-dns-betaserver.sh
  ```

## ⏳ Ожидает выполнения

### DNS запись
- **Требуется:** Создать DNS запись типа `A` для `api.staging.betaserver.ru`
- **Значение:** `62.76.233.233`
- **TTL:** 300 секунд (рекомендуется)
- **Где настроить:** В панели управления DNS для домена `betaserver.ru`

**После создания DNS записи:**
1. Cert-manager автоматически получит TLS сертификат от Let's Encrypt
2. Сертификат будет сохранен в секрет `api-gateway-tls`
3. Ingress начнет обслуживать HTTPS трафик

**Проверка DNS:**
```bash
dig +short api.staging.betaserver.ru
# Должен вернуть: 62.76.233.233
```

**Проверка сертификата (после DNS):**
```bash
kubectl get certificate -n maratea
# READY должен стать True

kubectl describe certificate api-gateway-tls -n maratea
# Проверить Events на наличие ошибок
```

**Проверка доступности (после DNS и получения сертификата):**
```bash
curl -I https://api.staging.betaserver.ru/health
curl https://api.staging.betaserver.ru/health
```

## 📁 Созданные файлы

1. `infrastructure/kubernetes/cert-manager/cluster-issuer.yaml` - ClusterIssuer для Let's Encrypt
2. `infrastructure/kubernetes/cert-manager/certificate.yaml` - Certificate ресурс
3. `scripts/setup-dns-betaserver.sh` - Скрипт с инструкциями по DNS
4. `docs/timeweb/ingress-dns.md` - Обновленная документация
5. `docs/timeweb/step1-summary.md` - Этот файл

## 🔄 Следующие шаги

После настройки DNS записи и получения TLS сертификата:
1. Проверить доступность API через HTTPS
2. Перейти к шагу 2: Проверка CI/CD
3. Перейти к шагу 3: Настройка ArgoCD

