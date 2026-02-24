# Инструкция по установке Laravel Octane + Swoole Boilerplate

Этот boilerplate предназначен для быстрого развертывания Laravel-проекта с архитектурой **Laravel Octane + Swoole + PostgreSQL + Redis + pgAdmin**.

## Для каких приложений подходит эта архитектура

### ✅ 1. Высоконагруженные API

**Идеальный кейс для Swoole**

* REST / GraphQL API с высоким RPS
* Микросервисы
* Real-time приложения (WebSocket через Swoole)

**Почему Swoole:** Persistent workers + корутины — приложение загружается один раз и обрабатывает тысячи запросов без повторного bootstrap. Корутины Swoole позволяют выполнять асинхронный I/O (запросы к БД, HTTP-вызовы) без блокировки воркера.

---

### ✅ 2. Blade / Livewire / Inertia приложения

* Blade templates + Server-side rendering
* Livewire
* Inertia + Vue/React

**Почему подходит:** Laravel Octane полностью совместим с Blade, Livewire и Inertia. Получаете прирост производительности без изменения кода.

---

### ✅ 3. SaaS-панели и админки

* CRM / ERP системы
* Internal tools
* Корпоративные порталы

---

### ⚠️ Важно: особенности Octane

При работе с Laravel Octane нужно учитывать, что **приложение живёт между запросами**:

* Не храните состояние в статических свойствах классов
* Используйте `Octane::concurrently()` для параллельных задач
* Будьте осторожны с singleton-сервисами — они переиспользуются между запросами
* Подробнее: [Laravel Octane Documentation](https://laravel.com/docs/octane)

---

## 🚀 Процесс установки для разработки

### 1. Создание проекта Laravel

Создайте новый проект Laravel:

```bash
composer create-project laravel/laravel my-app
cd my-app
```

### 2. Установка Laravel Octane

```bash
composer require laravel/octane
php artisan octane:install --server=swoole
```

> **Примечание:** В отличие от RoadRunner, Swoole — это PHP-расширение (C-extension), а не отдельный бинарный файл. Оно уже установлено в Docker-образе из этого boilerplate. Локально устанавливать Swoole не нужно — всё работает внутри контейнера.

### 3. Копирование файлов boilerplate

Скопируйте следующие файлы и папки из данного boilerplate в корень вашего нового проекта Laravel:

* Папку `docker/` (включая все подпапки и файлы)
* Файлы `docker-compose.yml`, `docker-compose.dev.yml`, `docker-compose.prod.yml`
* Файл `Makefile`
* Файл `.dockerignore`

### 4. Настройка окружения (.env)

Откройте файл `.env` в корне Laravel и выполните следующие изменения:

**a) Настройте подключение к БД:**

```dotenv
DB_CONNECTION=pgsql
DB_HOST=laravel-postgres-sw
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=postgres
DB_PASSWORD=root
```

**b) Настройте Redis:**

```dotenv
REDIS_HOST=laravel-redis-sw
REDIS_PORT=6379
REDIS_PASSWORD=
```

**c) Настройте Octane:**

```dotenv
OCTANE_SERVER=swoole
```

**d) Добавьте в конец `.env` секцию из файла `.env.docker`:**

```dotenv
# --- pgAdmin Web Interface ---
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=admin

# --- Docker ports ---
APP_PORT=8000
DB_FORWARD_PORT=5432
REDIS_FORWARD_PORT=6379
PGADMIN_PORT=8080

# --- Xdebug Configuration ---
XDEBUG_MODE=off
XDEBUG_START=no
XDEBUG_CLIENT_HOST=host.docker.internal

# --- Swoole / Octane Configuration ---
OCTANE_WORKERS=2
OCTANE_TASK_WORKERS=2
OCTANE_MAX_REQUESTS=250
```

### 5. Инициализация проекта

Запустите команду, которая соберет контейнеры, установит все зависимости и выполнит миграции:

```bash
make setup
```

После завершения:
- **Приложение:** http://localhost:8000
- **pgAdmin:** http://localhost:8080
- **Vite HMR:** http://localhost:5173

### 6. Работа с Swoole в разработке

В dev-режиме контейнер запускается с флагом `--watch`, который автоматически перезагружает воркеры при изменении PHP-файлов. Если автоматическая перезагрузка не срабатывает, можно перезагрузить вручную:

```bash
# Перезагрузить воркеры (быстро, без перезапуска контейнера)
make octane-reload

# Посмотреть статус Swoole Octane
make octane-status
```

> **Примечание:** Флаг `--watch` требует установленного пакета `chokidar` (устанавливается автоматически через npm). Если `--watch` не работает, используйте `make octane-reload` после изменений PHP-кода.

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

### Архитектура Production

В продакшене используется **production stage** из Dockerfile — образ содержит весь код, vendor и собранные ассеты. Никаких volume-монтирований.

Дополнительные сервисы:
- **Queue Worker** — обработка очередей Laravel
- **Scheduler** — планировщик задач (замена cron)
- **Migrate** — одноразовый контейнер для миграций при деплое

### 1. Сборка Production-образа

```bash
# Сборка образа с тегом
docker build \
  -f docker/php.Dockerfile \
  --target production \
  -t your-registry.com/app:latest \
  .

# Пуш в registry
docker push your-registry.com/app:latest
```

### 2. Настройка Production .env

```dotenv
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

# БД
DB_CONNECTION=pgsql
DB_HOST=laravel-postgres-sw
DB_PORT=5432
DB_DATABASE=your_db
DB_USERNAME=your_user
DB_PASSWORD=<strong_password>

# Redis
REDIS_HOST=laravel-redis-sw
REDIS_PORT=6379

# Octane
OCTANE_SERVER=swoole

# Swoole
OCTANE_WORKERS=8
OCTANE_TASK_WORKERS=4
OCTANE_MAX_REQUESTS=500

# Registry (для docker-compose.prod.yml)
CI_REGISTRY_IMAGE=your-registry.com
IMAGE_TAG=latest
```

### 3. Запуск на сервере

```bash
# Скопируйте на сервер:
# - docker-compose.yml
# - docker-compose.prod.yml
# - .env (с production-настройками)

# Запуск
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Миграции выполнятся автоматически через сервис migrate
```

### 4. Production Checklist

- [ ] `APP_ENV=production`, `APP_DEBUG=false`
- [ ] Сильные пароли для БД и Redis
- [ ] `OCTANE_WORKERS` = количество ядер CPU
- [ ] HTTPS терминируется на reverse proxy (Traefik, Caddy, Nginx) перед Swoole
- [ ] Health check настроен: `http://app:8000/up`
- [ ] Queue worker и Scheduler запущены
- [ ] Бэкапы PostgreSQL настроены
- [ ] `.env` файл **не** в Git, передаётся через CI/CD secrets

### 5. CI/CD (GitLab CI пример)

```yaml
stages:
  - build
  - deploy

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -f docker/php.Dockerfile --target production -t $CI_REGISTRY_IMAGE/app:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE/app:$CI_COMMIT_SHA

deploy:
  stage: deploy
  script:
    - ssh deploy@server "cd /app && IMAGE_TAG=$CI_COMMIT_SHA docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
```

### 6. Reverse Proxy (HTTPS)

Swoole слушает на порту 8000 (HTTP). Для HTTPS используйте reverse proxy перед ним.

**Пример с Caddy (рекомендуется — автоматический HTTPS):**

```
your-domain.com {
    reverse_proxy laravel-swoole:8000
}
```

**Пример с Nginx:**

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/ssl/cert.pem;
    ssl_certificate_key /etc/ssl/key.pem;

    location / {
        proxy_pass http://laravel-swoole:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 📋 Полный список Make-команд

| Команда | Описание |
|---------|----------|
| `make help` | Показать справку |
| `make setup` | Полная инициализация проекта |
| `make up` | Запустить контейнеры (dev) |
| `make up-prod` | Запустить контейнеры (prod) |
| `make down` | Остановить контейнеры |
| `make restart` | Перезапустить контейнеры |
| `make build` | Собрать образы |
| `make rebuild` | Пересобрать без кэша |
| `make logs` | Логи всех сервисов |
| `make logs-app` | Логи Swoole |
| `make status` | Статус контейнеров |
| `make shell` | Войти в контейнер приложения |
| `make shell-postgres` | PostgreSQL CLI |
| `make octane-reload` | Перезагрузить воркеры Swoole |
| `make octane-status` | Статус Swoole Octane |
| `make artisan CMD="..."` | Artisan-команда |
| `make migrate` | Запустить миграции |
| `make fresh` | Пересоздать БД + сиды |
| `make test-php` | Запустить тесты |
| `make validate` | Проверить доступность сервисов |
| `make info` | Информация о проекте |
| `make clean` | Удалить контейнеры и тома |
| `make clean-all` | Полная очистка |
