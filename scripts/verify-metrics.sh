#!/bin/bash

# Скрипт для проверки метрик Prometheus в API Gateway
# Использование: ./scripts/verify-metrics.sh

set -e

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

echo "=========================================="
echo "Проверка метрик Prometheus в API Gateway"
echo "=========================================="
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "❌ Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Шаг 1: Проверка endpoint /metrics"
echo "----------------------------------------"

# Port-forward для API Gateway
echo "Настройка port-forward для API Gateway..."
kubectl port-forward -n maratea svc/api-gateway 8080:8080 > /dev/null 2>&1 &
API_GATEWAY_PID=$!
sleep 3

# Проверка метрик
METRICS_RESPONSE=$(curl -s http://localhost:8080/metrics 2>/dev/null || echo "")

if [ -z "$METRICS_RESPONSE" ]; then
    echo -e "${RED}❌ Метрики недоступны${NC}"
    echo "   Возможно, API Gateway еще не обновлен с новым образом"
    kill $API_GATEWAY_PID 2>/dev/null || true
    exit 1
fi

# Проверка наличия ключевых метрик
if echo "$METRICS_RESPONSE" | grep -q "http_requests_total"; then
    echo -e "${GREEN}✅ Метрика http_requests_total найдена${NC}"
else
    echo -e "${RED}❌ Метрика http_requests_total не найдена${NC}"
fi

if echo "$METRICS_RESPONSE" | grep -q "http_request_duration_seconds"; then
    echo -e "${GREEN}✅ Метрика http_request_duration_seconds найдена${NC}"
else
    echo -e "${RED}❌ Метрика http_request_duration_seconds не найдена${NC}"
fi

if echo "$METRICS_RESPONSE" | grep -q "process_memory_usage_bytes"; then
    echo -e "${GREEN}✅ Метрика process_memory_usage_bytes найдена${NC}"
else
    echo -e "${RED}❌ Метрика process_memory_usage_bytes не найдена${NC}"
fi

echo ""
echo "Примеры метрик:"
echo "$METRICS_RESPONSE" | grep -E "^(http_|process_)" | head -10

kill $API_GATEWAY_PID 2>/dev/null || true

echo ""
echo "Шаг 2: Проверка сбора метрик в Prometheus"
echo "----------------------------------------"

# Port-forward для Prometheus
echo "Настройка port-forward для Prometheus..."
kubectl port-forward -n observability svc/monitoring-kube-prometheus-prometheus 9090:9090 > /dev/null 2>&1 &
PROMETHEUS_PID=$!
sleep 3

# Проверка targets
TARGETS_RESPONSE=$(curl -s "http://localhost:9090/api/v1/targets" 2>/dev/null || echo "")

if [ -z "$TARGETS_RESPONSE" ]; then
    echo -e "${RED}❌ Prometheus недоступен${NC}"
    kill $PROMETHEUS_PID 2>/dev/null || true
    exit 1
fi

# Проверка API Gateway target
API_GATEWAY_TARGET=$(echo "$TARGETS_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    targets = data.get('data', {}).get('activeTargets', [])
    api_gateway = [t for t in targets if 'api-gateway' in t.get('labels', {}).get('job', '')]
    if api_gateway:
        t = api_gateway[0]
        print(f\"{t['labels']['job']}|{t['health']}|{t.get('lastError', 'OK')}\")
    else:
        print('NOT_FOUND')
except:
    print('ERROR')
" 2>/dev/null || echo "ERROR")

if [ "$API_GATEWAY_TARGET" != "NOT_FOUND" ] && [ "$API_GATEWAY_TARGET" != "ERROR" ]; then
    JOB=$(echo "$API_GATEWAY_TARGET" | cut -d'|' -f1)
    HEALTH=$(echo "$API_GATEWAY_TARGET" | cut -d'|' -f2)
    ERROR=$(echo "$API_GATEWAY_TARGET" | cut -d'|' -f3)
    
    if [ "$HEALTH" = "up" ]; then
        echo -e "${GREEN}✅ API Gateway target найден и работает${NC}"
        echo "   Job: $JOB"
        echo "   Health: $HEALTH"
    else
        echo -e "${YELLOW}⚠️  API Gateway target найден, но не работает${NC}"
        echo "   Job: $JOB"
        echo "   Health: $HEALTH"
        echo "   Error: $ERROR"
    fi
else
    echo -e "${RED}❌ API Gateway target не найден в Prometheus${NC}"
    echo "   Проверьте ServiceMonitor и labels"
fi

# Проверка метрик в Prometheus
echo ""
echo "Проверка метрик в Prometheus..."

HTTP_REQUESTS=$(curl -s "http://localhost:9090/api/v1/query?query=http_requests_total" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    result = data.get('data', {}).get('result', [])
    print('1' if result else '0')
except:
    print('0')
" 2>/dev/null || echo "0")

if [ "$HTTP_REQUESTS" = "1" ]; then
    echo -e "${GREEN}✅ Метрика http_requests_total найдена в Prometheus${NC}"
else
    echo -e "${YELLOW}⚠️  Метрика http_requests_total не найдена в Prometheus${NC}"
    echo "   Возможно, еще не было запросов к API Gateway"
fi

kill $PROMETHEUS_PID 2>/dev/null || true

echo ""
echo "Шаг 3: Проверка Prometheus Rules"
echo "----------------------------------------"

# Port-forward для Prometheus
kubectl port-forward -n observability svc/monitoring-kube-prometheus-prometheus 9090:9090 > /dev/null 2>&1 &
PROMETHEUS_PID=$!
sleep 3

RULES_RESPONSE=$(curl -s "http://localhost:9090/api/v1/rules" 2>/dev/null || echo "")

if [ -n "$RULES_RESPONSE" ]; then
    MARATEA_RULES=$(echo "$RULES_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    groups = data.get('data', {}).get('groups', [])
    maratea = [g for g in groups if 'maratea' in str(g).lower()]
    print(len(maratea))
except:
    print('0')
" 2>/dev/null || echo "0")
    
    if [ "$MARATEA_RULES" != "0" ]; then
        echo -e "${GREEN}✅ Найдено групп правил maratea: $MARATEA_RULES${NC}"
    else
        echo -e "${YELLOW}⚠️  Правила maratea не найдены${NC}"
    fi
else
    echo -e "${RED}❌ Не удалось получить правила${NC}"
fi

kill $PROMETHEUS_PID 2>/dev/null || true

echo ""
echo "=========================================="
echo "Итоговый отчет"
echo "=========================================="
echo ""
echo "Для доступа к интерфейсам:"
echo ""
echo "  Prometheus:"
echo "    kubectl port-forward -n observability svc/monitoring-kube-prometheus-prometheus 9090:9090"
echo "    http://localhost:9090"
echo ""
echo "  API Gateway метрики:"
echo "    kubectl port-forward -n maratea svc/api-gateway 8080:8080"
echo "    curl http://localhost:8080/metrics"
echo ""
echo "  Проверка targets:"
echo "    http://localhost:9090/targets"
echo ""
echo "  Проверка правил:"
echo "    http://localhost:9090/rules"
echo ""

