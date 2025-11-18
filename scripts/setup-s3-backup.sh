#!/bin/bash

# Интерактивный скрипт для настройки S3 backup
# Использование: ./scripts/setup-s3-backup.sh

set -e

echo "=========================================="
echo "Настройка S3 Backup для PostgreSQL и Redis"
echo "=========================================="
echo ""

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Ошибка: kubectl не установлен"
    exit 1
fi

# Проверка KUBECONFIG
if [ -z "$KUBECONFIG" ]; then
    echo "Предупреждение: KUBECONFIG не установлен"
    echo "Используйте: export KUBECONFIG=/path/to/kubeconfig"
    read -p "Продолжить? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Шаг 1: Создание S3 bucket в Timeweb Cloud"
echo "------------------------------------------"
echo "1. Войдите в панель управления Timeweb Cloud"
echo "2. Перейдите в раздел 'Object Storage' (S3)"
echo "3. Создайте новый bucket:"
echo "   - Имя: maratea-backups"
echo "   - Регион: ru-1 (Санкт-Петербург)"
echo "   - Версионирование: Включить (рекомендуется)"
echo ""
read -p "Нажмите Enter после создания bucket..."

echo ""
echo "Шаг 2: Ввод S3 credentials"
echo "------------------------------------------"
read -p "S3 Endpoint (по умолчанию: s3.timeweb.cloud): " S3_ENDPOINT
S3_ENDPOINT=${S3_ENDPOINT:-s3.timeweb.cloud}

read -p "S3 Access Key: " S3_ACCESS_KEY
if [ -z "$S3_ACCESS_KEY" ]; then
    echo "Ошибка: Access Key обязателен"
    exit 1
fi

read -sp "S3 Secret Key: " S3_SECRET_KEY
echo
if [ -z "$S3_SECRET_KEY" ]; then
    echo "Ошибка: Secret Key обязателен"
    exit 1
fi

read -p "S3 Bucket (по умолчанию: maratea-backups): " S3_BUCKET
S3_BUCKET=${S3_BUCKET:-maratea-backups}

read -p "S3 Region (по умолчанию: ru-1): " S3_REGION
S3_REGION=${S3_REGION:-ru-1}

echo ""
echo "Шаг 3: Создание секрета в Kubernetes"
echo "------------------------------------------"

kubectl create secret generic s3-backup-secret \
  --namespace maratea \
  --from-literal=S3_ENDPOINT="$S3_ENDPOINT" \
  --from-literal=S3_ACCESS_KEY="$S3_ACCESS_KEY" \
  --from-literal=S3_SECRET_KEY="$S3_SECRET_KEY" \
  --from-literal=S3_BUCKET="$S3_BUCKET" \
  --from-literal=S3_REGION="$S3_REGION" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Секрет s3-backup-secret создан/обновлен"

echo ""
echo "Шаг 4: Применение PostgreSQL backup с S3"
echo "------------------------------------------"

if [ -f "infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml" ]; then
    kubectl apply -f infrastructure/kubernetes/postgres/backup-cronjob-s3.yaml
    echo "✅ PostgreSQL backup с S3 применен"
else
    echo "⚠️  Файл backup-cronjob-s3.yaml не найден"
fi

echo ""
echo "Шаг 5: Тестирование подключения к S3"
echo "------------------------------------------"
echo "Проверка доступности S3 bucket..."

# Проверка через kubectl run (временный pod)
kubectl run s3-test --rm -i --restart=Never \
  --namespace maratea \
  --image=amazon/aws-cli:latest \
  --env="AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY" \
  --env="AWS_SECRET_ACCESS_KEY=$S3_SECRET_KEY" \
  --env="AWS_DEFAULT_REGION=$S3_REGION" \
  -- sh -c "aws --endpoint-url=https://$S3_ENDPOINT s3 ls s3://$S3_BUCKET/ || echo 'Bucket пуст или недоступен'"

echo ""
echo "=========================================="
echo "Настройка завершена!"
echo "=========================================="
echo ""
echo "Следующие шаги:"
echo "1. Проверьте статус CronJob:"
echo "   kubectl get cronjob -n maratea"
echo ""
echo "2. Запустите тестовый backup:"
echo "   kubectl create job --from=cronjob/postgres-backup-s3 postgres-backup-test-\$(date +%s) -n maratea"
echo ""
echo "3. Проверьте логи:"
echo "   kubectl logs -n maratea job/postgres-backup-test-<timestamp>"
echo ""
echo "4. Проверьте backup'ы в S3:"
echo "   aws --endpoint-url=https://$S3_ENDPOINT s3 ls s3://$S3_BUCKET/postgres/"

