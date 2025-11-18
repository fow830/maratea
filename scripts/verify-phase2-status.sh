#!/bin/bash

set -e

echo "=========================================="
echo "Проверка статуса Phase 2"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if KUBECONFIG is set
if [ -z "$KUBECONFIG" ]; then
  echo -e "${YELLOW}⚠️  KUBECONFIG не установлен${NC}"
  echo "Установите: export KUBECONFIG=/path/to/kubeconfig"
  exit 1
fi

echo "Шаг 1: Проверка DNS"
echo "----------------------------------------"
APP_DNS=$(dig +short app.staging.betaserver.ru 2>/dev/null || echo "")
LANDING_DNS=$(dig +short staging.betaserver.ru 2>/dev/null || echo "")

if [ "$APP_DNS" = "62.76.233.233" ]; then
  echo -e "${GREEN}✅ app.staging.betaserver.ru → $APP_DNS${NC}"
else
  echo -e "${RED}❌ app.staging.betaserver.ru → $APP_DNS (ожидается: 62.76.233.233)${NC}"
fi

if [ "$LANDING_DNS" = "62.76.233.233" ]; then
  echo -e "${GREEN}✅ staging.betaserver.ru → $LANDING_DNS${NC}"
else
  echo -e "${RED}❌ staging.betaserver.ru → $LANDING_DNS (ожидается: 62.76.233.233)${NC}"
fi

echo ""
echo "Шаг 2: Проверка TLS сертификатов"
echo "----------------------------------------"
APP_CERT=$(kubectl get certificate app-tls -n maratea -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "NotFound")
LANDING_CERT=$(kubectl get certificate landing-tls -n maratea -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "NotFound")

if [ "$APP_CERT" = "True" ]; then
  echo -e "${GREEN}✅ app-tls сертификат готов${NC}"
elif [ "$APP_CERT" = "NotFound" ]; then
  echo -e "${YELLOW}⚠️  app-tls сертификат не найден${NC}"
else
  echo -e "${YELLOW}⏳ app-tls сертификат в процессе получения${NC}"
fi

if [ "$LANDING_CERT" = "True" ]; then
  echo -e "${GREEN}✅ landing-tls сертификат готов${NC}"
elif [ "$LANDING_CERT" = "NotFound" ]; then
  echo -e "${YELLOW}⚠️  landing-tls сертификат не найден${NC}"
else
  echo -e "${YELLOW}⏳ landing-tls сертификат в процессе получения${NC}"
fi

echo ""
echo "Шаг 3: Проверка Deployments"
echo "----------------------------------------"
APP_DEPLOY=$(kubectl get deployment app -n maratea -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' 2>/dev/null || echo "NotFound")
LANDING_DEPLOY=$(kubectl get deployment landing -n maratea -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' 2>/dev/null || echo "NotFound")

if [ "$APP_DEPLOY" = "2/2" ]; then
  echo -e "${GREEN}✅ app deployment: $APP_DEPLOY готов${NC}"
elif [ "$APP_DEPLOY" = "NotFound" ]; then
  echo -e "${YELLOW}⚠️  app deployment не найден${NC}"
else
  echo -e "${YELLOW}⏳ app deployment: $APP_DEPLOY${NC}"
fi

if [ "$LANDING_DEPLOY" = "1/1" ]; then
  echo -e "${GREEN}✅ landing deployment: $LANDING_DEPLOY готов${NC}"
elif [ "$LANDING_DEPLOY" = "NotFound" ]; then
  echo -e "${YELLOW}⚠️  landing deployment не найден${NC}"
else
  echo -e "${YELLOW}⏳ landing deployment: $LANDING_DEPLOY${NC}"
fi

echo ""
echo "Шаг 4: Проверка Ingress"
echo "----------------------------------------"
APP_INGRESS=$(kubectl get ingress app -n maratea -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "NotFound")
LANDING_INGRESS=$(kubectl get ingress landing -n maratea -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "NotFound")

if [ -n "$APP_INGRESS" ] && [ "$APP_INGRESS" != "NotFound" ]; then
  echo -e "${GREEN}✅ app ingress настроен${NC}"
else
  echo -e "${YELLOW}⚠️  app ingress не найден${NC}"
fi

if [ -n "$LANDING_INGRESS" ] && [ "$LANDING_INGRESS" != "NotFound" ]; then
  echo -e "${GREEN}✅ landing ingress настроен${NC}"
else
  echo -e "${YELLOW}⚠️  landing ingress не найден${NC}"
fi

echo ""
echo "Шаг 5: Проверка доступности (если DNS настроен)"
echo "----------------------------------------"
if [ "$APP_DNS" = "62.76.233.233" ]; then
  APP_HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://app.staging.betaserver.ru 2>/dev/null || echo "000")
  if [ "$APP_HTTP" = "200" ]; then
    echo -e "${GREEN}✅ app.staging.betaserver.ru доступен (HTTP $APP_HTTP)${NC}"
  else
    echo -e "${YELLOW}⚠️  app.staging.betaserver.ru вернул HTTP $APP_HTTP${NC}"
  fi
else
  echo -e "${YELLOW}⏳ app.staging.betaserver.ru - DNS не настроен${NC}"
fi

if [ "$LANDING_DNS" = "62.76.233.233" ]; then
  LANDING_HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://staging.betaserver.ru 2>/dev/null || echo "000")
  if [ "$LANDING_HTTP" = "200" ]; then
    echo -e "${GREEN}✅ staging.betaserver.ru доступен (HTTP $LANDING_HTTP)${NC}"
  else
    echo -e "${YELLOW}⚠️  staging.betaserver.ru вернул HTTP $LANDING_HTTP${NC}"
  fi
else
  echo -e "${YELLOW}⏳ staging.betaserver.ru - DNS не настроен${NC}"
fi

echo ""
echo "=========================================="
echo "Итоговый отчет"
echo "=========================================="
echo ""
echo "Для доступа к приложениям:"
echo ""
echo "  App:"
echo "    https://app.staging.betaserver.ru"
echo ""
echo "  Landing:"
echo "    https://staging.betaserver.ru"
echo ""
echo "  API Gateway:"
echo "    https://api.staging.betaserver.ru"
echo ""
echo "Проверка статуса deployments:"
echo "  kubectl get pods -n maratea"
echo "  kubectl get deployments -n maratea"
echo ""

