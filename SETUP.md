# Инструкция по установке Laravel Octane + Swoole Boilerplate

---

## 🚀 Процесс установки для разработки

### 1. Создание проекта Laravel

Создайте новый проект Laravel:

```bash
composer create-project laravel/laravel my-app
```

```bash
cd my-app
```

### 2. Установка Laravel Octane

```bash
composer require laravel/octane
```

После установки пакета выполните публикацию конфигурации Octane:

```bash
php artisan octane:install
```

> **Примечание:** Swoole — это PHP-расширение (C-extension), а не отдельный бинарный файл. Оно уже установлено в Docker-образе из этого boilerplate. Локально устанавливать Swoole не нужно — всё работает внутри контейнера.

### 3. Копирование файлов boilerplate

Скопируйте следующие файлы и папки из данного boilerplate в корень вашего нового проекта Laravel:

* Папку `docker/` (включая все подпапки и файлы)
* Файлы `docker-compose.yml`, `docker-compose.prod.yml`, `docker-compose.prod.local.yml`
* Файл `Makefile`
* Файл `.dockerignore`
* Файл `.gitignore`

### 4. Настройка окружения (.env)

После `php artisan octane:install` сначала внесите изменения в `config/octane.php`, а затем продолжайте настройку `.env`.

**a) Настройте Octane в `/config/octane.php`:**

1. Измените строку

```php
'server' => env('OCTANE_SERVER', 'roadrunner'),
```

на

```php
'server' => env('OCTANE_SERVER', 'swoole'),
```

2. После секции `Force HTTPS` добавьте:

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

После этого откройте файл `.env` в корне Laravel и выполните следующие изменения:

**b) Настройте подключение к БД:**

```dotenv
DB_CONNECTION=pgsql
DB_HOST=laravel-postgres-sw
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=postgres
DB_PASSWORD=root
```

**c) Настройте Redis и драйверы Laravel (обязательно для этого boilerplate):**

```dotenv
REDIS_CLIENT=phpredis
REDIS_HOST=laravel-redis-sw
REDIS_PORT=6379
REDIS_PASSWORD=secret

SESSION_DRIVER=redis
CACHE_STORE=redis
QUEUE_CONNECTION=redis
```

**d) Добавьте в конец `.env` секцию из файла `.env.docker`:**

```dotenv
# --- Swoole / Octane Configuration ---
OCTANE_SERVER=swoole
OCTANE_STATE_FILE=/var/www/laravel/storage/framework/octane-server-state.json
SWOOLE_WORKERS=2
SWOOLE_TASK_WORKERS=2
SWOOLE_MAX_REQUESTS=250

# --- pgAdmin Web Interface ---
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=admin

# --- Docker ports ---
APP_PORT=8050
DB_FORWARD_PORT=5432
REDIS_FORWARD_PORT=6379
PGADMIN_PORT=8080

# --- Xdebug Configuration ---
XDEBUG_MODE=off
XDEBUG_START=no
XDEBUG_CLIENT_HOST=host.docker.internal
```

### 5. Инициализация проекта

Запустите команду, которая соберет контейнеры, установит все зависимости и выполнит миграции:

```bash
make setup
```

После завершения:
- **Приложение:** http://localhost:8050
- **pgAdmin:** http://localhost:8080
- **Vite HMR:** http://localhost:5173

### 6. Работа со Swoole в разработке

В dev-режиме контейнер запускается с флагом `--watch`, который автоматически перезагружает воркеры при изменении PHP-файлов. Если автоматическая перезагрузка не срабатывает, можно перезагрузить вручную:

```bash
# Перезагрузить воркеры (быстро, без перезапуска контейнера)
make swoole-reload

# Посмотреть статус Swoole Octane
make swoole-status
```

> **Примечание:** Флаг `--watch` требует установленного пакета `chokidar` (устанавливается автоматически через npm внутри контейнера).

### 7. Xdebug

Для включения Xdebug измените в `.env`:

```dotenv
XDEBUG_MODE=debug
XDEBUG_START=yes
```

Затем пересоберите контейнер:

```bash
make rebuild
make up
```

---

## 🏭 Развертывание на Production

Этот boilerplate рассчитан на деплой через **Dokploy**.

### Настройка `.env.production`

Для локального запуска production-окружения через `make up-prod` создайте файл `.env.production` из шаблона:

```bash
cp .env.production.example .env.production
```

Этот файл используется для запуска `docker-compose.prod.local.yml`.

Проверьте и заполните в `.env.production` production-значения:

```dotenv
APP_NAME=LaravelSwoole
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:your-generated-key
APP_URL=https://your-domain.com
APP_BASE_PATH=/var/www/laravel
APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

LOG_CHANNEL=stack
LOG_STACK=single
LOG_LEVEL=info

DB_CONNECTION=pgsql
DB_HOST=laravel-postgres-sw
DB_PORT=5432
DB_DATABASE=your_db
DB_USERNAME=your_user
DB_PASSWORD=<strong_password>

SESSION_DRIVER=redis
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

CACHE_STORE=redis
QUEUE_CONNECTION=redis
BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local

REDIS_CLIENT=phpredis
REDIS_HOST=laravel-redis-sw
REDIS_PORT=6379
REDIS_PASSWORD=<strong_password>

OCTANE_SERVER=swoole
OCTANE_STATE_FILE=/var/www/laravel/storage/framework/octane-server-state.json
SWOOLE_WORKERS=2
SWOOLE_TASK_WORKERS=2
SWOOLE_MAX_REQUESTS=200
```

`APP_DEBUG=false` обязателен для production.  
`.env.production` не должен попадать в Git.

### Деплой в Dokploy

После создания проекта в Dokploy:

1. Перейдите в раздел **Environment -> Environment Settings**.
2. Добавьте в **Environment -> Environment Settings** **все** переменные из файла `.env.production`, кроме:

```dotenv
# Локальный порт для `make up-prod`
APP_PORT=8050
```

`APP_PORT` используется только для локального запуска production-окружения через `make up-prod`.
3. Для Preview-развертываний (если используются) измените переменные БД (например, добавьте префикс к имени БД), чтобы preview не затрагивал production-базу.
4. В настройках развертывания укажите команду Post-deployment:
    - `php artisan migrate --force && php artisan optimize:clear`

---

## 📋 Полный список Make-команд

| Команда                  | Описание                         |
|--------------------------|----------------------------------|
| `make help`              | Показать справку                 |
| `make setup`             | Полная инициализация проекта     |
| `make up`                | Запустить контейнеры (dev)       |
| `make up-prod`           | Запустить контейнеры (prod local)|
| `make down`              | Остановить контейнеры            |
| `make down-prod`         | Остановить контейнеры (prod local)|
| `make restart`           | Перезапустить контейнеры         |
| `make build`             | Собрать образы                   |
| `make rebuild`           | Пересобрать без кэша             |
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
| `make status`            | Статус контейнеров               |
| `make shell`             | Войти в контейнер приложения     |
| `make shell-prod`        | Войти в app-контейнер (prod local)|
| `make shell-postgres`    | PostgreSQL CLI (dev)             |
| `make shell-postgres-prod`| PostgreSQL CLI (prod local)     |
| `make shell-redis`       | Redis CLI (dev)                  |
| `make shell-redis-prod`  | Redis CLI (prod local)           |
| `make shell-queue-prod`  | Shell queue worker (prod local)  |
| `make shell-scheduler-prod`| Shell scheduler (prod local)   |
| `make swoole-reload`     | Перезагрузить воркеры Swoole     |
| `make swoole-status`     | Статус Swoole Octane             |
| `make artisan CMD="..."` | Artisan-команда                  |
| `make migrate`           | Запустить миграции               |
| `make fresh`             | Пересоздать БД + сиды            |
| `make test-php`          | Запустить тесты                  |
| `make validate`          | Проверить доступность сервисов   |
| `make info`              | Информация о проекте             |
| `make clean`             | Удалить контейнеры и тома        |
| `make clean-all`         | Полная очистка                   |
