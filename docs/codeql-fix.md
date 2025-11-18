# Исправление CodeQL - Конфликт с Default Setup

Дата: 2025-11-18

## 🔧 Проблема

CodeQL workflow падал с ошибкой:
```
CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled
```

## ✅ Решение

### 1. Создан config файл

**Файл:** `.github/codeql/codeql-config.yml`

```yaml
name: "CodeQL Config"

paths:
  - "services/**"
  - "app/**"
  - "landing/**"
  - "shared/**"

paths-ignore:
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "**/*.test.js"
  - "**/*.spec.js"
  - "node_modules/**"
  - "dist/**"
  - ".next/**"
```

### 2. Обновлен workflow

**Файл:** `.github/workflows/codeql.yml`

Добавлен `config-file` в `Initialize CodeQL` step:
```yaml
- name: Initialize CodeQL
  uses: github/codeql-action/init@v4
  with:
    languages: ${{ matrix.language }}
    config-file: ./.github/codeql/codeql-config.yml
```

## 📝 Альтернативное решение

Если ошибка сохранится, нужно отключить default CodeQL setup в настройках репозитория:

1. Открыть: `Settings → Code security and analysis → Code scanning`
2. Найти раздел `Advanced`
3. Отключить `Default setup`

Или через GitHub CLI:
```bash
gh api repos/:owner/:repo/code-scanning/default-setup \
  -X PATCH \
  -f state=not_configured
```

## 🔍 Проверка

После применения изменений:
- CodeQL workflow должен успешно выполняться
- SARIF файлы должны загружаться в GitHub Security
- Не должно быть конфликтов с default setup

