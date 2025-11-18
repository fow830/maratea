# Отключение CodeQL Default Setup

Дата: 2025-11-18

## 🔧 Проблема

CodeQL workflow падает с ошибкой:
```
CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled
```

## ✅ Решение

### Вариант 1: Через веб-интерфейс GitHub (рекомендуется)

1. Откройте настройки репозитория:
   ```
   https://github.com/fow830/maratea/settings/security
   ```

2. Найдите раздел **"Code scanning"** → **"CodeQL analysis"**

3. Нажмите **"Configure"** или **"Edit"**

4. В разделе **"Advanced"** выберите:
   - **"Disable CodeQL"** или
   - Установите state в **"not-configured"**

5. Сохраните изменения

### Вариант 2: Через GitHub CLI (требуются права администратора)

```bash
gh api repos/fow830/maratea/code-scanning/default-setup \
  -X PATCH \
  -f state=not-configured
```

### Вариант 3: Через GitHub API напрямую

```bash
curl -X PATCH \
  -H "Authorization: token YOUR_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/fow830/maratea/code-scanning/default-setup \
  -d '{"state":"not-configured"}'
```

## 🔍 Проверка

После отключения default setup:

1. Проверьте статус:
   ```bash
   gh api repos/fow830/maratea/code-scanning/default-setup
   ```

2. Должно вернуться:
   ```json
   {"state":"not-configured"}
   ```

3. Перезапустите CodeQL workflow:
   ```bash
   gh workflow run codeql.yml
   ```

## 📝 Примечание

- Default setup автоматически создает CodeQL workflow
- Наш кастомный workflow конфликтует с default setup
- После отключения default setup наш workflow будет работать корректно

## ✅ После отключения

CodeQL workflow должен:
- ✅ Успешно инициализироваться
- ✅ Выполнять анализ
- ✅ Загружать SARIF файлы в GitHub Security
- ✅ Не конфликтовать с default setup

