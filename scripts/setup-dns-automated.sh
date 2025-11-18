#!/bin/bash

# Автоматическая настройка DNS записей через Timeweb Cloud API
# Использование: ./scripts/setup-dns-automated.sh

set -e

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"
EXTERNAL_IP="62.76.233.233"
DOMAIN="betaserver.ru"
TIMEWEB_API_BASE_URL="https://api.timeweb.cloud/api/v1"

echo "=========================================="
echo "Автоматическая настройка DNS записей"
echo "=========================================="
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Получение токена из Kubernetes secret
echo "Шаг 1: Получение Timeweb API токена..."
TIMEWEB_TOKEN=$(kubectl get secret timeweb-api-token -n maratea -o jsonpath='{.data.TIMEWEB_API_TOKEN}' 2>/dev/null | base64 -d)

if [ -z "$TIMEWEB_TOKEN" ]; then
    echo "❌ Ошибка: Не удалось получить TIMEWEB_API_TOKEN из Kubernetes secret"
    echo "   Убедитесь, что секрет timeweb-api-token существует в namespace maratea"
    exit 1
fi

echo "✅ Токен получен"

# Проверка наличия curl и jq
if ! command -v curl &> /dev/null; then
    echo "❌ Ошибка: curl не установлен"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "⚠️  Предупреждение: jq не установлен, будет использован базовый парсинг JSON"
    USE_JQ=false
else
    USE_JQ=true
fi

# Функция для API запросов
api_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    local url="${TIMEWEB_API_BASE_URL}${endpoint}"
    local headers=(
        -H "Authorization: Bearer ${TIMEWEB_TOKEN}"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )
    
    if [ "$method" = "GET" ]; then
        curl -s "${headers[@]}" "$url"
    elif [ "$method" = "POST" ]; then
        curl -s -X POST "${headers[@]}" -d "$data" "$url"
    elif [ "$method" = "PUT" ]; then
        curl -s -X PUT "${headers[@]}" -d "$data" "$url"
    elif [ "$method" = "DELETE" ]; then
        curl -s -X DELETE "${headers[@]}" "$url"
    fi
}

# Получение списка доменов
echo ""
echo "Шаг 2: Поиск домена $DOMAIN..."
DOMAINS_RESPONSE=$(api_request "GET" "/domains")

if [ "$USE_JQ" = true ]; then
    DOMAIN_ID=$(echo "$DOMAINS_RESPONSE" | jq -r ".domains[]? | select(.fqdn == \"$DOMAIN\" or .name == \"$DOMAIN\") | .id" | head -1)
else
    DOMAIN_ID=$(echo "$DOMAINS_RESPONSE" | grep -o "\"id\":[0-9]*" | grep -o "[0-9]*" | head -1)
fi

if [ -z "$DOMAIN_ID" ] || [ "$DOMAIN_ID" = "null" ]; then
    echo "❌ Ошибка: Домен $DOMAIN не найден в вашем аккаунте Timeweb Cloud"
    echo ""
    echo "Доступные домены:"
    if [ "$USE_JQ" = true ]; then
        echo "$DOMAINS_RESPONSE" | jq -r '.domains[]? | "  - \(.fqdn // .name) (ID: \(.id))"'
    else
        echo "$DOMAINS_RESPONSE" | grep -o "\"fqdn\":\"[^\"]*\"" | head -5
    fi
    echo ""
    echo "Если домен зарегистрирован у другого провайдера, настройте DNS записи вручную:"
    echo "  - argocd.staging → $EXTERNAL_IP"
    echo "  - grafana.staging → $EXTERNAL_IP"
    exit 1
fi

echo "✅ Домен найден (ID: $DOMAIN_ID)"

# Получение текущих DNS записей
echo ""
echo "Шаг 3: Получение текущих DNS записей..."
DNS_RECORDS_RESPONSE=$(api_request "GET" "/domains/${DOMAIN_ID}/dns")

# Проверка существующих записей
check_record_exists() {
    local subdomain=$1
    if [ "$USE_JQ" = true ]; then
        echo "$DNS_RECORDS_RESPONSE" | jq -r ".records[]? | select(.subdomain == \"$subdomain\" and .type == \"A\" and .content == \"$EXTERNAL_IP\") | .id" | head -1
    else
        echo "$DNS_RECORDS_RESPONSE" | grep -q "\"subdomain\":\"$subdomain\"" && \
        echo "$DNS_RECORDS_RESPONSE" | grep -q "\"type\":\"A\"" && \
        echo "$DNS_RECORDS_RESPONSE" | grep -q "\"content\":\"$EXTERNAL_IP\"" && echo "exists" || echo ""
    fi
}

# Создание DNS записей
create_dns_record() {
    local subdomain=$1
    local record_name=$2
    
    echo ""
    echo "Настройка DNS записи для $record_name..."
    
    # Проверка существования
    EXISTING=$(check_record_exists "$subdomain")
    
    if [ -n "$EXISTING" ] && [ "$EXISTING" != "" ]; then
        echo "✅ DNS запись для $subdomain уже существует"
        return 0
    fi
    
    # Создание записи
    RECORD_DATA=$(cat <<EOF
{
  "subdomain": "$subdomain",
  "type": "A",
  "content": "$EXTERNAL_IP",
  "ttl": 300
}
EOF
)
    
    echo "Создание A записи: $subdomain → $EXTERNAL_IP"
    CREATE_RESPONSE=$(api_request "POST" "/domains/${DOMAIN_ID}/dns" "$RECORD_DATA")
    
    if [ "$USE_JQ" = true ]; then
        ERROR=$(echo "$CREATE_RESPONSE" | jq -r '.error?.message // .message // ""')
        if [ -n "$ERROR" ] && [ "$ERROR" != "null" ]; then
            echo "❌ Ошибка при создании записи: $ERROR"
            return 1
        fi
        RECORD_ID=$(echo "$CREATE_RESPONSE" | jq -r '.record?.id // .id // ""')
        if [ -n "$RECORD_ID" ] && [ "$RECORD_ID" != "null" ]; then
            echo "✅ DNS запись создана успешно (ID: $RECORD_ID)"
            return 0
        fi
    else
        if echo "$CREATE_RESPONSE" | grep -q "error\|Error"; then
            echo "❌ Ошибка при создании записи"
            echo "$CREATE_RESPONSE"
            return 1
        else
            echo "✅ DNS запись создана успешно"
            return 0
        fi
    fi
    
    echo "⚠️  Не удалось определить результат создания записи"
    echo "Ответ API: $CREATE_RESPONSE"
    return 1
}

# Создание записей
echo ""
echo "Шаг 4: Создание DNS записей..."

ARGOCD_OK=false
GRAFANA_OK=false

if create_dns_record "argocd.staging" "ArgoCD"; then
    ARGOCD_OK=true
fi

if create_dns_record "grafana.staging" "Grafana"; then
    GRAFANA_OK=true
fi

# Проверка через DNS
echo ""
echo "Шаг 5: Проверка DNS резолюции..."
echo "------------------------------------------"

check_dns_resolution() {
    local domain=$1
    local result=$(dig +short "$domain" 2>/dev/null | head -1)
    if [ -n "$result" ] && [ "$result" = "$EXTERNAL_IP" ]; then
        echo "✅ $domain → $result"
        return 0
    else
        echo "⏳ $domain → еще не резолвится (может потребоваться несколько минут)"
        return 1
    fi
}

ARGOCD_DNS_OK=false
GRAFANA_DNS_OK=false

if check_dns_resolution "argocd.staging.betaserver.ru"; then
    ARGOCD_DNS_OK=true
fi

if check_dns_resolution "grafana.staging.betaserver.ru"; then
    GRAFANA_DNS_OK=true
fi

# Итоговый статус
echo ""
echo "=========================================="
echo "Итоговый статус"
echo "=========================================="
echo ""

if [ "$ARGOCD_OK" = true ]; then
    echo "✅ DNS запись для ArgoCD создана"
else
    echo "❌ Не удалось создать DNS запись для ArgoCD"
fi

if [ "$GRAFANA_OK" = true ]; then
    echo "✅ DNS запись для Grafana создана"
else
    echo "❌ Не удалось создать DNS запись для Grafana"
fi

echo ""

if [ "$ARGOCD_DNS_OK" = true ] && [ "$GRAFANA_DNS_OK" = true ]; then
    echo "🎉 DNS записи настроены и резолвятся!"
    echo ""
    echo "Следующие шаги:"
    echo "1. Cert-manager автоматически получит TLS сертификаты (5-10 минут)"
    echo "2. Проверка: kubectl get certificate -A"
    echo "3. Доступ к ArgoCD: https://argocd.staging.betaserver.ru"
    echo "4. Доступ к Grafana: https://grafana.staging.betaserver.ru"
else
    echo "⚠️  DNS записи созданы, но еще не резолвятся"
    echo ""
    echo "Это нормально - распространение DNS может занять несколько минут"
    echo "Проверьте через несколько минут:"
    echo "  dig +short argocd.staging.betaserver.ru"
    echo "  dig +short grafana.staging.betaserver.ru"
    echo ""
    echo "После того как DNS начнет резолвиться, cert-manager автоматически получит TLS сертификаты"
fi

echo ""
echo "Для проверки статуса запустите:"
echo "  ./scripts/complete-phase1-setup.sh"

