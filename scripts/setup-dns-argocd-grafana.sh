#!/bin/bash

# Скрипт для настройки DNS записей для ArgoCD и Grafana
# Использование: ./scripts/setup-dns-argocd-grafana.sh

set -e

EXTERNAL_IP="62.76.233.233"

echo "=========================================="
echo "Настройка DNS для ArgoCD и Grafana"
echo "=========================================="
echo ""
echo "Внешний IP балансировщика: $EXTERNAL_IP"
echo ""
echo "Необходимо создать следующие DNS записи типа A:"
echo ""
echo "1. argocd.staging.betaserver.ru → $EXTERNAL_IP"
echo "2. grafana.staging.betaserver.ru → $EXTERNAL_IP"
echo ""
echo "Инструкции:"
echo "1. Откройте панель управления DNS для домена betaserver.ru"
echo "2. Создайте новую запись типа A для каждого поддомена:"
echo ""
echo "   Для ArgoCD:"
echo "   - Имя/Хост: argocd.staging"
echo "   - Тип: A"
echo "   - Значение/IP: $EXTERNAL_IP"
echo "   - TTL: 300 (или меньше для быстрого обновления)"
echo ""
echo "   Для Grafana:"
echo "   - Имя/Хост: grafana.staging"
echo "   - Тип: A"
echo "   - Значение/IP: $EXTERNAL_IP"
echo "   - TTL: 300 (или меньше для быстрого обновления)"
echo ""
echo "3. Сохраните изменения"
echo ""
echo "Проверка DNS (после сохранения):"
echo "  dig +short argocd.staging.betaserver.ru"
echo "  dig +short grafana.staging.betaserver.ru"
echo ""
echo "Ожидаемый результат: $EXTERNAL_IP"
echo ""
echo "После настройки DNS cert-manager автоматически получит TLS сертификаты."
echo "Проверка сертификатов:"
echo "  kubectl get certificate -n argocd"
echo "  kubectl get certificate -n observability"

