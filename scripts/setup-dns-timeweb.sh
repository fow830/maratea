#!/bin/bash

# Настройка DNS записей для betaserver.ru через Timeweb Cloud
# Использование: ./scripts/setup-dns-timeweb.sh

set -e

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"
EXTERNAL_IP="62.76.233.233"
DOMAIN="betaserver.ru"
TIMEWEB_API_BASE_URL="https://api.timeweb.cloud/api/v1"

echo "=========================================="
echo "Настройка DNS записей для $DOMAIN"
echo "=========================================="
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Получение токена
echo "Получение Timeweb API токена..."
TIMEWEB_TOKEN=$(kubectl get secret timeweb-api-token -n maratea -o jsonpath='{.data.TIMEWEB_API_TOKEN}' 2>/dev/null | base64 -d)

if [ -z "$TIMEWEB_TOKEN" ]; then
    echo "❌ Ошибка: Не удалось получить TIMEWEB_API_TOKEN"
    exit 1
fi

echo "✅ Токен получен"
echo ""

# Проверка домена
echo "Проверка домена $DOMAIN..."
DOMAIN_INFO=$(curl -s -H "Authorization: Bearer $TIMEWEB_TOKEN" \
    -H "Accept: application/json" \
    "${TIMEWEB_API_BASE_URL}/domains" | \
    jq -r ".domains[] | select(.fqdn == \"$DOMAIN\")" 2>/dev/null)

if [ -z "$DOMAIN_INFO" ] || [ "$DOMAIN_INFO" = "null" ]; then
    echo "❌ Домен $DOMAIN не найден в аккаунте Timeweb Cloud"
    echo ""
    echo "Пожалуйста, настройте DNS записи вручную через панель управления Timeweb Cloud:"
    echo ""
    echo "1. Войдите в панель управления Timeweb Cloud"
    echo "2. Перейдите в раздел 'Домены' → $DOMAIN"
    echo "3. Откройте раздел 'DNS записи' или 'Управление DNS'"
    echo "4. Создайте следующие A записи:"
    echo ""
    echo "   Запись 1:"
    echo "   - Имя/Поддомен: argocd.staging"
    echo "   - Тип: A"
    echo "   - Значение: $EXTERNAL_IP"
    echo "   - TTL: 300"
    echo ""
    echo "   Запись 2:"
    echo "   - Имя/Поддомен: grafana.staging"
    echo "   - Тип: A"
    echo "   - Значение: $EXTERNAL_IP"
    echo "   - TTL: 300"
    echo ""
    echo "5. Сохраните изменения"
    echo ""
    exit 1
fi

DOMAIN_ID=$(echo "$DOMAIN_INFO" | jq -r '.id')
echo "✅ Домен найден (ID: $DOMAIN_ID)"
echo ""

# Проверка текущих DNS записей
echo "Проверка текущих DNS записей..."
echo ""

# Проверка через DNS
check_dns() {
    local subdomain=$1
    local full_domain="${subdomain}.${DOMAIN}"
    local result=$(dig +short "$full_domain" 2>/dev/null | head -1)
    
    if [ -n "$result" ] && [ "$result" = "$EXTERNAL_IP" ]; then
        echo "✅ $full_domain → $result (уже настроен)"
        return 0
    else
        echo "❌ $full_domain → не настроен"
        return 1
    fi
}

ARGOCD_EXISTS=$(check_dns "argocd.staging"; echo $?)
GRAFANA_EXISTS=$(check_dns "grafana.staging"; echo $?)

echo ""

# Если DNS уже настроен
if [ "$ARGOCD_EXISTS" = "0" ] && [ "$GRAFANA_EXISTS" = "0" ]; then
    echo "🎉 DNS записи уже настроены и работают!"
    echo ""
    echo "Следующие шаги:"
    echo "1. Cert-manager автоматически получит TLS сертификаты (5-10 минут)"
    echo "2. Проверка: kubectl get certificate -A"
    exit 0
fi

# Инструкции для ручной настройки
echo "=========================================="
echo "Инструкции по настройке DNS"
echo "=========================================="
echo ""
echo "DNS записи необходимо настроить вручную через панель управления Timeweb Cloud."
echo ""
echo "📋 Пошаговая инструкция:"
echo ""
echo "1. Откройте панель управления Timeweb Cloud:"
echo "   https://timeweb.cloud/domains"
echo ""
echo "2. Найдите домен '$DOMAIN' и откройте его"
echo ""
echo "3. Перейдите в раздел 'DNS записи' или 'Управление DNS'"
echo ""
echo "4. Создайте следующие A записи:"
echo ""
echo "   ┌─────────────────────────────────────────┐"
echo "   │ Запись 1: ArgoCD                        │"
echo "   ├─────────────────────────────────────────┤"
echo "   │ Имя/Поддомен: argocd.staging            │"
echo "   │ Тип: A                                  │"
echo "   │ Значение: $EXTERNAL_IP                  │"
echo "   │ TTL: 300                                │"
echo "   └─────────────────────────────────────────┘"
echo ""
echo "   ┌─────────────────────────────────────────┐"
echo "   │ Запись 2: Grafana                       │"
echo "   ├─────────────────────────────────────────┤"
echo "   │ Имя/Поддомен: grafana.staging           │"
echo "   │ Тип: A                                  │"
echo "   │ Значение: $EXTERNAL_IP                  │"
echo "   │ TTL: 300                                │"
echo "   └─────────────────────────────────────────┘"
echo ""
echo "5. Сохраните изменения"
echo ""
echo "6. После сохранения проверьте DNS (может занять несколько минут):"
echo "   dig +short argocd.staging.betaserver.ru"
echo "   dig +short grafana.staging.betaserver.ru"
echo ""
echo "7. После того как DNS начнет резолвиться, cert-manager автоматически"
echo "   получит TLS сертификаты (5-10 минут)"
echo ""
echo "=========================================="
echo "Альтернативный способ: через API"
echo "=========================================="
echo ""
echo "Если у вас есть доступ к API управления DNS, вы можете использовать:"
echo ""
echo "  curl -X POST 'https://api.timeweb.cloud/api/v1/domains/$DOMAIN_ID/dns' \\"
echo "    -H 'Authorization: Bearer YOUR_TOKEN' \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{"
echo "      \"subdomain\": \"argocd.staging\","
echo "      \"type\": \"A\","
echo "      \"content\": \"$EXTERNAL_IP\","
echo "      \"ttl\": 300"
echo "    }'"
echo ""
echo "Однако, API может не поддерживать управление DNS записями напрямую."
echo "В этом случае используйте панель управления."
echo ""
echo "=========================================="
echo "Проверка после настройки"
echo "=========================================="
echo ""
echo "После настройки DNS запустите:"
echo "  ./scripts/complete-phase1-setup.sh"
echo ""
echo "Этот скрипт проверит:"
echo "  - DNS резолюцию"
echo "  - TLS сертификаты"
echo "  - Доступность сервисов"
echo ""

