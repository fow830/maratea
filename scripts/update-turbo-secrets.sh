#!/bin/bash
# Script to update GitHub Secrets after turbo link

set -e

echo "⚡ Обновление GitHub Secrets для Turborepo"
echo "=========================================="
echo ""

# Check if config exists
if [ ! -f ~/.turbo/config.json ]; then
    echo "❌ Конфигурация Turborepo не найдена"
    echo "   Выполните сначала: npx turbo link"
    exit 1
fi

echo "✅ Конфигурация найдена"
echo ""

# Try to extract team ID and token
TEAM_ID=$(cat ~/.turbo/config.json | jq -r '.teamId' 2>/dev/null || echo "")
TOKEN=$(cat ~/.turbo/config.json | jq -r '.token' 2>/dev/null || echo "")

if [ -z "$TEAM_ID" ] || [ "$TEAM_ID" = "null" ]; then
    echo "⚠️  Team ID не найден в конфигурации"
    echo "   Конфигурация:"
    cat ~/.turbo/config.json
    echo ""
    read -p "Введите Team ID (slug) вручную: " TEAM_ID
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "⚠️  Токен не найден в конфигурации"
    echo "   Получите токен из Vercel Dashboard:"
    echo "   https://vercel.com/dashboard → Settings → Access Tokens"
    echo ""
    read -p "Введите TURBO_TOKEN: " TOKEN
fi

if [ -z "$TEAM_ID" ] || [ -z "$TOKEN" ]; then
    echo "❌ Team ID и/или токен не указаны"
    exit 1
fi

echo ""
echo "Обновляю GitHub Secrets..."
echo "  TURBO_TEAM: $TEAM_ID"
echo "  TURBO_TOKEN: ${TOKEN:0:10}..." # Show first 10 chars only

# Update TURBO_TEAM
if gh secret set TURBO_TEAM --body "$TEAM_ID" 2>/dev/null; then
    echo "  ✅ TURBO_TEAM обновлен"
else
    echo "  ❌ Ошибка обновления TURBO_TEAM"
    echo "  Выполните вручную:"
    echo "    gh secret set TURBO_TEAM --body \"$TEAM_ID\""
fi

# Update TURBO_TOKEN
if gh secret set TURBO_TOKEN --body "$TOKEN" 2>/dev/null; then
    echo "  ✅ TURBO_TOKEN обновлен"
else
    echo "  ❌ Ошибка обновления TURBO_TOKEN"
    echo "  Выполните вручную:"
    echo "    gh secret set TURBO_TOKEN --body \"$TOKEN\""
fi

echo ""
echo "✅ Готово!"
echo ""
echo "Проверка:"
gh secret list | grep TURBO

echo ""
echo "Тестирование remote cache:"
echo "  pnpm turbo build"
echo "  (при повторной сборке должно показать [REMOTE CACHE HIT])"

