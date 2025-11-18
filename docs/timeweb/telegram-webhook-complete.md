# Telegram Webhook - Настройка завершена ✅

Дата: 2025-11-18

## ✅ Настройка завершена

### Telegram Bot
- **Bot:** @marateahookbot
- **Bot Token:** `8594621300:AAHo7Da-tbzz4DI4XPSeXzMDOaSvQRb-5ys`
- **Chat ID:** `709114549`
- **Статус:** ✅ Настроен и протестирован

### Alertmanager
- **Конфигурация:** ✅ Обновлена
- **Webhook:** ✅ Настроен для critical alerts
- **Статус:** ✅ Перезапущен и работает

---

## 📋 Что настроено

### Critical Alerts → Telegram
Все критические алерты (`severity: critical`) теперь отправляются в Telegram через бота @marateahookbot.

Формат уведомления:
```
🚨 Critical Alert: <alertname>

Alert: <summary>
Severity: critical
Instance: <instance>
Namespace: <namespace>
Details: <description>
```

---

## 🧪 Тестирование

### Отправка тестового alert

```bash
export KUBECONFIG=./copypast/twc-cute-grosbeak-config.yaml

# Вариант 1: Через port-forward
kubectl port-forward -n observability svc/alertmanager-monitoring-kube-prometheus-alertmanager 9093:9093

# В другом терминале
curl -X POST http://localhost:9093/api/v1/alerts \
  -H 'Content-Type: application/json' \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "severity": "critical",
      "namespace": "maratea"
    },
    "annotations": {
      "summary": "Test Alert",
      "description": "This is a test alert to verify Telegram webhook"
    }
  }]'
```

### Проверка конфигурации

```bash
kubectl get secret alertmanager-config -n observability -o jsonpath='{.data.alertmanager\.yml}' | base64 -d | grep -A 10 "api.telegram.org"
```

---

## 📊 Статус компонентов

| Компонент | Статус | Примечание |
|-----------|--------|------------|
| Telegram Bot | ✅ Работает | @marateahookbot |
| Alertmanager Config | ✅ Обновлена | Webhook настроен |
| Alertmanager Pod | ✅ Running | Готов к работе |
| Тестовое сообщение | ✅ Отправлено | Проверьте Telegram |

---

## 🔧 Управление

### Просмотр логов Alertmanager

```bash
kubectl logs -n observability alertmanager-monitoring-kube-prometheus-alertmanager-0
```

### Перезапуск Alertmanager

```bash
kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability
```

### Обновление Chat ID

Если нужно изменить Chat ID:

```bash
export KUBECONFIG=./copypast/twc-cute-grosbeak-config.yaml
./scripts/setup-telegram-webhook-quick.sh <NEW_CHAT_ID>
```

---

## 📝 Следующие шаги

1. ✅ Telegram webhook настроен
2. ⏳ Настроить webhook для warning alerts (опционально)
3. ⏳ Настроить дополнительные каналы уведомлений (Slack, Email)

---

## 🎉 Phase 1 завершена!

**Все задачи Phase 1 выполнены:**
- ✅ DNS настроен (argocd, grafana, api)
- ✅ S3 Backup настроен
- ✅ Telegram webhook настроен

**Phase 1: 100% завершена!** 🎊

