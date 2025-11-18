#!/bin/bash

# Полностью автоматизированный скрипт для завершения Phase 1
# Выполняет все возможные автоматические задачи

set -e

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"
EXTERNAL_IP="62.76.233.233"

echo "=========================================="
echo "Автоматическое завершение Phase 1"
echo "=========================================="
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Шаг 1: Применение PostgreSQL backup с S3 (если секрет уже заполнен)
echo "Шаг 1: Применение PostgreSQL backup с S3"
echo "------------------------------------------"

if kubectl get secret s3-backup-secret -n maratea &>/dev/null; then
    S3_ENDPOINT=$(kubectl get secret s3-backup-secret -n maratea -o jsonpath='{.data.S3_ENDPOINT}' | base64 -d 2>/dev/null || echo "")
    
    if [ -n "$S3_ENDPOINT" ] && [ "$S3_ENDPOINT" != "YOUR_ACCESS_KEY" ] && [ "$S3_ENDPOINT" != "s3.timeweb.cloud" ]; then
        echo "✅ S3 secret заполнен, применяю backup CronJob..."
        kubectl apply -f infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml
        echo "✅ PostgreSQL backup с S3 применен"
    else
        echo "⚠️  S3 secret содержит placeholder значения"
        echo "   Требуется заполнение реальными credentials"
        echo "   Используйте: kubectl edit secret s3-backup-secret -n maratea"
    fi
else
    echo "⚠️  S3 secret не создан"
    echo "   Создайте S3 bucket и секрет перед применением backup"
fi

# Шаг 2: Проверка и применение всех манифестов
echo ""
echo "Шаг 2: Проверка манифестов"
echo "------------------------------------------"

# Проверка всех необходимых ресурсов
RESOURCES_OK=true

# Проверка Ingress
if ! kubectl get ingress argocd-server -n argocd &>/dev/null; then
    echo "⚠️  Ingress для ArgoCD не найден, применяю..."
    kubectl apply -f infrastructure/kubernetes/argocd/ingress.yaml
fi

if ! kubectl get ingress grafana -n observability &>/dev/null; then
    echo "⚠️  Ingress для Grafana не найден, применяю..."
    kubectl apply -f infrastructure/kubernetes/monitoring/grafana-ingress.yaml
fi

# Проверка Certificate
if ! kubectl get certificate argocd-server-tls -n argocd &>/dev/null; then
    echo "⚠️  Certificate для ArgoCD не найден, применяю..."
    kubectl apply -f infrastructure/kubernetes/argocd/certificate.yaml
fi

if ! kubectl get certificate grafana-tls -n observability &>/dev/null; then
    echo "⚠️  Certificate для Grafana не найден, применяю..."
    kubectl apply -f infrastructure/kubernetes/monitoring/grafana-certificate.yaml
fi

echo "✅ Все манифесты применены"

# Шаг 3: Проверка DNS и сертификатов
echo ""
echo "Шаг 3: Проверка DNS и сертификатов"
echo "------------------------------------------"

check_dns() {
    local domain=$1
    local result=$(dig +short "$domain" 2>/dev/null | head -1)
    if [ -n "$result" ] && [ "$result" = "$EXTERNAL_IP" ]; then
        echo "✅ $domain → $result"
        return 0
    else
        echo "❌ $domain не настроен (ожидается: $EXTERNAL_IP)"
        return 1
    fi
}

ARGOCD_DNS=$(check_dns "argocd.staging.betaserver.ru"; echo $?)
GRAFANA_DNS=$(check_dns "grafana.staging.betaserver.ru"; echo $?)

if [ "$ARGOCD_DNS" = "0" ] && [ "$GRAFANA_DNS" = "0" ]; then
    echo ""
    echo "✅ DNS настроен, проверяю сертификаты..."
    
    # Ждем получения сертификатов (максимум 2 минуты)
    echo "Ожидание получения TLS сертификатов..."
    for i in {1..24}; do
        ARGOCD_CERT=$(kubectl get certificate argocd-server-tls -n argocd -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
        GRAFANA_CERT=$(kubectl get certificate grafana-tls -n observability -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
        
        if [ "$ARGOCD_CERT" = "True" ] && [ "$GRAFANA_CERT" = "True" ]; then
            echo "✅ Все сертификаты получены!"
            break
        fi
        
        if [ $i -lt 24 ]; then
            sleep 5
            echo "   Ожидание... ($i/24)"
        fi
    done
else
    echo ""
    echo "⚠️  DNS не настроен. После настройки DNS сертификаты получатся автоматически."
fi

# Шаг 4: Финальная проверка
echo ""
echo "Шаг 4: Финальная проверка"
echo "------------------------------------------"

./scripts/complete-phase1-setup.sh

echo ""
echo "=========================================="
echo "Автоматическая настройка завершена"
echo "=========================================="

