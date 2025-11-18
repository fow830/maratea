#!/bin/bash
# Script to get Turborepo tokens and update GitHub Secrets

set -e

echo "⚡ Получение Turborepo токенов"
echo "==============================="
echo ""

# Check if turbo is available
if ! command -v npx &> /dev/null; then
    echo "❌ npx не найден"
    exit 1
fi

echo "1. Проверка авторизации..."
if npx turbo login --check 2>/dev/null; then
    echo "   ✅ Уже авторизован"
else
    echo "   ⚠️  Не авторизован"
    echo ""
    echo "   Выполните авторизацию:"
    echo "   npx turbo login"
    echo ""
    read -p "Нажмите Enter после авторизации..."
fi

echo ""
echo "2. Проверка привязки к команде..."
TEAM_INFO=$(npx turbo link --dry-run 2>&1 || echo "")

if [ -f ~/.turbo/config.json ]; then
    echo "   Конфигурация найдена:"
    cat ~/.turbo/config.json | jq '.' 2>/dev/null || cat ~/.turbo/config.json
    echo ""
    
    # Try to extract team ID
    TEAM_ID=$(cat ~/.turbo/config.json | jq -r '.teamId' 2>/dev/null || echo "")
    if [ -n "$TEAM_ID" ] && [ "$TEAM_ID" != "null" ] && [ -n "$TEAM_ID" ]; then
        echo "   ✅ Team ID найден: $TEAM_ID"
    else
        echo "   ⚠️  Team ID не найден в конфигурации"
        echo "   Team ID - это slug команды из URL: https://vercel.com/{team-slug}"
        echo "   Или выполните: npx turbo link --team <your-team-slug>"
        read -p "Введите Team ID (slug): " TEAM_ID
    fi
else
    echo "   ⚠️  Конфигурация не найдена"
    echo "   Выполните: npx turbo link --team <your-team-id>"
    read -p "Введите Team ID: " TEAM_ID
fi

echo ""
echo "3. Получение токена..."
echo "   Согласно документации Turborepo:"
echo "   - Токен создается через Vercel Dashboard"
echo "   - Зайдите на https://vercel.com/dashboard"
echo "   - Settings > Access Tokens > Create Token"
echo "   - Скопируйте токен (показывается только один раз!)"
echo ""
echo "   Или используйте команду:"
echo "   npx turbo login"
echo "   (токен будет сохранен автоматически)"
echo ""

read -p "Введите TURBO_TOKEN (или нажмите Enter для пропуска): " TURBO_TOKEN

if [ -n "$TURBO_TOKEN" ]; then
    echo ""
    echo "4. Обновление GitHub Secrets..."
    
    # Update TURBO_TOKEN
    if gh secret set TURBO_TOKEN --body "$TURBO_TOKEN" 2>/dev/null; then
        echo "   ✅ TURBO_TOKEN обновлен"
    else
        echo "   ❌ Ошибка обновления TURBO_TOKEN"
        echo "   Выполните вручную:"
        echo "   gh secret set TURBO_TOKEN --body \"$TURBO_TOKEN\""
    fi
    
    # Update TURBO_TEAM
    if [ -n "$TEAM_ID" ]; then
        if gh secret set TURBO_TEAM --body "$TEAM_ID" 2>/dev/null; then
            echo "   ✅ TURBO_TEAM обновлен: $TEAM_ID"
        else
            echo "   ❌ Ошибка обновления TURBO_TEAM"
            echo "   Выполните вручную:"
            echo "   gh secret set TURBO_TEAM --body \"$TEAM_ID\""
        fi
    else
        echo "   ⚠️  TURBO_TEAM не обновлен (Team ID не указан)"
    fi
    
    echo ""
    echo "✅ Настройка завершена!"
    echo ""
    echo "Проверка:"
    echo "  gh secret list | grep TURBO"
else
    echo ""
    echo "⚠️  Токен не введен. Обновите секреты вручную:"
    echo "  gh secret set TURBO_TOKEN --body \"ваш_токен\""
    if [ -n "$TEAM_ID" ]; then
        echo "  gh secret set TURBO_TEAM --body \"$TEAM_ID\""
    fi
fi

echo ""
echo "📚 Документация: https://turborepo.com/docs/core-concepts/remote-caching"

