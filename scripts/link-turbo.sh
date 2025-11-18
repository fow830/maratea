#!/bin/bash
# Interactive script to link Turborepo to a team

set -e

echo "⚡ Привязка Turborepo к команде"
echo "================================"
echo ""

# Check if already linked
if [ -f .turbo/config.json ]; then
    echo "✅ Проект уже привязан к команде"
    cat .turbo/config.json | jq '.' 2>/dev/null || cat .turbo/config.json
    echo ""
    read -p "Хотите привязать к другой команде? (y/n): " RE_LINK
    if [ "$RE_LINK" != "y" ] && [ "$RE_LINK" != "Y" ]; then
        echo "Используется существующая привязка"
        exit 0
    fi
fi

echo "Выберите способ привязки:"
echo "1. Интерактивно (npx turbo link) - покажет список команд"
echo "2. По team slug (если знаете slug команды)"
echo ""
read -p "Выберите вариант (1 или 2): " CHOICE

if [ "$CHOICE" = "1" ]; then
    echo ""
    echo "Запускаю интерактивную привязку..."
    npx turbo link
elif [ "$CHOICE" = "2" ]; then
    echo ""
    read -p "Введите team slug (из URL: vercel.com/{team-slug}): " TEAM_SLUG
    if [ -n "$TEAM_SLUG" ]; then
        echo "Привязываю к команде: $TEAM_SLUG"
        npx turbo link --scope "$TEAM_SLUG"
    else
        echo "❌ Team slug не указан"
        exit 1
    fi
else
    echo "❌ Неверный выбор"
    exit 1
fi

echo ""
echo "✅ Привязка выполнена!"
echo ""
echo "Проверяю конфигурацию..."
if [ -f .turbo/config.json ]; then
    echo "Конфигурация:"
    cat .turbo/config.json | jq '.' 2>/dev/null || cat .turbo/config.json
    echo ""
    echo "Хотите обновить GitHub Secrets? (y/n)"
    read -p "> " UPDATE_SECRETS
    if [ "$UPDATE_SECRETS" = "y" ] || [ "$UPDATE_SECRETS" = "Y" ]; then
        ./scripts/update-turbo-secrets.sh
    fi
else
    echo "⚠️  Конфигурация не найдена в .turbo/config.json"
    echo "Проверьте ~/.turbo/config.json"
fi

