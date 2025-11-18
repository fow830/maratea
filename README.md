# Maratea LMS Platform

Корпоративная платформа для обучения сотрудников (Learning Management System).

## Архитектура

Проект построен на микросервисной архитектуре с использованием:
- **Monorepo** (Turborepo + pnpm)
- **Node.js 22** с TypeScript
- **PostgreSQL** (Database per Service)
- **Redis** для кэширования
- **Kubernetes** для оркестрации
- **OpenTelemetry** для observability

## Структура проекта

```
maratea/
├── services/          # Микросервисы
│   ├── api-gateway/  # API Gateway
│   ├── auth-service/ # Аутентификация
│   └── ...
├── app/              # Next.js приложение (app.maratea.com)
├── landing/          # Landing page (maratea.com)
├── shared/           # Общие типы и утилиты
└── infrastructure/   # K8s манифесты, Terraform
```

## Быстрый старт

### Требования

- Node.js >= 22.0.0
- pnpm >= 8.0.0
- Docker & Docker Compose

### Установка

Подробная инструкция по настройке: [SETUP.md](./SETUP.md)

```bash
# Установка зависимостей
make install
# или
pnpm install

# Настройка переменных окружения (см. SETUP.md)

# Запуск Docker Compose (PostgreSQL, Redis)
make docker-up
# или
docker compose up -d

# Запуск в режиме разработки
make dev
# или
pnpm dev
```

## Доступные команды

```bash
make help          # Показать все доступные команды
make install       # Установить зависимости
make dev           # Запустить все сервисы в dev режиме
make build         # Собрать все сервисы
make test          # Запустить тесты
make lint          # Проверить код линтером
make clean         # Очистить артефакты сборки
make docker-up     # Запустить Docker Compose
make docker-down   # Остановить Docker Compose
make docker-logs   # Просмотр логов Docker
```

## Переменные окружения

Скопируйте `.env.example` файлы в каждом сервисе и настройте переменные окружения.

## Разработка

### Добавление нового сервиса

1. Создайте директорию в `services/`
2. Добавьте `package.json` с зависимостями
3. Добавьте маршрут в `api-gateway/src/config/routes.ts`
4. Настройте Prisma schema в `services/[service-name]/prisma/`

### Структура микросервиса

```
services/[service-name]/
├── src/
│   ├── index.ts
│   ├── routes/
│   ├── controllers/
│   ├── services/
│   └── models/
├── prisma/
│   └── schema.prisma
├── package.json
└── Dockerfile
```

## Документация

- [Архитектура](./docs/architecture.md)
- [API Documentation](./docs/api.md)
- [Deployment](./docs/deployment.md)

## Лицензия

Proprietary

