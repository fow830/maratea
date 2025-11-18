#!/bin/bash
# Автоматическая настройка GitHub Secrets

set -e

echo "🔐 Автоматическая настройка GitHub Secrets"
echo "=========================================="
echo ""

REPO="fow830/maratea"

# Проверка GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI не установлен"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "❌ Не аутентифицирован в GitHub CLI"
    exit 1
fi

echo "✅ GitHub CLI доступен"
echo ""

# 1. TURBO_TOKEN
echo "1. Настройка TURBO_TOKEN..."
if gh secret list | grep -q "TURBO_TOKEN"; then
    echo "   ⚠️  TURBO_TOKEN уже установлен"
else
    echo "   Для получения токена выполните:"
    echo "   npx turbo login"
    echo ""
    read -p "   Введите Turborepo токен (или нажмите Enter чтобы пропустить): " TURBO_TOKEN
    if [ -n "$TURBO_TOKEN" ]; then
        echo "$TURBO_TOKEN" | gh secret set TURBO_TOKEN --body-file -
        echo "   ✅ TURBO_TOKEN установлен"
    else
        echo "   ⚠️  TURBO_TOKEN пропущен"
    fi
fi

echo ""

# 2. TURBO_TEAM
echo "2. Настройка TURBO_TEAM..."
if gh secret list | grep -q "TURBO_TEAM"; then
    echo "   ⚠️  TURBO_TEAM уже установлен"
else
    read -p "   Введите название команды Turborepo (или нажмите Enter чтобы пропустить): " TURBO_TEAM
    if [ -n "$TURBO_TEAM" ]; then
        echo "$TURBO_TEAM" | gh secret set TURBO_TEAM --body-file -
        echo "   ✅ TURBO_TEAM установлен"
    else
        echo "   ⚠️  TURBO_TEAM пропущен"
    fi
fi

echo ""

# 3. KUBECONFIG
echo "3. Настройка KUBECONFIG..."
if gh secret list | grep -q "KUBECONFIG"; then
    echo "   ⚠️  KUBECONFIG уже установлен"
else
    if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null 2>&1; then
        echo "   Получаю kubeconfig из текущего кластера..."
        KUBECONFIG_B64=$(kubectl config view --flatten 2>/dev/null | base64 | tr -d '\n')
        if [ -n "$KUBECONFIG_B64" ] && [ ${#KUBECONFIG_B64} -gt 100 ]; then
            echo "$KUBECONFIG_B64" | gh secret set KUBECONFIG --body-file -
            echo "   ✅ KUBECONFIG установлен из текущего кластера"
        else
            echo "   ⚠️  Не удалось получить KUBECONFIG"
        fi
    else
        echo "   ⚠️  Kubernetes кластер не доступен"
        echo "   Для ручной настройки выполните:"
        echo "   kubectl config view --flatten | base64 | gh secret set KUBECONFIG --body-file -"
    fi
fi

echo ""
echo "✅ Настройка завершена!"
echo ""
echo "Установленные secrets:"
gh secret list
