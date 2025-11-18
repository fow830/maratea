#!/bin/bash

# Скрипт для тестирования системы мониторинга
# Использование: ./scripts/test-monitoring.sh

set -e

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

echo "=========================================="
echo "Тестирование системы мониторинга"
echo "=========================================="
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "❌ Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция проверки
check_status() {
    local name=$1
    local command=$2
    
    echo -n "Проверка $name... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        return 1
    fi
}

# Функция проверки с выводом
check_status_with_output() {
    local name=$1
    local command=$2
    
    echo "Проверка $name:"
    if eval "$command"; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        return 1
    fi
    echo ""
}

echo "Шаг 1: Проверка компонентов мониторинга"
echo "----------------------------------------"

check_status "Prometheus" "kubectl get pods -n observability | grep prometheus | grep Running"
check_status "Grafana" "kubectl get pods -n observability | grep grafana | grep Running"
check_status "Alertmanager" "kubectl get pods -n observability | grep alertmanager | grep Running"
check_status "Loki" "kubectl get pods -n observability | grep loki | grep Running"

echo ""
echo "Шаг 2: Проверка Prometheus Rules"
echo "----------------------------------------"

check_status "PrometheusRule maratea-alerts" "kubectl get prometheusrule maratea-alerts -n observability"

echo ""
echo "Шаг 3: Проверка метрик"
echo "----------------------------------------"

# Port-forward для Prometheus
echo "Настройка port-forward для Prometheus..."
kubectl port-forward -n observability svc/monitoring-kube-prometheus-prometheus 9090:9090 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!
sleep 3

# Проверка доступности Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Prometheus доступен${NC}"
    
    # Проверка правил
    echo ""
    echo "Проверка загруженных правил..."
    RULES=$(curl -s "http://localhost:9090/api/v1/rules" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    groups = data.get('data', {}).get('groups', [])
    maratea_rules = [g for g in groups if 'maratea' in str(g).lower()]
    if maratea_rules:
        print(f'Найдено групп правил maratea: {len(maratea_rules)}')
        for group in maratea_rules:
            rules_count = len(group.get('rules', []))
            print(f\"  - {group.get('name', 'unknown')}: {rules_count} правил\")
    else:
        print('Правила maratea не найдены')
except Exception as e:
    print(f'Ошибка: {e}')
" 2>/dev/null || echo "Ошибка при получении правил")
    echo "$RULES"
    
    # Проверка метрик приложения
    echo ""
    echo "Проверка метрик приложения..."
    
    # API Gateway
    API_GATEWAY_UP=$(curl -s "http://localhost:9090/api/v1/query?query=up{job=\"api-gateway\",namespace=\"maratea\"}" | python3 -c "import sys, json; data = json.load(sys.stdin); result = data.get('data', {}).get('result', []); print('1' if result and result[0].get('value', [None, '0'])[1] == '1' else '0')" 2>/dev/null || echo "0")
    if [ "$API_GATEWAY_UP" = "1" ]; then
        echo -e "  API Gateway: ${GREEN}✅ UP${NC}"
    else
        echo -e "  API Gateway: ${RED}❌ DOWN${NC}"
    fi
    
    # PostgreSQL
    POSTGRES_UP=$(curl -s "http://localhost:9090/api/v1/query?query=up{job=\"postgres\",namespace=\"maratea\"}" | python3 -c "import sys, json; data = json.load(sys.stdin); result = data.get('data', {}).get('result', []); print('1' if result and result[0].get('value', [None, '0'])[1] == '1' else '0')" 2>/dev/null || echo "0")
    if [ "$POSTGRES_UP" = "1" ]; then
        echo -e "  PostgreSQL: ${GREEN}✅ UP${NC}"
    else
        echo -e "  PostgreSQL: ${RED}❌ DOWN${NC}"
    fi
    
    # Redis
    REDIS_UP=$(curl -s "http://localhost:9090/api/v1/query?query=up{job=\"redis\",namespace=\"maratea\"}" | python3 -c "import sys, json; data = json.load(sys.stdin); result = data.get('data', {}).get('result', []); print('1' if result and result[0].get('value', [None, '0'])[1] == '1' else '0')" 2>/dev/null || echo "0")
    if [ "$REDIS_UP" = "1" ]; then
        echo -e "  Redis: ${GREEN}✅ UP${NC}"
    else
        echo -e "  Redis: ${RED}❌ DOWN${NC}"
    fi
    
else
    echo -e "${RED}❌ Prometheus недоступен${NC}"
fi

# Остановка port-forward
kill $PORT_FORWARD_PID 2>/dev/null || true

echo ""
echo "Шаг 4: Проверка Alertmanager"
echo "----------------------------------------"

# Port-forward для Alertmanager
echo "Настройка port-forward для Alertmanager..."
kubectl port-forward -n observability svc/alertmanager-monitoring-kube-prometheus-alertmanager 9093:9093 > /dev/null 2>&1 &
ALERTMANAGER_PORT_FORWARD_PID=$!
sleep 3

if curl -s http://localhost:9093/-/healthy > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Alertmanager доступен${NC}"
    
    # Проверка активных алертов
    echo ""
    echo "Активные алерты:"
    ACTIVE_ALERTS=$(curl -s "http://localhost:9093/api/v1/alerts" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    alerts = data.get('data', {}).get('alerts', [])
    if alerts:
        print(f'Найдено активных алертов: {len(alerts)}')
        for alert in alerts[:5]:  # Показываем первые 5
            print(f\"  - {alert.get('labels', {}).get('alertname', 'unknown')}: {alert.get('status', {}).get('state', 'unknown')}\")
    else:
        print('Активных алертов нет')
except Exception as e:
    print(f'Ошибка: {e}')
" 2>/dev/null || echo "Ошибка при получении алертов")
    echo "$ACTIVE_ALERTS"
else
    echo -e "${RED}❌ Alertmanager недоступен${NC}"
fi

# Остановка port-forward
kill $ALERTMANAGER_PORT_FORWARD_PID 2>/dev/null || true

echo ""
echo "Шаг 5: Проверка Grafana"
echo "----------------------------------------"

GRAFANA_POD=$(kubectl get pods -n observability -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$GRAFANA_POD" ]; then
    echo -e "${GREEN}✅ Grafana pod найден: $GRAFANA_POD${NC}"
    
    # Проверка готовности
    GRAFANA_READY=$(kubectl get pod $GRAFANA_POD -n observability -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    if [ "$GRAFANA_READY" = "True" ]; then
        echo -e "  Статус: ${GREEN}✅ Ready${NC}"
    else
        echo -e "  Статус: ${RED}❌ Not Ready${NC}"
    fi
else
    echo -e "${RED}❌ Grafana pod не найден${NC}"
fi

echo ""
echo "Шаг 6: Проверка Loki"
echo "----------------------------------------"

LOKI_POD=$(kubectl get pods -n observability -l app=loki -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$LOKI_POD" ]; then
    echo -e "${GREEN}✅ Loki pod найден: $LOKI_POD${NC}"
    
    # Проверка готовности
    LOKI_READY=$(kubectl get pod $LOKI_POD -n observability -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    if [ "$LOKI_READY" = "True" ]; then
        echo -e "  Статус: ${GREEN}✅ Ready${NC}"
    else
        echo -e "  Статус: ${RED}❌ Not Ready${NC}"
    fi
else
    echo -e "${RED}❌ Loki pod не найден${NC}"
fi

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
echo "  Grafana:"
echo "    https://grafana.staging.betaserver.ru"
echo "    (Basic Auth: admin / пароль из secret)"
echo ""
echo "  Alertmanager:"
echo "    kubectl port-forward -n observability svc/alertmanager-monitoring-kube-prometheus-alertmanager 9093:9093"
echo "    http://localhost:9093"
echo ""
echo "=========================================="

