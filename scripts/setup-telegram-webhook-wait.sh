#!/bin/bash

# Автоматическое получение Chat ID и настройка webhook
# Скрипт ждет, пока пользователь отправит сообщение боту

set -e

BOT_TOKEN="8594621300:AAHo7Da-tbzz4DI4XPSeXzMDOaSvQRb-5ys"
KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

echo "=========================================="
echo "Автоматическая настройка Telegram webhook"
echo "=========================================="
echo ""
echo "📱 Инструкция:"
echo "   1. Откройте Telegram"
echo "   2. Найдите бота: @marateahookbot"
echo "   3. Отправьте любое сообщение боту (например: /start или Hello)"
echo ""
echo "⏳ Ожидание сообщения от пользователя..."
echo "   (Скрипт будет проверять каждые 3 секунды)"
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "❌ Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Ожидание сообщения (максимум 2 минуты)
MAX_ATTEMPTS=40
ATTEMPT=0
CHAT_ID=""

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    # Получаем обновления
    UPDATES=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates")
    
    # Извлекаем Chat ID
    CHAT_ID=$(echo "$UPDATES" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    updates = data.get('result', [])
    for update in updates:
        if 'message' in update:
            chat_id = update['message']['chat']['id']
            print(chat_id)
            break
except:
    pass
" 2>/dev/null || echo "")
    
    if [ -n "$CHAT_ID" ] && [ "$CHAT_ID" != "" ]; then
        echo ""
        echo "✅ Chat ID получен: $CHAT_ID"
        break
    fi
    
    # Показываем прогресс каждые 5 попыток
    if [ $((ATTEMPT % 5)) -eq 0 ]; then
        echo "   Попытка $ATTEMPT/$MAX_ATTEMPTS... (отправьте сообщение боту @marateahookbot)"
    fi
    
    sleep 3
done

if [ -z "$CHAT_ID" ] || [ "$CHAT_ID" == "" ]; then
    echo ""
    echo "❌ Не удалось получить Chat ID"
    echo ""
    echo "Попробуйте вручную:"
    echo "   1. Отправьте сообщение боту @marateahookbot"
    echo "   2. Выполните:"
    echo "      curl -s 'https://api.telegram.org/bot${BOT_TOKEN}/getUpdates' | grep -o '\"chat\":{\"id\":[0-9-]*' | head -1 | grep -o '[0-9-]*\$'"
    echo "   3. Запустите: ./scripts/setup-telegram-webhook-quick.sh <CHAT_ID>"
    exit 1
fi

echo ""
echo "Настройка webhook..."

# Запускаем быстрый скрипт настройки
./scripts/setup-telegram-webhook-quick.sh "$CHAT_ID"

