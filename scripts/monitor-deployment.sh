#!/bin/bash

# Скрипт для мониторинга деплоя нового образа API Gateway
# Использование: ./scripts/monitor-deployment.sh

set -e

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

echo "=========================================="
echo "Мониторинг деплоя API Gateway"
echo "=========================================="
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

# Проверяем, есть ли метрики
echo "Проверка endpoint /metrics..."
kubectl port-forward -n maratea svc/api-gateway 8080:8080 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!
sleep 3

METRICS_CHECK=$(curl -s http://localhost:8080/metrics 2>/dev/null | grep -c "http_requests_total" || echo "0")
kill $PORT_FORWARD_PID 2>/dev/null || true

if [ "$METRICS_CHECK" != "0" ]; then
    echo "✅ Метрики доступны! Новый образ уже задеплоен."
    echo ""
    echo "Проверка метрик:"
    ./scripts/verify-metrics.sh
    exit 0
else
    echo "⏳ Метрики еще недоступны. Ожидание деплоя..."
    echo ""
    echo "Для отслеживания деплоя выполните:"
    echo "  ./scripts/wait-for-deployment.sh"
    echo ""
    echo "Или проверьте вручную:"
    echo "  kubectl get pods -n maratea -l app=api-gateway -o wide"
    echo "  kubectl get deployment api-gateway -n maratea -o yaml | grep image"
fi

