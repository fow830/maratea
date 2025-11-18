#!/bin/bash

# Быстрая настройка Telegram webhook (требует Chat ID)
# Использование: ./scripts/setup-telegram-webhook-quick.sh <CHAT_ID>

set -e

BOT_TOKEN="8594621300:AAHo7Da-tbzz4DI4XPSeXzMDOaSvQRb-5ys"
CHAT_ID="${1}"

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

if [ -z "$CHAT_ID" ]; then
    echo "❌ Ошибка: Chat ID обязателен"
    echo ""
    echo "Использование: $0 <CHAT_ID>"
    echo ""
    echo "Для получения Chat ID:"
    echo "  1. Откройте Telegram и найдите @marateahookbot"
    echo "  2. Отправьте любое сообщение боту (например: /start)"
    echo "  3. Выполните:"
    echo "     curl -s 'https://api.telegram.org/bot${BOT_TOKEN}/getUpdates' | grep -o '\"chat\":{\"id\":[0-9-]*' | head -1 | grep -o '[0-9-]*\$'"
    echo ""
    exit 1
fi

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "❌ Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

echo "=========================================="
echo "Настройка Telegram webhook"
echo "=========================================="
echo ""
echo "Bot: @marateahookbot"
echo "Chat ID: $CHAT_ID"
echo ""

# Проверка bot token
CHECK_RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe" 2>/dev/null || echo "")
if ! echo "$CHECK_RESPONSE" | grep -q '"ok":true'; then
    echo "❌ Ошибка: Bot Token невалиден"
    exit 1
fi

# Отправка тестового сообщения
TEST_MESSAGE="✅ Тестовое сообщение от Alertmanager

Если вы видите это сообщение, webhook настроен правильно!"
SEND_RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${TEST_MESSAGE}" \
    -d "parse_mode=Markdown" 2>/dev/null || echo "")

if echo "$SEND_RESPONSE" | grep -q '"ok":true'; then
    echo "✅ Тестовое сообщение отправлено в Telegram!"
else
    ERROR_MSG=$(echo "$SEND_RESPONSE" | grep -o '"description":"[^"]*"' | cut -d'"' -f4 || echo "Unknown error")
    echo "❌ Ошибка отправки тестового сообщения: $ERROR_MSG"
    exit 1
fi

echo ""
echo "Обновление Alertmanager конфигурации..."

# Получение текущей конфигурации
CURRENT_CONFIG=$(kubectl get secret alertmanager-config -n observability -o jsonpath='{.data.alertmanager\.yml}' | base64 -d)

# Создание обновленной конфигурации
TEMP_CONFIG=$(mktemp)

# Удаляем закомментированный Telegram блок и добавляем активный webhook
echo "$CURRENT_CONFIG" | \
    sed "/# Telegram webhook/,/#     }/d" | \
    sed "/name: 'critical-alerts'/,/name: 'warning-alerts'/{
        /webhook_configs:/a\\
          - url: 'https://api.telegram.org/bot${BOT_TOKEN}/sendMessage'\\
            send_resolved: true\\
            http_config:\\
              method: POST\\
            body: |\\
              {\\
                \"chat_id\": \"${CHAT_ID}\",\\
                \"text\": \"🚨 *Critical Alert: {{ .GroupLabels.alertname }}*\\\\n\\\\n{{ range .Alerts }}*Alert:* {{ .Annotations.summary }}\\\\n*Severity:* {{ .Labels.severity }}\\\\n*Instance:* {{ .Labels.instance }}\\\\n*Namespace:* {{ .Labels.namespace }}\\\\n*Details:* {{ .Annotations.description }}\\\\n{{ end }}\",\\
                \"parse_mode\": \"Markdown\"\\
              }
    }" > "$TEMP_CONFIG"

# Обновление секрета
kubectl create secret generic alertmanager-config \
    --namespace observability \
    --from-file=alertmanager.yml="$TEMP_CONFIG" \
    --dry-run=client -o yaml | kubectl apply -f -

rm -f "$TEMP_CONFIG"

echo "✅ Alertmanager конфигурация обновлена"

# Перезапуск Alertmanager
echo ""
echo "Перезапуск Alertmanager..."
kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability

echo ""
echo "Ожидание готовности Alertmanager..."
kubectl rollout status statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability --timeout=120s 2>/dev/null || true

echo ""
echo "=========================================="
echo "✅ Настройка завершена!"
echo "=========================================="
echo ""
echo "Telegram webhook настроен для @marateahookbot"
echo ""

