# Быстрый старт - Maratea Platform

## Шаг 1: Установка зависимостей

### Установка pnpm (если не установлен)

```bash
# Через npm (требует sudo)
npm install -g pnpm@8.15.0

# Или через corepack (рекомендуется)
corepack enable
corepack prepare pnpm@8.15.0 --activate
```

### Установка зависимостей проекта

```bash
pnpm install
```

Это автоматически инициализирует Husky hooks.

## Шаг 2: Настройка переменных окружения

`.env.example` файлы уже созданы. Скопируйте их в `.env`:

```bash
# API Gateway
cp services/api-gateway/.env.example services/api-gateway/.env

# Shared (для Prisma)
cp shared/.env.example shared/.env

# App
cp app/.env.example app/.env

# Landing
cp landing/.env.example landing/.env
```

Или создайте `.env` файлы вручную, используя `.env.example` как шаблон.

## Шаг 3: Запуск Docker Compose

### Убедитесь, что Docker запущен

```bash
# Проверка статуса Docker
docker ps

# Если Docker не запущен, запустите Docker Desktop
```

### Запуск сервисов

```bash
make docker-up
# или
docker compose up -d
```

### Проверка статуса

```bash
docker compose ps
```

Должны быть запущены:
- `maratea-postgres` (PostgreSQL)
- `maratea-redis` (Redis)

## Проверка работоспособности

### Health Check API Gateway

После установки зависимостей и запуска API Gateway:

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

### Проверка PostgreSQL

```bash
docker compose exec postgres psql -U maratea_user -d maratea_platform -c "SELECT version();"
```

### Проверка Redis

```bash
docker compose exec redis redis-cli ping
```

Ожидаемый ответ: `PONG`

## Запуск в режиме разработки

```bash
# Все сервисы
make dev

# Или отдельно API Gateway
cd services/api-gateway
pnpm dev
```

## Troubleshooting

### pnpm не найден

Установите pnpm одним из способов выше.

### Docker daemon не запущен

Запустите Docker Desktop или Docker daemon.

### Порт занят

Измените порты в `docker-compose.yml` или `.env` файлах.

### Проблемы с правами

Для установки pnpm может потребоваться `sudo`:
```bash
sudo npm install -g pnpm@8.15.0
```

## Следующие шаги

После успешной настройки:
1. ✅ Зависимости установлены
2. ✅ Переменные окружения настроены
3. ✅ Docker Compose запущен
4. 🚀 Готово к разработке!

Можно переходить к **Фазе 1**: разработка Auth Service и Content Service.

