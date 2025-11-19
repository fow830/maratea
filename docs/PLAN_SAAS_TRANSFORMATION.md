# План трансформации в SaaS «школы как сервис»

## 1. Анализ и требования
1. Зафиксировать целевую модель multi-tenant:
   - Школа = отдельный клиентский workspace.
   - Жизненный цикл школы: регистрация, настройка бренда, биллинг, управление пользователями.
2. Выявить регуляторные требования (данные, юридические соглашения, GDPR/152-ФЗ).
3. Определить SLA/лимиты: количество пользователей, курсов, дисковая квота, частота бэкапов.

## 2. Доменная модель
1. Обновить ER-диаграмму:
   - `tenants` (школы) → `organizations`, `courses`, `lessons`, `enrollments`.
   - Роли: owner, admin, instructor, student.
2. Спроектировать конфигурацию школы: бренд, **кастомный домен**, платежный план, интеграции.
3. **Кастомные домены для школ**:
   - Каждая школа может подключить свой домен (например, `school1.com`, `learn.school2.com`).
   - Домен привязан к tenant через `tenant_domains` таблицу.
   - Валидация владения доменом (DNS TXT запись или файл на корне).

## 3. Архитектура микросервисов
1. **Tenant Service**:
   - CRUD школ, тарифы, **управление кастомными доменами**, настройки.
   - Валидация доменов (DNS проверка), активация домена.
   - Интеграция с биллингом (Stripe/Timeweb invoices).
2. **Auth Service**:
   - Мультиарендная авторизация: OAuth2/OpenID, tenant-aware JWT.
   - SSO для корпоративных клиентов (SAML/SCIM в перспективе).
3. **User Service**:
   - Профили, роли, приглашения в школу, RBAC внутри tenant.
4. **Course Service**:
   - Курсы, модули, уроки, прогресс, сертификация.
5. **Billing/Usage Service** (этап 2):
   - Подписки, счетчики использования, уведомления о лимитах.
6. **Notification Service**:
   - Email/Webhook/Telegram по событиям школы.
7. API Gateway:
   - **Tenant resolution по домену** (primary метод): определение tenant из `Host` header.
   - Fallback: `X-Tenant-ID` header для API запросов.
   - Rate limit per tenant, аудит, метрики per tenant.

## 4. Данные и изоляция
1. Модель хранения:
   - Вариант A: shared database, tenant_id в каждой таблице (быстрее запуск).
   - Вариант B: схема на tenant (Postgres schemas) для крупных клиентов.
   - Вариант C: выделенные базы (premium).
2. Секреты/ключи per tenant (S3, SMTP, интеграции).
3. Миграции:
   - Liquibase/Prisma миграции с awareness по tenant.
   - Data loader для существующих школ (if any).

## 5. Бэкап/восстановление
1. Гранулярные бэкапы per tenant (pg_dump with tenant filters).
2. Disaster Recovery: восстановление школы на staging, экспорт курсов.
3. Хранение бэкапов в S3 с тегами tenant_id + retention policy.

## 6. Фронтенд и UX
1. App (Next.js):
   - **Роутинг по кастомным доменам**: каждая школа доступна на своём домене.
   - Fallback: `tenantId.maratea.app` или `app.maratea.com/{tenant}` для школ без кастомного домена.
   - Admin console для владельца школы (настройка домена, DNS инструкции).
   - Воркфлоу создания школы (wizard) + подключение домена.
2. Landing:
   - Маркетинг SaaS, тарифы, CTA «создать школу за N минут».
3. White-label кастомизация: логотип, цвета, **собственный домен**.

## 7. DevOps и инфраструктура
1. Секреты и конфиги per tenant (Kubernetes Secrets/External Secrets).
2. Helm/ArgoCD: шаблонизация сервисов, values для tenant-aware настроек.
3. **Инфраструктура кастомных доменов**:
   - **Kubernetes Controller** для управления доменами:
     - Watch `tenant_domains` таблицу или API Tenant Service.
     - Динамическое создание/удаление Ingress ресурсов для каждого домена.
     - Автоматическое создание Certificate ресурсов (cert-manager).
   - **Ingress Controller** (nginx):
     - Поддержка wildcard DNS (`*.maratea.app` для fallback).
     - Роутинг по `Host` header к нужному Service (app/landing).
   - **cert-manager**:
     - ClusterIssuer для Let's Encrypt (HTTP-01 challenge).
     - Автоматическое получение TLS сертификатов для каждого домена.
     - Мониторинг статуса сертификатов (Prometheus metrics).
   - **DNS валидация**:
     - Проверка DNS записей (A/CNAME) перед активацией домена.
     - Инструкции для пользователя: куда указывать DNS (IP LoadBalancer).
4. Observability:
   - Метрики с лейблом tenant (Prometheus + logs Loki labels).
   - Отдельные dashboards и алерты per tenant (SLO).
5. Автомасштабирование (HPA) по нагрузке tenant.

## 8. Безопасность и соответствие
1. Изоляция данных: политики на уровне приложений + PostgreSQL RLS.
2. **Изоляция по доменам**: проверка, что запрос с домена `school1.com` не может получить данные `school2.com`.
3. Аудит действий (audit log) per tenant + per domain.
4. Шифрование конфиденциальных данных, контроль доступа к бэкапам.
5. **Валидация доменов**: защита от подделки доменов (DNS проверка, TLS сертификаты).
6. Pen-test, threat modeling (включая multi-tenant изоляцию).

## 9. Roadmap релизов
1. **Sprint 1**: Tenant Service + Auth (multi-tenant JWT) + базовая модель данных.
2. **Sprint 2**: User/Course Service с tenant_id, UI для создания школ.
3. **Sprint 3**: Биллинг/лимиты, уведомления, **кастомные домены**:
   - Tenant Service: CRUD доменов, валидация DNS.
   - Kubernetes Controller для динамических Ingress/Certificate.
   - API Gateway: tenant resolution по домену.
   - UI: настройка домена в админке школы.
4. **Sprint 4**: Observability per tenant, backup/restore wizard, white-label кастомизация (логотип, цвета).
5. **Sprint 5**: Production hardening (DR, autoscaling, runbooks) + GA.

## 10. Коммуникации
1. Обновить документацию:
   - README, архитектурные схемы, API specs (OpenAPI).
2. Обновить клиентский onboarding: гайд «Как запустить свою школу».
3. План миграции текущих пользователей на модель «школ».

