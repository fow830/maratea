#!/bin/bash
# Script to help get Vercel token for Turborepo

echo "⚡ Получение токена Vercel для Turborepo"
echo "========================================="
echo ""
echo "Токен можно получить двумя способами:"
echo ""
echo "Способ 1 (через веб-интерфейс):"
echo "  1. Откройте: https://vercel.com/dashboard"
echo "  2. Settings → Tokens → Create Token"
echo "  3. Скопируйте токен"
echo ""
echo "Способ 2 (через Vercel CLI):"
echo "  1. Установите: npm install -g vercel"
echo "  2. Выполните: vercel login"
echo "  3. Выполните: vercel tokens create 'Turborepo'"
echo ""
read -p "Введите токен (или нажмите Enter для пропуска): " TOKEN

if [ -n "$TOKEN" ]; then
    echo ""
    echo "Обновляю GitHub Secret..."
    if gh secret set TURBO_TOKEN --body "$TOKEN" 2>/dev/null; then
        echo "✅ TURBO_TOKEN обновлен"
        echo ""
        echo "Проверка:"
        gh secret list | grep TURBO
    else
        echo "❌ Ошибка обновления TURBO_TOKEN"
        echo "Выполните вручную:"
        echo "  gh secret set TURBO_TOKEN --body \"$TOKEN\""
    fi
else
    echo ""
    echo "Токен не введен. Обновите секрет вручную:"
    echo "  gh secret set TURBO_TOKEN --body \"ваш_токен\""
fi
