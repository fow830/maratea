#!/bin/bash
# Скрипт для настройки DNS записи для api.staging.betaserver.ru
# Использование: ./scripts/setup-dns-betaserver.sh

set -euo pipefail

INGRESS_IP="62.76.233.233"
DOMAIN="api.staging.betaserver.ru"

echo "=== Настройка DNS для $DOMAIN ==="
echo ""
echo "Внешний IP балансировщика: $INGRESS_IP"
echo ""
echo "Необходимо создать DNS запись:"
echo "  Тип: A"
echo "  Имя: api.staging"
echo "  Значение: $INGRESS_IP"
echo "  TTL: 300 (или меньше)"
echo ""
echo "Или если используется поддомен:"
echo "  Тип: A"
echo "  Имя: api.staging.betaserver.ru"
echo "  Значение: $INGRESS_IP"
echo "  TTL: 300"
echo ""
echo "После создания DNS записи, проверьте:"
echo "  dig +short $DOMAIN"
echo "  curl -I http://$DOMAIN/health"
echo ""
echo "TLS сертификат будет автоматически получен cert-manager после настройки DNS."

