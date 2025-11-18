# Исправление Timeweb Routes - Опциональная регистрация

Дата: 2025-11-18

## 🔧 Проблема

Новый pod API Gateway падал с ошибкой:
```
TIMEWEB_API_TOKEN is not set
```

Причина: Timeweb routes регистрировались всегда, даже если токен не был установлен.

---

## ✅ Решение

### 1. Сделать Timeweb routes опциональными

**Файл:** `services/api-gateway/src/routes/timeweb.ts`

```typescript
export const timewebRoutes: FastifyPluginAsync = async (fastify) => {
  // Timeweb routes are optional - only register if token is available
  if (!process.env.TIMEWEB_API_TOKEN) {
    return; // Skip registration if token is not set
  }

  const client = new TimewebClient();
  // ... rest of the code
};
```

### 2. Добавить TIMEWEB_API_TOKEN в deployment (optional)

**Файл:** `infrastructure/kubernetes/api-gateway/deployment.yaml`

```yaml
env:
  - name: TIMEWEB_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: timeweb-api-token
        key: TIMEWEB_API_TOKEN
        optional: true
```

---

## 📊 Результат

- ✅ API Gateway может запускаться без TIMEWEB_API_TOKEN
- ✅ Timeweb routes регистрируются только если токен доступен
- ✅ Deployment не падает при отсутствии токена
- ✅ Метрики Prometheus работают независимо от Timeweb

---

## 🔍 Проверка

После деплоя нового образа:

```bash
# Проверить, что pod запущен
kubectl get pods -n maratea -l app=api-gateway

# Проверить метрики
curl http://api-gateway:8080/metrics

# Проверить логи (не должно быть ошибок о TIMEWEB_API_TOKEN)
kubectl logs -n maratea -l app=api-gateway --tail=50
```

---

## 📝 Следующие шаги

1. ✅ Исправление применено
2. ⏳ Ожидание деплоя нового образа
3. ⏳ Проверка метрик после деплоя

