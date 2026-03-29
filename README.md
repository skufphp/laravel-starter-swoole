# Laravel Boilerplate (Laravel Octane + Swoole + PostgreSQL + Redis)

Этот репозиторий представляет собой **универсальный boilerplate** для развертывания Laravel-проектов с использованием **Laravel Octane** и **Swoole** в Docker-окружении.

## 🚀 Основные возможности

*   **Высокая производительность:** Приложение работает через **Swoole HTTP Server** без отдельного Nginx/Apache и без повторного bootstrap Laravel на каждый запрос.
*   **Современный стек:**
    *   **PHP 8.5 (Alpine)** — свежая версия PHP с готовым runtime для Laravel Octane.
    *   **Swoole** — встроенный HTTP-сервер и менеджер persistent workers + coroutines для Octane.
    *   **PostgreSQL 18.2** — основная база данных.
    *   **Redis 8.6** — кеш, очереди и сессии.
    *   **Node.js 24** — для сборки фронтенда (Vite) с поддержкой Hot Module Replacement (HMR).
*   **Разделение окружений:** Готовые конфигурации для **Development** (монтирование кода, HMR, pgAdmin) и **Production** (multi-stage сборка, immutable image, отдельные queue/scheduler-сервисы).
*   **Инструменты разработки:**
    *   **pgAdmin 4** — веб-интерфейс для PostgreSQL (только в dev).
    *   **Xdebug** — предустановлен и включается через `.env`.
    *   **Makefile** — автоматизация сборки, запуска, логов, artisan-команд и операций Swoole Octane.
*   **Production Ready:** Отдельные compose-конфигурации для локального production-запуска и дальнейшей интеграции в CI/CD или Dokploy.

## 📂 Структура проекта

*   `docker/` — Dockerfile и конфигурационные файлы PHP.
*   `docker-compose.yml` — базовая конфигурация сервисов и разработка.
*   `docker-compose.prod.yml` — прод-конфигурация сервисов.
*   `docker-compose.prod.local.yml` — настройки для локального запуска продакшена.
*   `Makefile` — главный пульт управления проектом.

## 🛠 Быстрый старт (Development)

1.  Клонируйте репозиторий в корень вашего Laravel-проекта.
2.  Установите и настройте Laravel Octane под Swoole:
    ```bash
    composer require laravel/octane
    php artisan octane:install
    ```
3.  Настройте файлы окружения:
    ```bash
    cp .env.example .env
    ```
    *(Убедитесь, что параметры БД, Redis и Octane в `.env` соответствуют именам сервисов в docker-compose.)*
4.  Запустите полную инициализацию:
    ```bash
    make setup
    ```
    Эта команда соберет образы, запустит контейнеры, установит зависимости (Composer & NPM), создаст `APP_KEY`, выполнит миграции и настроит права доступа.

## 💻 Основные команды (Makefile)

*   `make up` — запустить проект в dev-режиме.
*   `make up-prod` — запустить проект в prod-режиме локально.
*   `make down` — остановить контейнеры.
*   `make setup` — полная инициализация проекта.
*   `make artisan CMD="migrate"` — выполнить artisan-команду.
*   `make shell` — войти в консоль app-контейнера.
*   `make shell-redis` — проверить доступность Redis.
*   `make npm-dev` — подключиться к Vite dev server.
*   `make swoole-reload` — перезагрузить воркеры Swoole после изменения PHP-кода.
*   `make swoole-status` — проверить состояние Swoole Octane.
*   `make info` — показать информацию о портах и сервисах.
*   `make logs` — просмотр логов всех сервисов.

## 🔗 Доступы (Default)

*   **Web-сайт:** [http://localhost:8050](http://localhost:8050)
*   **pgAdmin:** [http://localhost:8080](http://localhost:8080)
*   **Postgres:** `localhost:5432` (снаружи, если не переопределено в `.env`)
*   **Redis:** `localhost:6379` (снаружи, если не переопределено в `.env`)

---
*Подробная инструкция по установке и настройке находится в [SETUP.md](SETUP.md).*
