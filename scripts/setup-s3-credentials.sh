#!/bin/bash

# Автоматическая настройка S3 credentials в Kubernetes
# Использование: ./scripts/setup-s3-credentials.sh

set -e

KUBECONFIG_PATH="${KUBECONFIG:-./copypast/twc-cute-grosbeak-config.yaml}"

echo "=========================================="
echo "Настройка S3 credentials для backup'ов"
echo "=========================================="
echo ""

# Проверка KUBECONFIG
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "Ошибка: KUBECONFIG не найден: $KUBECONFIG_PATH"
    exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

# Запрос данных от пользователя
echo "Введите данные из раздела 'Подключение' вашего S3 bucket:"
echo ""

# S3 URL
read -p "S3 URL (например: https://s3.twcstorage.ru): " S3_ENDPOINT
S3_ENDPOINT=${S3_ENDPOINT:-https://s3.twcstorage.ru}

# Bucket name
read -p "Название бакета (Bucket Name): " S3_BUCKET
if [ -z "$S3_BUCKET" ]; then
    echo "❌ Ошибка: Название бакета обязательно"
    exit 1
fi

# Access Key
read -p "S3 Access Key: " S3_ACCESS_KEY
if [ -z "$S3_ACCESS_KEY" ]; then
    echo "❌ Ошибка: S3 Access Key обязателен"
    exit 1
fi

# Secret Key
read -sp "S3 Secret Access Key: " S3_SECRET_KEY
echo ""
if [ -z "$S3_SECRET_KEY" ]; then
    echo "❌ Ошибка: S3 Secret Access Key обязателен"
    exit 1
fi

# Region
read -p "Регион (например: ru-1): " S3_REGION
S3_REGION=${S3_REGION:-ru-1}

# Удаление https:// из endpoint если есть
S3_ENDPOINT_CLEAN=$(echo "$S3_ENDPOINT" | sed 's|https\?://||')

echo ""
echo "=========================================="
echo "Проверка введенных данных"
echo "=========================================="
echo "S3 Endpoint: $S3_ENDPOINT_CLEAN"
echo "Bucket Name: $S3_BUCKET"
echo "Access Key: ${S3_ACCESS_KEY:0:10}..."
echo "Secret Key: ${S3_SECRET_KEY:0:10}..."
echo "Region: $S3_REGION"
echo ""

read -p "Все данные верны? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Отменено"
    exit 0
fi

echo ""
echo "Создание/обновление секрета в Kubernetes..."

# Создание или обновление секрета
kubectl create secret generic s3-backup-secret \
    --namespace maratea \
    --from-literal=S3_ENDPOINT="$S3_ENDPOINT_CLEAN" \
    --from-literal=S3_ACCESS_KEY="$S3_ACCESS_KEY" \
    --from-literal=S3_SECRET_KEY="$S3_SECRET_KEY" \
    --from-literal=S3_BUCKET="$S3_BUCKET" \
    --from-literal=S3_REGION="$S3_REGION" \
    --dry-run=client -o yaml | kubectl apply -f -

if [ $? -eq 0 ]; then
    echo "✅ Секрет s3-backup-secret успешно создан/обновлен"
else
    echo "❌ Ошибка при создании секрета"
    exit 1
fi

echo ""
echo "Проверка секрета..."
kubectl get secret s3-backup-secret -n maratea

echo ""
echo "=========================================="
echo "Следующие шаги"
echo "=========================================="
echo ""
echo "1. Применить PostgreSQL backup CronJob:"
echo "   kubectl apply -f infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml"
echo ""
echo "2. Протестировать backup:"
echo "   kubectl create job --from=cronjob/postgres-backup-s3 postgres-backup-test-\$(date +%s) -n maratea"
echo ""
echo "3. Проверить логи:"
echo "   kubectl logs -n maratea job/postgres-backup-test-<timestamp>"
echo ""
echo "4. Проверить backup в S3:"
echo "   aws --endpoint-url=https://$S3_ENDPOINT_CLEAN s3 ls s3://$S3_BUCKET/postgres/"
echo ""

