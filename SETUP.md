# Инструкция по работе с Laravel Boilerplate

Этот boilerplate предназначен для быстрого развертывания Laravel-проекта с архитектурой **Laravel Octane + Swoole + PostgreSQL 18.2 + Redis 8.6**.

---

## Содержание

1. [Для каких приложений подходит](#для-каких-приложений-подходит)
2. [Структура проекта](#структура-проекта)
3. [Быстрый старт (Development)](#быстрый-старт-development)
4. [Работа с окружениями](#работа-с-окружениями)
5. [Команды Makefile](#команды-makefile)
6. [Тестирование](#тестирование)
7. [Production-деплой](#production-деплой)
8. [Архитектура Docker](#архитектура-docker)
9. [Конфигурация сервисов](#конфигурация-сервисов)
10. [Swoole / Octane особенности](#swoole--octane-особенности)
11. [Troubleshooting](#troubleshooting)

---

## Для каких приложений подходит

### ✅ Высоконагруженные API
Swoole особенно хорошо подходит для REST / GraphQL API, микросервисов и других приложений с высоким числом запросов благодаря coroutines и persistent workers.

### ✅ Blade-based приложения
Классический Laravel: Blade templates, server-side rendering, Tailwind/Bootstrap.
**Примеры:** CRM, админки, корпоративные сайты, SaaS-панели, internal tools.

### ✅ Laravel + Livewire / Inertia
Frontend внутри Laravel: Livewire, Inertia + Vue/React. JS живет в `resources/`, Vite используется для сборки ассетов.

### ✅ API-only backend
Laravel как REST / GraphQL API без UI. Один HTTP-сервис, простая Docker-модель, отдельные контейнеры для очередей и планировщика.

**Итог:** подходит для Blade, Livewire, Inertia, API-only, Admin panels, Small-medium SaaS и high-load API, где нужен прирост производительности без отдельного frontend web server.

---

## Структура проекта

```text
├── docker/
│   ├── php.Dockerfile            # Multi-stage: development -> production
│   └── php/
│       ├── php.ini               # PHP конфиг для разработки
│       └── php.prod.ini          # PHP конфиг для production
├── docker-compose.yml            # Базовая конфигурация сервисов и разработка
├── docker-compose.prod.yml       # Прод-конфигурация сервисов
├── docker-compose.prod.local.yml # Prod: локальный запуск с --env-file .env.production
├── .dockerignore                 # Исключения из контекста сборки
├── .env.docker                   # Шаблон Docker-переменных для .env
├── .env.production.example       # Пример production-переменных
├── Makefile                      # Автоматизация всех операций
└── README.md / SETUP.md          # Основная документация по проекту
```

---

## Быстрый старт (Development)

### Предварительные требования

- **Docker** >= 24.0 и **Docker Compose** >= 2.20
- **Git**
- **Composer** и **PHP CLI** для первоначальной установки Laravel/Octane

### Шаг 1. Создание Laravel-проекта

```bash
composer create-project laravel/laravel my-project
cd my-project
```

### Шаг 2. Установка Laravel Octane

```bash
composer require laravel/octane
php artisan octane:install
```

Команда `octane:install` добавляет Swoole-поддержку в проект Laravel. Swoole — это PHP-расширение (C-extension), а не отдельный бинарный файл. Оно уже установлено в Docker-образе из этого boilerplate. Локально устанавливать Swoole не нужно — всё работает внутри контейнера.

### Шаг 3. Копирование файлов boilerplate

Скопируйте в корень Laravel-проекта:
- Папку `docker/`
- Файлы `docker-compose.yml`, `docker-compose.prod.yml`, `docker-compose.prod.local.yml`
- Файлы `Makefile`, `.dockerignore`, `.env.docker`, `.env.production.example`

### Шаг 4. Настройка конфигурационных файлов Laravel

#### Настройка Octane

В `config/octane.php` измените строку:

```php
'server' => env('OCTANE_SERVER', 'roadrunner'),
```

на:

```php
'server' => env('OCTANE_SERVER', 'swoole'),
```

После секции `Force HTTPS` добавьте:

```php
/*
|--------------------------------------------------------------------------
| Octane State File
|--------------------------------------------------------------------------
|
| Octane stores process IDs and runtime server state in this file. Keeping
| it under storage/framework avoids coupling the runtime state to log storage.
|
*/

'state_file' => env('OCTANE_STATE_FILE', storage_path('framework/octane-server-state.json')),
```

#### Удаление лишних файлов

Laravel по умолчанию создает `database/database.sqlite`. В этом стеке используется PostgreSQL, поэтому удалите файл и добавьте маску в `.gitignore`:

```bash
rm database/database.sqlite
```

Добавьте в `.gitignore`:

```text
database/*.sqlite
```

#### Обновление fallback-значений конфигурации

Laravel хранит дефолтные значения подключений в `config/`. По умолчанию они указывают на `sqlite`, файловые сессии и файловый кеш. Для корректной работы в случае проблем с `.env` замените их на значения, соответствующие этому стеку:

**`config/database.php`**
```php
'default' => env('DB_CONNECTION', 'pgsql'),
```

**`config/queue.php`**
```php
'default' => env('QUEUE_CONNECTION', 'redis'),
// ...
'batching' => [
    'database' => env('DB_CONNECTION', 'pgsql'),
],
'failed' => [
    'database' => env('DB_CONNECTION', 'pgsql'),
],
```

**`config/cache.php`**
```php
'default' => env('CACHE_STORE', 'redis'),
```

**`config/session.php`**
```php
'driver' => env('SESSION_DRIVER', 'redis'),
```

> **Примечание:** Миграция `create_cache_table` создает таблицу `cache` в БД, но при `CACHE_STORE=redis` она не используется. Ее можно удалить для чистоты или оставить как fallback.

---

### Шаг 5. Настройка .env

Откройте `.env` и внесите изменения:

```dotenv
# --- Замените стандартные значения ---
DB_CONNECTION=pgsql
DB_HOST=laravel-postgres-sw
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=postgres
DB_PASSWORD=root

REDIS_CLIENT=phpredis
REDIS_HOST=laravel-redis-sw
REDIS_PORT=6379
REDIS_PASSWORD=

QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
CACHE_STORE=redis

OCTANE_SERVER=swoole

# --- Добавьте в конец файла (из .env.docker) ---
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=admin

APP_PORT=8050
DB_FORWARD_PORT=5432
REDIS_FORWARD_PORT=6379
PGADMIN_PORT=8080

XDEBUG_MODE=off
XDEBUG_START=no
XDEBUG_CLIENT_HOST=host.docker.internal

OCTANE_STATE_FILE=/var/www/laravel/storage/framework/octane-server-state.json
SWOOLE_WORKERS=2
SWOOLE_TASK_WORKERS=2
SWOOLE_MAX_REQUESTS=250

APP_BASE_PATH=/var/www/laravel
```

### Шаг 6. Запуск

```bash
make setup
```

Эта команда автоматически:
1. Соберет Docker-образы
2. Запустит все контейнеры (Swoole app, PostgreSQL, Redis, Queue Worker, Scheduler, Node HMR, pgAdmin)
3. Установит зависимости (Composer + NPM)
4. Сгенерирует `APP_KEY`
5. Запустит миграции
6. Настроит права доступа

**Готово!** Проект доступен:
- **Сайт:** http://localhost:8050
- **pgAdmin:** http://localhost:8080
- **Vite HMR:** http://localhost:5173

---

## Работа с окружениями

### Development (по умолчанию)

```bash
make up          # Запустить
make down        # Остановить
make restart     # Перезапустить
make logs        # Логи всех сервисов
```

Особенности dev-режима:
- Код монтируется из хоста
- Vite HMR для горячей перезагрузки фронтенда
- pgAdmin для управления БД
- Порты PostgreSQL и Redis проброшены наружу для IDE/GUI-клиентов
- Xdebug установлен в dev-образе и включается через `.env`
- В dev-режиме контейнер запускается с флагом `--watch`, который автоматически перезагружает воркеры при изменении PHP-файлов. Если автоматическая перезагрузка не срабатывает — `make swoole-reload`

### Production

```bash
cp .env.production.example .env.production
make up-prod
```

Особенности prod-режима:
- Локальный production-запуск через `docker-compose.prod.local.yml`
- `php.prod.ini` с production-настройками PHP
- `composer install --no-dev --optimize-autoloader` выполняется при сборке production-образа
- При старте app-контейнера выполняются `php artisan optimize:clear` и `php artisan migrate --force`
- Queue Worker и Scheduler работают отдельными сервисами
- Переменные Laravel и Swoole передаются через `.env.production`

---

## Команды Makefile

### Управление контейнерами

| Команда               | Описание                         |
|-----------------------|----------------------------------|
| `make up`             | Запустить проект (dev)           |
| `make up-prod`        | Запустить проект (prod)          |
| `make down`           | Остановить dev-контейнеры        |
| `make down-prod`      | Остановить prod-контейнеры       |
| `make restart`        | Перезапустить контейнеры         |
| `make build`          | Собрать образы                   |
| `make rebuild`        | Пересобрать dev-образы без кэша  |
| `make rebuild-prod`   | Пересобрать prod-образы без кэша |
| `make status`         | Статус контейнеров               |
| `make clean`          | Удалить контейнеры и тома        |
| `make clean-all`      | Полная очистка dev (+ образы)    |
| `make dev-reset`      | Сброс среды разработки           |
| `make clean-prod`     | Удалить prod-контейнеры и тома   |
| `make clean-all-prod` | Полная очистка prod (+ образы)   |
| `make prod-reset`     | Сброс prod-среды                 |

### Логи

| Команда                    | Описание                 |
|----------------------------|--------------------------|
| `make logs`                | Все dev-сервисы          |
| `make logs-prod`           | Все prod-сервисы         |
| `make logs-app`            | Swoole                   |
| `make logs-app-prod`       | Swoole (prod)            |
| `make logs-postgres`       | PostgreSQL               |
| `make logs-postgres-prod`  | PostgreSQL (prod)        |
| `make logs-redis`          | Redis                    |
| `make logs-redis-prod`     | Redis (prod)             |
| `make logs-queue`          | Queue Worker             |
| `make logs-queue-prod`     | Queue Worker (prod)      |
| `make logs-scheduler`      | Scheduler                |
| `make logs-scheduler-prod` | Scheduler (prod)         |
| `make logs-node`           | Node (HMR)               |
| `make logs-pgadmin`        | pgAdmin                  |

### Shell-доступ

| Команда                     | Описание                         |
|-----------------------------|----------------------------------|
| `make shell`                | Консоль app-контейнера           |
| `make shell-prod`           | Консоль app-контейнера (prod)    |
| `make shell-node`           | Консоль Node                     |
| `make shell-postgres`       | PostgreSQL CLI (`psql`)          |
| `make shell-postgres-prod`  | PostgreSQL CLI (`psql`) для prod |
| `make shell-redis`          | Redis CLI / ping                 |
| `make shell-redis-prod`     | Redis CLI / ping для prod        |
| `make shell-queue`          | Консоль Queue Worker             |
| `make shell-queue-prod`     | Консоль Queue Worker (prod)      |
| `make shell-scheduler`      | Консоль Scheduler                |
| `make shell-scheduler-prod` | Консоль Scheduler (prod)         |

### Laravel и зависимости

| Команда                                    | Описание                                      |
|--------------------------------------------|-----------------------------------------------|
| `make setup`                               | Полная инициализация проекта                  |
| `make install-deps`                        | Установить Composer + NPM зависимости         |
| `make artisan CMD="..."`                   | Любая artisan-команда                         |
| `make composer CMD="..."`                  | Любая composer-команда                        |
| `make composer-install`                    | `composer install`                            |
| `make composer-update`                     | `composer update`                             |
| `make composer-require PACKAGE=vendor/pkg` | `composer require`                            |
| `make migrate`                             | Запустить миграции                            |
| `make rollback`                            | Откатить миграции                             |
| `make fresh`                               | Пересоздать БД + сиды                         |
| `make tinker`                              | Laravel Tinker                                |
| `make test-php`                            | PHP-тесты                                     |
| `make test-coverage`                       | Тесты с покрытием                             |
| `make npm-install`                         | `npm install`                                 |
| `make npm-dev`                             | Vite dev server                               |
| `make npm-build`                           | Production-сборка фронтенда                   |
| `make permissions`                         | Исправить права `storage` и `bootstrap/cache` |
| `make info`                                | Показать информацию о проекте                 |
| `make validate`                            | Проверить HTTP-доступность сервисов           |

### Swoole / Octane

| Команда              | Описание                                   |
|----------------------|--------------------------------------------|
| `make swoole-reload` | Перезагрузить воркеры Swoole Octane        |
| `make swoole-status` | Проверить статус Swoole Octane             |

---

## Тестирование

```bash
make test-php
make test-coverage
```

Особенности тестирования:
- По умолчанию используется основная БД, если иное не настроено в `phpunit.xml`
- Для покрытия используется Xdebug
- Если менялись сервисы контейнера или окружение Octane, перед тестами полезно выполнить `make swoole-reload`

---

## Production-деплой

Минимальная последовательность для локальной проверки production-режима:

```bash
cp .env.production.example .env.production
make up-prod
make logs-prod
```

Что важно проверить перед деплоем:
- Актуальные значения `APP_URL`, `APP_KEY`, `DB_*`, `REDIS_*`, `SWOOLE_*` в `.env.production`
- Настройки внешнего reverse proxy / TLS-терминации, если HTTPS завершается вне контейнера
- Доступность постоянных томов для PostgreSQL и Redis
- Количество воркеров Swoole (`SWOOLE_WORKERS`) и лимит перезапуска (`SWOOLE_MAX_REQUESTS`)
- Политику перезапуска и мониторинг контейнеров

### Dokploy

Для Dokploy перенесите значения из `.env.production` в секцию **Environment -> Environment Settings** и используйте post-deployment команду уровня приложения или сервиса:

```bash
php artisan migrate --force && php artisan optimize:clear
```

Если используются preview/staging-окружения, для них нужны отдельные БД/Redis-инстансы или отдельные credentials.

---

## Архитектура Docker

### Схема взаимодействия

```text
                    ┌─────────────┐
                    │   Client    │
                    └──────┬──────┘
                           │ :80 / :8050
                    ┌──────▼──────┐
                    │   Swoole    │
                    │ Octane HTTP │──────────┐
                    └──────┬──────┘          │
                           │                 │
                 ┌─────────▼─────────┐ ┌────▼─────┐
                 │   PostgreSQL 18   │ │ Redis 8.6│
                 └───────────────────┘ └──────────┘
                           │
                 ┌─────────▼─────────┐
                 │ Queue / Scheduler │
                 └───────────────────┘
```

### Ключевая идея

Swoole выступает одновременно как HTTP-сервер и менеджер воркеров PHP с поддержкой coroutines. Это упрощает контейнеризацию, убирает отдельный web-server-контейнер и ускоряет обработку запросов за счет persistent workers.

---

## Конфигурация сервисов

### Swoole app
- Основной runtime Laravel-приложения
- В dev-режиме монтирует код проекта
- В prod-режиме собирается как финальный immutable image

### PostgreSQL
- Основная реляционная БД
- В dev-режиме проброшена на `DB_FORWARD_PORT`

### Redis
- Кеш, очереди, сессии
- В dev-режиме проброшен на `REDIS_FORWARD_PORT`

### Node
- Нужен только в development для Vite HMR

### Queue Worker / Scheduler
- Отдельные сервисы для фоновых задач Laravel
- Запускаются как отдельные процессы в Docker Compose

### pgAdmin
- Доступен только в dev-окружении
- Используется для администрирования PostgreSQL через браузер

---

## Swoole / Octane особенности

### Persistent workers
Octane не пересоздает приложение на каждый запрос. Любое состояние, сохраненное в static-свойствах, singleton-объектах или глобальных переменных, может пережить предыдущий запрос.

### Перезагрузка после изменений
В dev-режиме контейнер запускается с флагом `--watch`, который автоматически перезагружает воркеры при изменении PHP-файлов. Если автоматическая перезагрузка не срабатывает, используйте:

```bash
make swoole-reload
```

### На что обратить внимание в коде
- Не храните request-specific state в singleton-сервисах
- Не полагайтесь на то, что static-состояние будет сбрасываться между запросами
- Осторожно работайте с кешированными конфигами и долгоживущими подключениями
- При диагностике проблем сначала проверяйте, воспроизводится ли ошибка после `make swoole-reload`

---

## Troubleshooting

### Сайт не открывается
- Проверьте `make status`
- Проверьте `make logs-app`
- Убедитесь, что порт `APP_PORT` свободен

### Laravel не подключается к БД
- Проверьте `DB_HOST=laravel-postgres-sw`
- Проверьте `make logs-postgres`
- Убедитесь, что в `.env` выбран `DB_CONNECTION=pgsql`

### Redis недоступен
- Проверьте `REDIS_HOST=laravel-redis-sw`
- Проверьте `make logs-redis`
- Если задан пароль, убедитесь, что он совпадает в `.env` и compose

### Изменения в PHP-коде не применяются
- Выполните `make swoole-reload`
- Проверьте `make swoole-status`
- Если проблема остается, проверьте `make logs-app`

### Vite HMR не работает
- Проверьте `make logs-node`
- Убедитесь, что порт `5173` свободен
- Проверьте, что frontend использует Vite и зависимости установлены

### Ошибки прав доступа
- Выполните:

```bash
make permissions
```
