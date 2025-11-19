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
2. Спроектировать конфигурацию школы: бренд, домен, платежный план, интеграции.

## 3. Архитектура микросервисов
1. **Tenant Service**:
   - CRUD школ, тарифы, домены, настройки.
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
   - Tenant resolution (по домену/`X-Tenant-ID`), rate limit per tenant, аудит.

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
   - Multi-tenant routing: `tenantId.maratea.app` или `app.maratea.com/{tenant}`.
   - Admin console для владельца школы.
   - Воркфлоу создания школы (wizard).
2. Landing:
   - Маркетинг SaaS, тарифы, CTA «создать школу за N минут».
3. White-label кастомизация: логотип, цвета, собственный домен.

## 7. DevOps и инфраструктура
1. Секреты и конфиги per tenant (Kubernetes Secrets/External Secrets).
2. Helm/ArgoCD: шаблонизация сервисов, values для tenant-aware настроек.
3. Observability:
   - Метрики с лейблом tenant (Prometheus + logs Loki labels).
   - Отдельные dashboards и алерты per tenant (SLO).
4. Автомасштабирование (HPA) по нагрузке tenant.

## 8. Безопасность и соответствие
1. Изоляция данных: политики на уровне приложений + PostgreSQL RLS.
2. Аудит действий (audit log) per tenant.
3. Шифрование конфиденциальных данных, контроль доступа к бэкапам.
4. Pen-test, threat modeling.

## 9. Roadmap релизов
1. **Sprint 1**: Tenant Service + Auth (multi-tenant JWT) + базовая модель данных.
2. **Sprint 2**: User/Course Service с tenant_id, UI для создания школ.
3. **Sprint 3**: Биллинг/лимиты, уведомления, white-label настройки.
4. **Sprint 4**: Observability per tenant, backup/restore wizard.
5. **Sprint 5**: Production hardening (DR, autoscaling, runbooks) + GA.

## 10. Коммуникации
1. Обновить документацию:
   - README, архитектурные схемы, API specs (OpenAPI).
2. Обновить клиентский onboarding: гайд «Как запустить свою школу».
3. План миграции текущих пользователей на модель «школ».

