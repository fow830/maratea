#!/bin/bash
# Auto-update GitHub Secrets for Turborepo

set -e

echo "⚡ Автоматическое обновление GitHub Secrets"
echo "==========================================="
echo ""

TEAM_ID="fow830"
echo "Используется Team ID: $TEAM_ID"

# Try to get token from various locations
TOKEN=""
if [ -f ~/.turbo/config.json ]; then
    TOKEN=$(cat ~/.turbo/config.json | jq -r '.token' 2>/dev/null || echo "")
fi

if [ -z "$TOKEN" ] && [ -f .turbo/config.json ]; then
    TOKEN=$(cat .turbo/config.json | jq -r '.token' 2>/dev/null || echo "")
fi

if [ -z "$TOKEN" ]; then
    echo "⚠️  Токен не найден в конфигурации"
    echo "   Токен будет получен из Vercel Dashboard"
    echo "   Или создайте токен через: https://vercel.com/dashboard → Settings → Tokens"
    echo ""
    echo "   Для продолжения введите токен вручную или нажмите Enter для пропуска"
    read -p "TURBO_TOKEN: " TOKEN
fi

if [ -n "$TEAM_ID" ]; then
    echo ""
    echo "Обновляю GitHub Secrets..."
    echo "  TURBO_TEAM: $TEAM_ID"
    
    if gh secret set TURBO_TEAM --body "$TEAM_ID" 2>/dev/null; then
        echo "  ✅ TURBO_TEAM обновлен"
    else
        echo "  ❌ Ошибка обновления TURBO_TEAM"
    fi
fi

if [ -n "$TOKEN" ]; then
    echo "  TURBO_TOKEN: ${TOKEN:0:10}..."
    
    if gh secret set TURBO_TOKEN --body "$TOKEN" 2>/dev/null; then
        echo "  ✅ TURBO_TOKEN обновлен"
    else
        echo "  ❌ Ошибка обновления TURBO_TOKEN"
    fi
else
    echo "  ⚠️  TURBO_TOKEN не обновлен (токен не указан)"
fi

echo ""
echo "Проверка:"
gh secret list | grep TURBO || echo "Секреты не найдены"
