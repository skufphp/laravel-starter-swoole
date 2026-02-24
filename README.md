# Laravel Octane + Swoole — Docker Boilerplate

Boilerplate для быстрого развертывания **Laravel Octane** на **Swoole** в Docker.

## Архитектура

```
┌─────────────────────────────────────────────────┐
│              Docker Compose                      │
│                                                  │
│  ┌──────────────────────┐   ┌────────────────┐  │
│  │  Swoole (PHP 8.4)    │   │  PostgreSQL    │  │
│  │  Laravel Octane       │   │  18.2 Alpine   │  │
│  │  :8000 HTTP           │   │  :5432         │  │
│  └──────────────────────┘   └────────────────┘  │
│                                                  │
│                              ┌────────────────┐  │
│  ┌──────────────────────┐   │  Redis          │  │
│  │  Node.js (dev only)  │   │  8.6 Alpine     │  │
│  │  Vite HMR :5173      │   │  :6379          │  │
│  └──────────────────────┘   └────────────────┘  │
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
| Перезагрузка кода  | Автоматическая        | `make octane-reload` или `--watch`       |

## Структура проекта (файлы boilerplate)

```
├── docker/
│   ├── php.Dockerfile          # Многоэтапный образ (dev + production)
│   └── php/
│       ├── php.ini             # Настройки PHP для разработки
│       └── php.prod.ini        # Настройки PHP для продакшена
├── docker-compose.yml          # Базовые сервисы (app, postgres, redis)
├── docker-compose.dev.yml      # Оверлей для разработки (volumes, xdebug, pgadmin, node)
├── docker-compose.prod.yml     # Оверлей для продакшена (queue, scheduler, migrate)
├── .dockerignore               # Исключения из контекста сборки
├── .env.docker                 # Шаблон переменных окружения для Docker
├── Makefile                    # Команды управления проектом
└── SETUP.md                    # Подробная инструкция по установке
```

## Быстрый старт

```bash
# 1. Создайте Laravel проект
composer create-project laravel/laravel my-app
cd my-app

# 2. Добавить Octane в зависимости (локально Swoole не нужен)
composer require laravel/octane

# 3. Скопируйте файлы boilerplate в проект
# (docker/, docker-compose*.yml, Makefile, .dockerignore)

# 4. Настройте .env (см. SETUP.md)

# 5. Запустить — всё остальное сделает init-job внутри контейнера
make setup
```

Подробная инструкция — в файле **[SETUP.md](SETUP.md)**.

## Основные команды

| Команда                  | Описание                         |
|--------------------------|----------------------------------|
| `make setup`             | Полная инициализация проекта     |
| `make up`                | Запустить контейнеры (dev)       |
| `make down`              | Остановить контейнеры            |
| `make logs-app`          | Логи Swoole                      |
| `make shell`             | Войти в контейнер                |
| `make octane-reload`     | Перезагрузить воркеры Swoole     |
| `make octane-status`     | Статус Swoole Octane             |
| `make artisan CMD="..."` | Выполнить artisan-команду        |
| `make test-php`          | Запустить тесты                  |
| `make help`              | Полный список команд             |
