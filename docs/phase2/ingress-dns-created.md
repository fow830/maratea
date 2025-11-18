# Phase 2, Этап 3: Ingress и DNS созданы

Дата: 2025-11-19

## ✅ Что создано

### 1. Ingress для `app`

**Файл:** `infrastructure/kubernetes/app/ingress.yaml`

**Характеристики:**
- **Host:** `app.staging.betaserver.ru`
- **Backend:** Service `app` (порт 80)
- **TLS:** Автоматический через cert-manager
- **Annotations:**
  - `proxy-body-size: 16m`
  - `proxy-read-timeout: 60`
  - `proxy-send-timeout: 60`

---

### 2. Ingress для `landing`

**Файл:** `infrastructure/kubernetes/landing/ingress.yaml`

**Характеристики:**
- **Host:** `staging.betaserver.ru`
- **Backend:** Service `landing` (порт 80)
- **TLS:** Автоматический через cert-manager
- **Annotations:**
  - `proxy-body-size: 16m`
  - `proxy-read-timeout: 60`
  - `proxy-send-timeout: 60`

---

### 3. Certificate для `app`

**Файл:** `infrastructure/kubernetes/app/certificate.yaml`

**Характеристики:**
- **DNS Name:** `app.staging.betaserver.ru`
- **Issuer:** `letsencrypt-prod` (ClusterIssuer)
- **Secret:** `app-tls`

---

### 4. Certificate для `landing`

**Файл:** `infrastructure/kubernetes/landing/certificate.yaml`

**Характеристики:**
- **DNS Name:** `staging.betaserver.ru`
- **Issuer:** `letsencrypt-prod` (ClusterIssuer)
- **Secret:** `landing-tls`

---

## 📋 DNS записи для настройки

### Требуемые записи

1. **app.staging.betaserver.ru** → `62.76.233.233`
   - Тип: A
   - TTL: 300

2. **staging.betaserver.ru** → `62.76.233.233`
   - Тип: A
   - TTL: 300

### Инструкция

1. Откройте панель управления DNS для `betaserver.ru`
2. Создайте A записи:
   - `app.staging` → `62.76.233.233`
   - `staging` → `62.76.233.233`
3. Сохраните изменения
4. Подождите распространения DNS (5-15 минут)

---

## 🔒 TLS сертификаты

После настройки DNS:

1. cert-manager автоматически создаст HTTP-01 challenge
2. Получит TLS сертификат от Let's Encrypt
3. Сохранит в Kubernetes Secret

**Проверка:**

```bash
# Проверка Certificate статуса
kubectl get certificates -n maratea

# Проверка Secret'ов
kubectl get secrets -n maratea | grep tls

# Детали Certificate
kubectl describe certificate app-tls -n maratea
kubectl describe certificate landing-tls -n maratea
```

---

## 🌐 Проверка доступности

После настройки DNS и получения сертификатов:

```bash
# App
curl -I https://app.staging.betaserver.ru

# Landing
curl -I https://staging.betaserver.ru
```

---

## 📝 Следующие шаги

### Этап 4: CI/CD workflows
- Добавить build jobs для приложений
- Настроить автоматический деплой
- Обновить GitHub Actions workflow

---

## ⚠️ Примечания

1. **DNS настройка:**
   - Требуется ручная настройка DNS записей
   - Время распространения: 5-15 минут

2. **TLS сертификаты:**
   - Получаются автоматически после DNS
   - Время получения: 1-2 минуты после DNS

3. **Ingress:**
   - Использует существующий ingress-nginx
   - LoadBalancer IP: `62.76.233.233`

4. **Домены:**
   - `app.staging.betaserver.ru` - основное приложение
   - `staging.betaserver.ru` - лендинг

