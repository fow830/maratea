#!/bin/bash

# Автоматизированный скрипт для завершения Phase 1
# Использование: ./scripts/complete-phase1-setup.sh

set -e

EXTERNAL_IP="62.76.233.233"
KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

echo "=========================================="
echo "Завершение Phase 1 - Автоматизированная настройка"
echo "=========================================="
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    echo "Установите: export KUBECONFIG=/path/to/kubeconfig"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Функция проверки DNS
check_dns() {
    local domain=$1
    local result=$(dig +short "$domain" 2>/dev/null | head -1)
    if [ -n "$result" ] && [ "$result" = "$EXTERNAL_IP" ]; then
        echo "✅ DNS для $domain настроен: $result"
        return 0
    else
        echo "❌ DNS для $domain не настроен"
        return 1
    fi
}

# Функция проверки сертификата
check_certificate() {
    local namespace=$1
    local name=$2
    local ready=$(kubectl get certificate "$name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    if [ "$ready" = "True" ]; then
        echo "✅ Сертификат $name готов"
        return 0
    else
        echo "⏳ Сертификат $name не готов (DNS не настроен или в процессе получения)"
        return 1
    fi
}

echo "Шаг 1: Проверка DNS"
echo "------------------------------------------"
ARGOCD_DNS_OK=false
GRAFANA_DNS_OK=false

if check_dns "argocd.staging.betaserver.ru"; then
    ARGOCD_DNS_OK=true
else
    echo ""
    echo "⚠️  Требуется настройка DNS для ArgoCD:"
    echo "   Создайте A запись: argocd.staging → $EXTERNAL_IP"
    echo "   В панели управления DNS для домена betaserver.ru"
fi

if check_dns "grafana.staging.betaserver.ru"; then
    GRAFANA_DNS_OK=true
else
    echo ""
    echo "⚠️  Требуется настройка DNS для Grafana:"
    echo "   Создайте A запись: grafana.staging → $EXTERNAL_IP"
    echo "   В панели управления DNS для домена betaserver.ru"
fi

echo ""
echo "Шаг 2: Проверка TLS сертификатов"
echo "------------------------------------------"
check_certificate "argocd" "argocd-server-tls"
check_certificate "observability" "grafana-tls"
check_certificate "maratea" "api-gateway-tls"

echo ""
echo "Шаг 3: Проверка S3 Backup"
echo "------------------------------------------"
if kubectl get secret s3-backup-secret -n maratea &>/dev/null; then
    echo "✅ S3 secret существует"
    
    # Проверка заполненности
    S3_ENDPOINT=$(kubectl get secret s3-backup-secret -n maratea -o jsonpath='{.data.S3_ENDPOINT}' | base64 -d 2>/dev/null || echo "")
    if [ -z "$S3_ENDPOINT" ] || [ "$S3_ENDPOINT" = "YOUR_ACCESS_KEY" ]; then
        echo "⚠️  S3 secret существует, но содержит placeholder значения"
        echo "   Требуется заполнение реальными credentials"
        echo "   Используйте: kubectl edit secret s3-backup-secret -n maratea"
    else
        echo "✅ S3 secret заполнен"
        
        # Проверка CronJob
        if kubectl get cronjob postgres-backup-s3 -n maratea &>/dev/null; then
            echo "✅ PostgreSQL backup с S3 настроен"
        else
            echo "⚠️  PostgreSQL backup с S3 не применен"
            echo "   Примените: kubectl apply -f infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml"
        fi
    fi
else
    echo "❌ S3 secret не создан"
    echo "   Создайте S3 bucket в Timeweb Cloud и заполните секрет"
    echo "   Используйте: ./scripts/setup-s3-backup.sh"
fi

echo ""
echo "Шаг 4: Проверка Webhook уведомлений"
echo "------------------------------------------"
ALERTMANAGER_CONFIG=$(kubectl get secret alertmanager-config -n observability -o jsonpath='{.data.alertmanager\.yml}' | base64 -d 2>/dev/null || echo "")

if echo "$ALERTMANAGER_CONFIG" | grep -q "webhook_configs:" && ! echo "$ALERTMANAGER_CONFIG" | grep -q "#.*webhook_configs"; then
    echo "✅ Webhook конфигурация активна"
    
    # Проверка на placeholder URL
    if echo "$ALERTMANAGER_CONFIG" | grep -q "YOUR.*WEBHOOK\|BOT_TOKEN\|CHAT_ID"; then
        echo "⚠️  Webhook URL содержит placeholder значения"
        echo "   Требуется заполнение реальными URL"
        echo "   Используйте: kubectl edit secret alertmanager-config -n observability"
    else
        echo "✅ Webhook URL настроен"
    fi
else
    echo "⚠️  Webhook конфигурация не активна или закомментирована"
    echo "   Раскомментируйте и заполните webhook_configs в alertmanager-config"
    echo "   Используйте: ./scripts/setup-webhook-alerts.sh"
fi

echo ""
echo "=========================================="
echo "Итоговый статус Phase 1"
echo "=========================================="
echo ""

COMPLETED=0
TOTAL=3

if [ "$ARGOCD_DNS_OK" = true ] && [ "$GRAFANA_DNS_OK" = true ]; then
    echo "✅ DNS: Настроен"
    ((COMPLETED++))
else
    echo "⏳ DNS: Требует настройки"
fi

if kubectl get secret s3-backup-secret -n maratea &>/dev/null && \
   kubectl get cronjob postgres-backup-s3 -n maratea &>/dev/null && \
   ! kubectl get secret s3-backup-secret -n maratea -o jsonpath='{.data.S3_ENDPOINT}' | base64 -d | grep -q "YOUR"; then
    echo "✅ S3 Backup: Настроен"
    ((COMPLETED++))
else
    echo "⏳ S3 Backup: Требует настройки"
fi

if echo "$ALERTMANAGER_CONFIG" | grep -q "webhook_configs:" && \
   ! echo "$ALERTMANAGER_CONFIG" | grep -q "#.*webhook_configs" && \
   ! echo "$ALERTMANAGER_CONFIG" | grep -q "YOUR.*WEBHOOK\|BOT_TOKEN\|CHAT_ID"; then
    echo "✅ Webhook: Настроен"
    ((COMPLETED++))
else
    echo "⏳ Webhook: Требует настройки"
fi

echo ""
PERCENTAGE=$((COMPLETED * 100 / TOTAL))
echo "Завершено: $COMPLETED из $TOTAL задач ($PERCENTAGE%)"

if [ $COMPLETED -eq $TOTAL ]; then
    echo ""
    echo "🎉 Phase 1 полностью завершена!"
else
    echo ""
    echo "📋 Оставшиеся задачи:"
    echo "   1. Настроить DNS записи (см. ./scripts/setup-dns-argocd-grafana.sh)"
    echo "   2. Настроить S3 backup (см. ./scripts/setup-s3-backup.sh)"
    echo "   3. Настроить webhook уведомления (см. ./scripts/setup-webhook-alerts.sh)"
fi

echo ""
echo "Подробная документация: docs/timeweb/manual-setup-checklist.md"

