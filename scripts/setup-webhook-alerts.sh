#!/bin/bash

# Интерактивный скрипт для настройки webhook уведомлений
# Использование: ./scripts/setup-webhook-alerts.sh

set -e

echo "=========================================="
echo "Настройка Webhook уведомлений для Alertmanager"
echo "=========================================="
echo ""

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Ошибка: kubectl не установлен"
    exit 1
fi

# Проверка KUBECONFIG
if [ -z "$KUBECONFIG" ]; then
    echo "Предупреждение: KUBECONFIG не установлен"
    echo "Используйте: export KUBECONFIG=/path/to/kubeconfig"
    read -p "Продолжить? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Выберите платформу для уведомлений:"
echo "1. Slack"
echo "2. Telegram"
echo "3. Пропустить (настроить позже)"
read -p "Ваш выбор (1-3): " PLATFORM

case $PLATFORM in
    1)
        echo ""
        echo "Настройка Slack Webhook"
        echo "------------------------------------------"
        echo "1. Перейдите на https://api.slack.com/apps"
        echo "2. Создайте новое приложение или выберите существующее"
        echo "3. Перейдите в 'Incoming Webhooks'"
        echo "4. Активируйте Incoming Webhooks"
        echo "5. Нажмите 'Add New Webhook to Workspace'"
        echo "6. Выберите канал для уведомлений"
        echo "7. Скопируйте Webhook URL"
        echo ""
        read -p "Введите Slack Webhook URL: " WEBHOOK_URL
        
        if [ -z "$WEBHOOK_URL" ]; then
            echo "Ошибка: Webhook URL обязателен"
            exit 1
        fi
        
        # Получить текущую конфигурацию
        CURRENT_CONFIG=$(kubectl get secret alertmanager-config -n observability -o jsonpath='{.data.alertmanager\.yml}' | base64 -d)
        
        # Создать временный файл с обновленной конфигурацией
        TMP_FILE=$(mktemp)
        echo "$CURRENT_CONFIG" > "$TMP_FILE"
        
        # Обновить конфигурацию (добавить Slack webhook)
        # Это упрощенная версия - в реальности нужен более сложный парсинг YAML
        echo ""
        echo "⚠️  Внимание: Автоматическое обновление конфигурации требует ручного редактирования"
        echo "Используйте команду:"
        echo "  kubectl edit secret alertmanager-config -n observability"
        echo ""
        echo "Раскомментируйте и обновите секцию для Slack:"
        echo "  webhook_configs:"
        echo "    - url: '$WEBHOOK_URL'"
        echo "      send_resolved: true"
        echo ""
        read -p "Нажмите Enter после обновления конфигурации..."
        
        # Перезапустить Alertmanager
        echo ""
        echo "Перезапуск Alertmanager..."
        kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability
        echo "✅ Alertmanager перезапущен"
        ;;
    2)
        echo ""
        echo "Настройка Telegram Bot"
        echo "------------------------------------------"
        echo "1. Откройте Telegram и найдите @BotFather"
        echo "2. Отправьте команду /newbot"
        echo "3. Следуйте инструкциям для создания бота"
        echo "4. Сохраните Bot Token"
        echo ""
        read -p "Введите Telegram Bot Token: " BOT_TOKEN
        
        if [ -z "$BOT_TOKEN" ]; then
            echo "Ошибка: Bot Token обязателен"
            exit 1
        fi
        
        echo ""
        echo "Получение Chat ID:"
        echo "1. Создайте группу в Telegram или используйте личный чат"
        echo "2. Добавьте вашего бота в группу"
        echo "3. Отправьте любое сообщение боту"
        echo "4. Откройте в браузере:"
        echo "   https://api.telegram.org/bot$BOT_TOKEN/getUpdates"
        echo "5. Найдите chat.id в ответе"
        echo ""
        read -p "Введите Chat ID: " CHAT_ID
        
        if [ -z "$CHAT_ID" ]; then
            echo "Ошибка: Chat ID обязателен"
            exit 1
        fi
        
        WEBHOOK_URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
        
        echo ""
        echo "⚠️  Внимание: Автоматическое обновление конфигурации требует ручного редактирования"
        echo "Используйте команду:"
        echo "  kubectl edit secret alertmanager-config -n observability"
        echo ""
        echo "Раскомментируйте и обновите секцию для Telegram:"
        echo "  webhook_configs:"
        echo "    - url: '$WEBHOOK_URL'"
        echo "      send_resolved: true"
        echo "      http_config:"
        echo "        method: POST"
        echo "      body: |"
        echo "        {"
        echo "          \"chat_id\": \"$CHAT_ID\","
        echo "          \"text\": \"🚨 Alert: {{ .GroupLabels.alertname }}\""
        echo "        }"
        echo ""
        read -p "Нажмите Enter после обновления конфигурации..."
        
        # Перезапустить Alertmanager
        echo ""
        echo "Перезапуск Alertmanager..."
        kubectl rollout restart statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -n observability
        echo "✅ Alertmanager перезапущен"
        ;;
    3)
        echo "Настройка пропущена. Вы можете настроить позже, следуя инструкциям в docs/timeweb/webhook-setup.md"
        exit 0
        ;;
    *)
        echo "Неверный выбор"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Тестирование уведомлений"
echo "=========================================="
echo ""
echo "Для тестирования выполните:"
echo ""
echo "1. Port-forward Alertmanager:"
echo "   kubectl port-forward -n observability svc/alertmanager-monitoring-kube-prometheus-alertmanager 9093:9093"
echo ""
echo "2. Отправить тестовый alert:"
echo "   curl -X POST http://localhost:9093/api/v1/alerts \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '[{"
echo "       \"labels\": {"
echo "         \"alertname\": \"TestAlert\","
echo "         \"severity\": \"critical\""
echo "       },"
echo "       \"annotations\": {"
echo "         \"summary\": \"Test alert\","
echo "         \"description\": \"This is a test alert\""
echo "       }"
echo "     }]'"
echo ""
echo "Проверьте, что уведомление пришло в выбранную платформу."

