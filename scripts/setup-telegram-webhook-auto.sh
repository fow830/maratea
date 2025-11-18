#!/bin/bash

# Автоматическая настройка Telegram webhook для Alertmanager
# Использование: ./scripts/setup-telegram-webhook-auto.sh <BOT_TOKEN> <CHAT_ID>

set -e

BOT_TOKEN="${1:-8594621300:AAHo7Da-tbzz4DI4XPSeXzMDOaSvQRb-5ys}"
CHAT_ID="${2}"

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

echo "=========================================="
echo "Автоматическая настройка Telegram webhook"
echo "=========================================="
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "❌ Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Если Chat ID не предоставлен, пытаемся получить его
if [ -z "$CHAT_ID" ]; then
    echo "📋 Для получения Chat ID:"
    echo "   1. Откройте Telegram и найдите @marateahookbot"
    echo "   2. Отправьте любое сообщение боту (например: /start)"
    echo "   3. Подождите 5 секунд и нажмите Enter"
    echo ""
    read -p "Нажмите Enter после отправки сообщения боту..."
    
    # Получаем Chat ID из getUpdates
    echo ""
    echo "Получение Chat ID..."
    UPDATES=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates")
    CHAT_ID=$(echo "$UPDATES" | grep -o '"chat":{"id":[0-9-]*' | head -1 | grep -o '[0-9-]*$' || echo "")
    
    if [ -z "$CHAT_ID" ]; then
        echo "❌ Не удалось получить Chat ID автоматически"
        echo ""
        echo "Попробуйте вручную:"
        echo "   1. Откройте: https://api.telegram.org/bot${BOT_TOKEN}/getUpdates"
        echo "   2. Найдите 'chat':{'id': <CHAT_ID>} в ответе"
        echo "   3. Запустите скрипт снова:"
        echo "      ./scripts/setup-telegram-webhook-auto.sh ${BOT_TOKEN} <CHAT_ID>"
        exit 1
    fi
    
    echo "✅ Chat ID получен: $CHAT_ID"
fi

echo ""
echo "Проверка подключения к Telegram API..."

# Проверка bot token
CHECK_RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe" 2>/dev/null || echo "")
if echo "$CHECK_RESPONSE" | grep -q '"ok":true'; then
    BOT_USERNAME=$(echo "$CHECK_RESPONSE" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Bot Token валиден"
    echo "   Bot username: @${BOT_USERNAME}"
else
    echo "❌ Ошибка: Bot Token невалиден"
    exit 1
fi

# Проверка chat ID и отправка тестового сообщения
TEST_MESSAGE="✅ Тестовое сообщение от Alertmanager

Если вы видите это сообщение, webhook настроен правильно!"
SEND_RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${TEST_MESSAGE}" \
    -d "parse_mode=Markdown" 2>/dev/null || echo "")

if echo "$SEND_RESPONSE" | grep -q '"ok":true'; then
    echo "✅ Тестовое сообщение отправлено в Telegram!"
    echo "   Проверьте ваш Telegram, вы должны получить тестовое сообщение"
else
    ERROR_MSG=$(echo "$SEND_RESPONSE" | grep -o '"description":"[^"]*"' | cut -d'"' -f4 || echo "Unknown error")
    echo "⚠️  Не удалось отправить тестовое сообщение: $ERROR_MSG"
    echo "   Ответ API: $SEND_RESPONSE"
    read -p "Продолжить настройку? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        echo "Отменено"
        exit 0
    fi
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
echo "Перезапуск Alertmanager для применения изменений..."
kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability

echo ""
echo "Ожидание готовности Alertmanager..."
if kubectl rollout status statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability --timeout=120s 2>/dev/null; then
    echo "✅ Alertmanager готов"
else
    echo "⚠️  Alertmanager еще не готов, но изменения применены"
fi

echo ""
echo "=========================================="
echo "Настройка завершена!"
echo "=========================================="
echo ""
echo "✅ Telegram bot настроен (@marateahookbot)"
echo "✅ Alertmanager конфигурация обновлена"
echo "✅ Alertmanager перезапущен"
echo ""
echo "📱 Тестирование:"
echo "   Для отправки тестового alert выполните:"
echo ""
echo "   kubectl run alert-test --rm -i --restart=Never \\"
echo "     --image=curlimages/curl -n observability -- \\"
echo "     curl -X POST http://alertmanager-monitoring-kube-prometheus-alertmanager:9093/api/v1/alerts \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '[{\"labels\":{\"alertname\":\"TestAlert\",\"severity\":\"critical\"},\"annotations\":{\"summary\":\"Test Alert\",\"description\":\"This is a test alert from Kubernetes\"}}]'"
echo ""

