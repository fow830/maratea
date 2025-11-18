#!/bin/bash

# Скрипт для ожидания деплоя нового образа API Gateway
# Использование: ./scripts/wait-for-deployment.sh [timeout_seconds]

set -e

TIMEOUT=${1:-600}  # По умолчанию 10 минут
KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

echo "=========================================="
echo "Ожидание деплоя нового образа API Gateway"
echo "=========================================="
echo ""
echo "Таймаут: ${TIMEOUT} секунд"
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "❌ Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Получаем текущий образ
CURRENT_IMAGE=$(kubectl get deployment api-gateway -n maratea -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")

if [ -z "$CURRENT_IMAGE" ]; then
    echo "❌ Ошибка: Deployment api-gateway не найден"
    exit 1
fi

echo "Текущий образ: $CURRENT_IMAGE"
echo ""
echo "Ожидание обновления образа..."
echo ""

START_TIME=$(date +%s)
LAST_IMAGE="$CURRENT_IMAGE"

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $TIMEOUT ]; then
        echo ""
        echo "❌ Таймаут ожидания деплоя (${TIMEOUT} секунд)"
        exit 1
    fi
    
    # Проверяем образ deployment
    NEW_IMAGE=$(kubectl get deployment api-gateway -n maratea -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
    
    if [ "$NEW_IMAGE" != "$LAST_IMAGE" ] && [ -n "$NEW_IMAGE" ]; then
        echo ""
        echo "✅ Образ обновлен!"
        echo "   Старый: $LAST_IMAGE"
        echo "   Новый:  $NEW_IMAGE"
        echo ""
        echo "Ожидание готовности pods..."
        
        # Ждем готовности pods
        kubectl rollout status deployment/api-gateway -n maratea --timeout=300s
        
        echo ""
        echo "✅ Деплой завершен!"
        exit 0
    fi
    
    # Проверяем статус pods
    READY_PODS=$(kubectl get pods -n maratea -l app=api-gateway -o jsonpath='{.items[?(@.status.conditions[?(@.type=="Ready")].status=="True")].metadata.name}' 2>/dev/null | wc -w | tr -d ' ')
    TOTAL_PODS=$(kubectl get pods -n maratea -l app=api-gateway --no-headers 2>/dev/null | wc -l | tr -d ' ')
    
    if [ -n "$READY_PODS" ] && [ -n "$TOTAL_PODS" ]; then
        echo -ne "\r⏳ Ожидание... (${ELAPSED}s/${TIMEOUT}s) - Pods: ${READY_PODS}/${TOTAL_PODS} ready"
    else
        echo -ne "\r⏳ Ожидание... (${ELAPSED}s/${TIMEOUT}s)"
    fi
    
    sleep 5
done

