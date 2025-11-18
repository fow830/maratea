# Настройка Telegram Webhook для Alertmanager

## Быстрый старт

Запустите интерактивный скрипт:

```bash
export KUBECONFIG=./copypast/twc-cute-grosbeak-config.yaml
./scripts/setup-telegram-webhook.sh
```

Скрипт проведет вас через все шаги автоматически.

---

## Ручная настройка

### Шаг 1: Создание Telegram Bot

1. Откройте Telegram и найдите [@BotFather](https://t.me/botfather)
2. Отправьте команду `/newbot`
3. Следуйте инструкциям:
   - **Имя бота:** `Maratea Alerts Bot` (или любое другое)
   - **Username бота:** `maratea_alerts_bot` (должен заканчиваться на `bot`)
4. Сохраните **Bot Token** (формат: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### Шаг 2: Получение Chat ID

#### Вариант A: Личный чат

1. Найдите вашего бота в Telegram
2. Отправьте любое сообщение (например: `/start`)
3. Откройте в браузере:
   ```
   https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
   ```
4. Найдите в ответе `"chat":{"id": <CHAT_ID>}` - это положительное число

#### Вариант B: Группа

1. Создайте группу в Telegram
2. Добавьте вашего бота в группу
3. Отправьте любое сообщение в группу
4. Откройте в браузере:
   ```
   https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
   ```
5. Найдите в ответе `"chat":{"id": <CHAT_ID>}` - это отрицательное число

### Шаг 3: Обновление конфигурации Alertmanager

```bash
export KUBECONFIG=./copypast/twc-cute-grosbeak-config.yaml
kubectl edit secret alertmanager-config -n observability
```

Раскомментируйте и обновите секцию для Telegram в `critical-alerts`:

```yaml
receivers:
  - name: 'critical-alerts'
    webhook_configs:
      - url: 'https://api.telegram.org/bot<BOT_TOKEN>/sendMessage'
        send_resolved: true
        http_config:
          method: POST
        body: |
          {
            "chat_id": "<CHAT_ID>",
            "text": "🚨 *Critical Alert: {{ .GroupLabels.alertname }}*\n\n{{ range .Alerts }}*Alert:* {{ .Annotations.summary }}\n*Severity:* {{ .Labels.severity }}\n*Instance:* {{ .Labels.instance }}\n*Namespace:* {{ .Labels.namespace }}\n*Details:* {{ .Annotations.description }}\n{{ end }}",
            "parse_mode": "Markdown"
          }
```

Замените:
- `<BOT_TOKEN>` на ваш Bot Token
- `<CHAT_ID>` на ваш Chat ID

### Шаг 4: Перезапуск Alertmanager

```bash
kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability
kubectl rollout status statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability
```

---

## Тестирование

### Вариант 1: Через kubectl

```bash
kubectl run alert-test --rm -i --restart=Never \
  --image=curlimages/curl -n observability -- \
  curl -X POST http://alertmanager-monitoring-kube-prometheus-alertmanager:9093/api/v1/alerts \
  -H 'Content-Type: application/json' \
  -d '[{"labels":{"alertname":"TestAlert","severity":"critical"},"annotations":{"summary":"Test Alert","description":"This is a test alert from Kubernetes"}}]'
```

### Вариант 2: Через port-forward

```bash
# В первом терминале
kubectl port-forward -n observability svc/alertmanager-monitoring-kube-prometheus-alertmanager 9093:9093

# Во втором терминале
curl -X POST http://localhost:9093/api/v1/alerts \
  -H 'Content-Type: application/json' \
  -d '[{"labels":{"alertname":"TestAlert","severity":"critical"},"annotations":{"summary":"Test Alert","description":"This is a test alert"}}]'
```

После отправки тестового alert вы должны получить сообщение в Telegram.

---

## Формат уведомлений

Уведомления будут приходить в следующем формате:

```
🚨 Critical Alert: TestAlert

Alert: Test Alert
Severity: critical
Instance: test-instance
Namespace: observability
Details: This is a test alert from Kubernetes
```

---

## Устранение неполадок

### Проблема: Не приходят уведомления

1. Проверьте Bot Token:
   ```bash
   curl "https://api.telegram.org/bot<BOT_TOKEN>/getMe"
   ```
   Должен вернуть `"ok":true`

2. Проверьте Chat ID:
   ```bash
   curl -X POST "https://api.telegram.org/bot<BOT_TOKEN>/sendMessage" \
     -d "chat_id=<CHAT_ID>" \
     -d "text=Test message"
   ```

3. Проверьте логи Alertmanager:
   ```bash
   kubectl logs -n observability statefulset/alertmanager-monitoring-kube-prometheus-alertmanager
   ```

4. Проверьте конфигурацию:
   ```bash
   kubectl get secret alertmanager-config -n observability -o jsonpath='{.data.alertmanager\.yml}' | base64 -d
   ```

### Проблема: "Bad Request" от Telegram API

- Убедитесь, что Bot Token правильный
- Убедитесь, что Chat ID правильный (может быть отрицательным для групп)
- Проверьте, что бот добавлен в группу (если используете группу)

### Проблема: Alertmanager не перезапускается

```bash
# Проверьте статус
kubectl get pods -n observability | grep alertmanager

# Удалите pod для принудительного перезапуска
kubectl delete pod -n observability -l app.kubernetes.io/name=alertmanager
```

---

## Дополнительные настройки

### Добавление webhook для warning alerts

Аналогично настройте `warning-alerts` receiver:

```yaml
- name: 'warning-alerts'
  webhook_configs:
    - url: 'https://api.telegram.org/bot<BOT_TOKEN>/sendMessage'
      send_resolved: true
      http_config:
        method: POST
      body: |
        {
          "chat_id": "<CHAT_ID>",
          "text": "⚠️ *Warning Alert: {{ .GroupLabels.alertname }}*\n\n{{ range .Alerts }}{{ .Annotations.description }}{{ end }}",
          "parse_mode": "Markdown"
        }
```

---

## Безопасность

⚠️ **Важно:** Bot Token и Chat ID хранятся в Kubernetes Secret. Убедитесь, что:
- Secret не коммитится в Git
- Доступ к кластеру ограничен
- Используется RBAC для ограничения доступа к Secret

---

## Ссылки

- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Alertmanager Webhook Configuration](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config)
- [Документация проекта](../README.md)

