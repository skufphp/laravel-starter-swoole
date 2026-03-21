# Laravel Octane + Swoole — Docker Boilerplate

Boilerplate для быстрого развертывания **Laravel Octane** на **Swoole** в Docker.

## Архитектура

```
┌─────────────────────────────────────────────────┐
│              Docker Compose                      │
│                                                  │
│  ┌──────────────────────┐   ┌────────────────┐  │
│  │  Swoole (PHP 8.5)    │   │  PostgreSQL    │  │
│  │  Laravel Octane       │   │  18.2 Alpine   │  │
│  │  :8000 HTTP           │   │  :5432         │  │
│  │  :2114 Health Check   │   └────────────────┘  │
│  └──────────────────────┘                        │
│                              ┌────────────────┐  │
│  ┌──────────────────────┐   │  Redis          │  │
│  │  Node.js (dev only)  │   │  8.6 Alpine     │  │
│  │  Vite HMR :5173      │   │  :6379          │  │
│  │  └───────────────────┘   └────────────────┘  │
│                                                  │
│  ┌──────────────────────┐                        │
│  │  pgAdmin (dev only)  │                        │
│  │  :8080               │                        │
│  └──────────────────────┘                        │
└─────────────────────────────────────────────────┘
```

## Ключевые отличия от Nginx + PHP-FPM

| Аспект             | Nginx + PHP-FPM       | Swoole (Octane)                          |
|--------------------|-----------------------|------------------------------------------|
| Контейнеры         | 2 (Nginx + PHP-FPM)   | 1 (Swoole)                               |
| Протокол           | Unix socket / FastCGI | Встроенный HTTP-сервер                   |
| Модель             | Процесс на запрос     | Persistent workers + coroutines          |
| Производительность | Хорошая               | Высокая (нет bootstrap на каждый запрос) |
| Статика            | Nginx                 | Reverse proxy (Caddy/Nginx) или Octane   |
| Перезагрузка кода  | Автоматическая        | `make swoole-reload` или `--watch`       |

## Структура проекта (файлы boilerplate)

```
├── docker/
│   ├── php.Dockerfile          # Многоэтапный образ (dev + production)
│   └── php/
│       ├── php.ini             # Настройки PHP для разработки
│       └── php.prod.ini        # Настройки PHP для продакшена
├── docker-compose.yml          # Разработка (app, node, postgres, redis, queue, scheduler, pgadmin)
├── docker-compose.prod.yml     # Продакшен-стек (app, postgres, redis, queue, scheduler)
├── docker-compose.prod.local.yml # Локальный запуск production-стека через .env.production
├── .dockerignore               # Исключения из контекста сборки
├── .env.docker                 # Шаблон переменных окружения для Docker
├── .env.production.example     # Шаблон переменных для production/локального prod-запуска
├── Makefile                    # Команды управления проектом
└── SETUP.md                    # Подробная инструкция по установке
```

## Быстрый старт

```bash
# 1. Создайте Laravel проект
composer create-project laravel/laravel my-app

# 2. Добавить Octane в зависимости (локально Swoole не нужен)
cd my-app
composer require laravel/octane

# 3. Скопируйте файлы boilerplate в проект
# (docker/, docker-compose*.yml, Makefile, .dockerignore, .env.production.example)

# 4. Настройте .env (см. SETUP.md)
# Важно для Redis:
# SESSION_DRIVER=redis
# CACHE_STORE=redis
# QUEUE_CONNECTION=redis
# REDIS_CLIENT=phpredis

# 5. Запустить
make setup
```

Подробная инструкция — в файле **[SETUP.md](SETUP.md)**.

## Локальный запуск production-стека

```bash
cp .env.production.example .env.production
make up-prod
```

`make up-prod` использует `--env-file .env.production` и `docker-compose.prod.local.yml`.

## Dokploy

Пошаговый деплой для Dokploy описан в **[SETUP.md](SETUP.md)** (раздел `Развертывание в Dokploy`): перенос всех переменных из `.env.production` в секцию `Environment -> Environment Settings`, изоляция preview-БД и `Post-deployment` команда для миграций.

## Основные команды

| Команда                  | Описание                         |
|--------------------------|----------------------------------|
| `make setup`             | Полная инициализация проекта     |
| `make up`                | Запустить контейнеры (dev)       |
| `make up-prod`           | Запустить контейнеры (prod local)|
| `make down`              | Остановить контейнеры            |
| `make down-prod`         | Остановить контейнеры (prod local)|
| `make logs`              | Логи всех сервисов (dev)         |
| `make logs-prod`         | Логи всех сервисов (prod local)  |
| `make logs-app`          | Логи Swoole                      |
| `make logs-app-prod`     | Логи Swoole (prod local)         |
| `make logs-postgres`     | Логи PostgreSQL (dev)            |
| `make logs-postgres-prod`| Логи PostgreSQL (prod local)     |
| `make logs-redis`        | Логи Redis (dev)                 |
| `make logs-redis-prod`   | Логи Redis (prod local)          |
| `make logs-queue`        | Логи queue worker (dev)          |
| `make logs-queue-prod`   | Логи queue worker (prod local)   |
| `make logs-scheduler`    | Логи scheduler (dev)             |
| `make logs-scheduler-prod`| Логи scheduler (prod local)     |
| `make shell`             | Войти в контейнер                |
| `make shell-prod`        | Войти в app-контейнер (prod local)|
| `make shell-postgres`    | PostgreSQL CLI (dev)             |
| `make shell-postgres-prod`| PostgreSQL CLI (prod local)     |
| `make shell-redis`       | Redis CLI (dev)                  |
| `make shell-redis-prod`  | Redis CLI (prod local)           |
| `make shell-queue-prod`  | Shell queue worker (prod local)  |
| `make shell-scheduler-prod`| Shell scheduler (prod local)   |
| `make swoole-reload`     | Перезагрузить воркеры Swoole     |
| `make swoole-status`     | Статус воркеров                  |
| `make artisan CMD="..."` | Выполнить artisan-команду        |
| `make test-php`          | Запустить тесты                  |
| `make help`              | Полный список команд             |
