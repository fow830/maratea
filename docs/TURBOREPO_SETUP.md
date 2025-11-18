# Настройка Turborepo Remote Cache

## Текущий статус

✅ **Конфигурация проекта готова:**
- `turbo.json`: Remote cache включен
- `package.json`: `turbo@^2.0.0` установлен
- CI/CD workflows: настроены для использования remote cache
- GitHub Secrets: созданы (требуют заполнения)

## Шаги для получения токенов

### Вариант 1: Через веб-интерфейс (рекомендуется)

1. **Регистрация:**
   - Зайдите на https://vercel.com/turborepo
   - Или https://turbo.build
   - Зарегистрируйтесь через GitHub

2. **Создание команды:**
   - После регистрации создайте команду (team)
   - Team ID - это slug команды из URL: `https://vercel.com/{team-slug}`
   - Например, если URL `https://vercel.com/my-team`, то Team ID = `my-team`

3. **Получение токена:**
   - Перейдите в Settings → Tokens
   - Создайте новый токен
   - Скопируйте токен (он показывается только один раз!)

4. **Обновление GitHub Secrets:**
   ```bash
   gh secret set TURBO_TOKEN --body "ваш_токен_из_веб_интерфейса"
   gh secret set TURBO_TEAM --body "ваш_team_id"
   ```

### Вариант 2: Через CLI

1. **Авторизация:**
   ```bash
   npx turbo login
   ```
   - Откроется браузер для авторизации
   - После авторизации вернитесь в терминал

2. **Привязка к команде:**
   ```bash
   npx turbo link --team <your-team-id>
   ```

3. **Получение токена:**
   - После `turbo login` токен обычно сохраняется в `~/.turbo/config.json`
   - Или создайте токен через веб-интерфейс (см. Вариант 1)

4. **Обучение GitHub Secrets:**
   ```bash
   # Если токен в конфигурации
   TOKEN=$(cat ~/.turbo/config.json | jq -r '.token' 2>/dev/null || echo "")
   TEAM_ID=$(cat ~/.turbo/config.json | jq -r '.teamId' 2>/dev/null || echo "")
   
   if [ -n "$TOKEN" ]; then
     gh secret set TURBO_TOKEN --body "$TOKEN"
   fi
   
   if [ -n "$TEAM_ID" ]; then
     gh secret set TURBO_TEAM --body "$TEAM_ID"
   fi
   ```

### Вариант 3: Автоматический скрипт

Запустите интерактивный скрипт:

```bash
./scripts/get-turbo-tokens.sh
```

Скрипт поможет:
- Проверить авторизацию
- Найти Team ID
- Обновить GitHub Secrets

## Проверка настройки

1. **Локально:**
   ```bash
   pnpm turbo build
   # При повторной сборке должно показать [REMOTE CACHE HIT]
   ```

2. **В CI/CD:**
   - После обновления секретов следующий CI/CD run должен использовать remote cache
   - Проверьте логи CI/CD на наличие `[REMOTE CACHE HIT]`

3. **Проверка секретов:**
   ```bash
   gh secret list | grep TURBO
   ```

## Полезные ссылки

- [Turborepo Getting Started](https://turborepo.com/docs/getting-started)
- [Remote Caching](https://turborepo.com/docs/core-concepts/remote-caching)
- [Vercel Turborepo Dashboard](https://vercel.com/turborepo)

## Troubleshooting

### Проблема: "authentication required"
- Убедитесь, что выполнили `npx turbo login`
- Проверьте, что токен правильно установлен в GitHub Secrets

### Проблема: "team not found"
- Убедитесь, что Team ID правильный
- Проверьте, что команда создана в дашборде

### Проблема: Remote cache не работает в CI/CD
- Проверьте, что секреты установлены: `gh secret list | grep TURBO`
- Убедитесь, что токен и Team ID правильные
- Проверьте логи CI/CD на наличие ошибок авторизации

