# Setup Guide - Maratea Platform

## Первоначальная настройка

### 1. Установка зависимостей

```bash
pnpm install
```

### 2. Настройка переменных окружения

Скопируйте `.env.example` файлы в соответствующие директории:

```bash
# Root
cp .env.example .env

# API Gateway
cp services/api-gateway/.env.example services/api-gateway/.env

# Shared (для Prisma)
cp shared/.env.example shared/.env

# App
cp app/.env.example app/.env

# Landing
cp landing/.env.example landing/.env
```

### 3. Инициализация Husky

Husky автоматически инициализируется при `pnpm install` благодаря скрипту `prepare`.

Если нужно инициализировать вручную:
```bash
pnpm exec husky install
```

### 4. Запуск Docker Compose

```bash
make docker-up
# или
docker compose up -d
```

Проверьте, что сервисы запущены:
```bash
docker compose ps
```

### 5. Настройка Prisma (опционально)

Если нужно создать миграции:

```bash
cd shared
npx prisma migrate dev --name init
```

### 6. Запуск в режиме разработки

```bash
# Все сервисы
make dev

# Или отдельно
cd services/api-gateway
pnpm dev
```

## Проверка работоспособности

### API Gateway Health Check

```bash
curl http://localhost:8080/health
```

Ожидаемый ответ:
```json
{
  "status": "healthy",
  "service": "api-gateway",
  "timestamp": "..."
}
```

### PostgreSQL

```bash
docker compose exec postgres psql -U maratea_user -d maratea_platform -c "SELECT version();"
```

### Redis

```bash
docker compose exec redis redis-cli ping
```

Ожидаемый ответ: `PONG`

## Troubleshooting

### Проблемы с портами

Если порты заняты, измените их в:
- `docker-compose.yml` (PostgreSQL, Redis)
- `.env` файлах сервисов

### Проблемы с Husky

Если pre-commit hooks не работают:
```bash
chmod +x .husky/pre-commit
pnpm exec husky install
```

### Проблемы с Prisma

Убедитесь, что PostgreSQL запущен:
```bash
docker compose ps
```

Проверьте `DATABASE_URL` в `shared/.env`

## Следующие шаги

После успешной настройки можно переходить к:
- Фаза 1: Разработка Auth Service и Content Service
- Фаза 2: Разработка Organization Service и User Service

