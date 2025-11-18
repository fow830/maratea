#!/bin/bash

# Интерактивная настройка Telegram webhook для Alertmanager
# Использование: ./scripts/setup-telegram-webhook.sh

set -e

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

echo "=========================================="
echo "Настройка Telegram webhook для Alertmanager"
echo "=========================================="
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "❌ Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

echo "📋 Инструкция по созданию Telegram bot:"
echo ""
echo "1. Откройте Telegram и найдите @BotFather"
echo "2. Отправьте команду: /newbot"
echo "3. Следуйте инструкциям BotFather:"
echo "   - Введите имя бота (например: Maratea Alerts Bot)"
echo "   - Введите username бота (должен заканчиваться на 'bot', например: maratea_alerts_bot)"
echo "4. BotFather предоставит вам Bot Token (выглядит как: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)"
echo ""
echo "5. Для получения Chat ID:"
echo "   - Найдите вашего бота в Telegram"
echo "   - Отправьте любое сообщение боту (например: /start)"
echo "   - Откройте в браузере:"
echo "     https://api.telegram.org/bot<BOT_TOKEN>/getUpdates"
echo "   - Найдите 'chat':{'id': <CHAT_ID>} в ответе"
echo "   - Для личного чата: положительное число"
echo "   - Для группы: отрицательное число"
echo ""

read -p "Введите Bot Token: " BOT_TOKEN
if [ -z "$BOT_TOKEN" ]; then
    echo "❌ Ошибка: Bot Token обязателен"
    exit 1
fi

read -p "Введите Chat ID: " CHAT_ID
if [ -z "$CHAT_ID" ]; then
    echo "❌ Ошибка: Chat ID обязателен"
    exit 1
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
    echo "⚠️  Не удалось проверить Bot Token"
    echo "   Ответ: $CHECK_RESPONSE"
    read -p "Продолжить настройку? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        echo "Отменено"
        exit 0
    fi
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

# Заменяем закомментированные Telegram webhook строки на активные
echo "$CURRENT_CONFIG" | sed -E "
/# Telegram webhook/,/#     }/ {
    /# Telegram webhook/ {
        # Удаляем комментарий и добавляем активный webhook
        d
    }
    /# - url: 'https:\/\/api\.telegram\.org\/bot/ {
        # Заменяем на активный URL
        s|# - url: 'https://api.telegram.org/bot<BOT_TOKEN>/sendMessage'|- url: 'https://api.telegram.org/bot${BOT_TOKEN}/sendMessage'|
        s|<BOT_TOKEN>|${BOT_TOKEN}|g
    }
    /#   send_resolved: true/ {
        s|#   send_resolved: true|  send_resolved: true|
    }
    /#   http_config:/ {
        s|#   http_config:|  http_config:|
    }
    /#     method: POST/ {
        s|#     method: POST|    method: POST|
    }
    /#   body: \|/ {
        s|#   body: \||  body: \||
    }
    /#     {/ {
        s|#     {|    {|
    }
    /#       \"chat_id\": \"<CHAT_ID>\",/ {
        s|#       \"chat_id\": \"<CHAT_ID>\",|      \"chat_id\": \"${CHAT_ID}\",|
    }
    /#       \"text\": / {
        # Оставляем текст как есть, но убираем комментарий
        s|#       \"text\": |      \"text\": |
    }
    /#     }/ {
        s|#     }|    }|
    }
}" > "$TEMP_CONFIG"

# Если sed не сработал (macOS sed), используем более простой подход
if ! grep -q "api.telegram.org/bot${BOT_TOKEN}" "$TEMP_CONFIG"; then
    # Простая замена: удаляем закомментированный блок и добавляем активный
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
fi

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
echo "✅ Telegram bot настроен"
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
