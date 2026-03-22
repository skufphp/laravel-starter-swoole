# ==========================================
# Laravel Octane + Swoole (Boilerplate)
# ==========================================
.PHONY: \
	help check-files check-files-prod \
	up up-prod down down-prod restart build rebuild rebuild-prod \
	logs logs-prod logs-app logs-app-prod logs-postgres logs-postgres-prod logs-pgadmin logs-node logs-redis logs-redis-prod logs-queue logs-queue-prod logs-scheduler logs-scheduler-prod \
	status \
	shell shell-prod shell-node shell-postgres shell-postgres-prod shell-redis shell-redis-prod shell-queue shell-queue-prod shell-scheduler shell-scheduler-prod \
	setup install-deps \
	composer-install composer-update composer-require \
	npm-install npm-dev npm-build \
	artisan composer migrate rollback fresh tinker test-php \
	swoole-reload swoole-status \
	permissions info validate \
	clean clean-all dev-reset clean-prod clean-all-prod prod-reset

# Цвета для вывода
YELLOW=\033[0;33m
GREEN=\033[0;32m
RED=\033[0;31m
NC=\033[0m

# Переменные Compose
COMPOSE = docker compose -f docker-compose.yml
COMPOSE_PROD = docker compose --env-file .env.production -f docker-compose.prod.local.yml

APP_PORT := $(shell grep '^APP_PORT=' .env 2>/dev/null | cut -d '=' -f 2- | tr -d '[:space:]')
ifeq ($(APP_PORT),)
APP_PORT := 8050
endif

# Сервисы (имена сервисов из compose-файлов)
APP_SERVICE=laravel-swoole
POSTGRES_SERVICE=laravel-postgres-sw
REDIS_SERVICE=laravel-redis-sw
PGADMIN_SERVICE=laravel-pgadmin-sw
NODE_SERVICE=laravel-node-sw
QUEUE_SERVICE=laravel-queue-sw
SCHEDULER_SERVICE=laravel-scheduler-sw

help: ## Показать справку
	@echo "$(YELLOW)Laravel Octane + Swoole Docker Boilerplate$(NC)"
	@echo "======================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

check-files: ## Проверить наличие всех необходимых файлов
	@echo "$(YELLOW)Проверка файлов конфигурации...$(NC)"
	@test -f docker-compose.yml || (echo "$(RED)✗ docker-compose.yml не найден$(NC)" && exit 1)
	@test -f docker-compose.prod.yml || (echo "$(RED)✗ docker-compose.prod.yml не найден$(NC)" && exit 1)
	@test -f .env || (echo "$(RED)✗ .env не найден. Убедитесь, что вы настроили проект Laravel$(NC)" && exit 1)
	@test -f docker/php.Dockerfile || (echo "$(RED)✗ docker/php.Dockerfile не найден$(NC)" && exit 1)
	@test -f docker/php/php.ini || (echo "$(RED)✗ docker/php/php.ini не найден$(NC)" && exit 1)
	@echo "$(GREEN)✓ Все файлы на месте$(NC)"

check-files-prod: ## Проверить наличие всех необходимых файлов
	@echo "$(YELLOW)Проверка файлов конфигурации...$(NC)"
	@test -f docker-compose.prod.local.yml || (echo "$(RED)✗ docker-compose.prod.local.yml не найден$(NC)" && exit 1)
	@test -f .env.production || (echo "$(RED)✗ .env.production не найден. Создайте его из .env.production.example$(NC)" && exit 1)
	@test -f docker/php.Dockerfile || (echo "$(RED)✗ docker/php.Dockerfile не найден$(NC)" && exit 1)
	@test -f docker/php/php.prod.ini || (echo "$(RED)✗ docker/php/php.prod.ini не найден$(NC)" && exit 1)
	@echo "$(GREEN)✓ Все файлы на месте$(NC)"

up: check-files ## Запустить контейнеры (Dev)
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Проект запущен на http://localhost:$(APP_PORT)$(NC)"

up-prod: check-files-prod ## Запустить контейнеры (Prod)
	$(COMPOSE_PROD) up -d
	@echo "$(GREEN)✓ Проект (Prod) запущен$(NC)"

down: ## Остановить контейнеры
	$(COMPOSE) down

down-prod: ## Остановить контейнеры (Prod)
	$(COMPOSE_PROD) down

restart: ## Перезапустить контейнеры
	$(COMPOSE) restart

build: ## Собрать образы (Dev)
	$(COMPOSE) build

rebuild: ## Пересобрать образы без кэша (Dev)
	$(COMPOSE) build --no-cache

rebuild-prod: ## Пересобрать prod образы без кэша
	$(COMPOSE_PROD) build --no-cache

logs: ## Показать логи всех сервисов
	$(COMPOSE) logs -f

logs-prod: ## Показать логи всех сервисов (Prod)
	$(COMPOSE_PROD) logs -f

logs-app: ## Просмотр логов Swoole
	$(COMPOSE) logs -f $(APP_SERVICE)

logs-app-prod: ## Просмотр логов Swoole (Prod)
	$(COMPOSE_PROD) logs -f $(APP_SERVICE)

logs-postgres: ## Просмотр логов PostgreSQL
	$(COMPOSE) logs -f $(POSTGRES_SERVICE)

logs-postgres-prod: ## Просмотр логов PostgreSQL (Prod)
	$(COMPOSE_PROD) logs -f $(POSTGRES_SERVICE)

logs-pgadmin: ## Просмотр логов pgAdmin
	$(COMPOSE) logs -f $(PGADMIN_SERVICE)

logs-node: ## Просмотр логов Node (HMR)
	$(COMPOSE) logs -f $(NODE_SERVICE)

logs-redis: ## Просмотр логов Redis
	$(COMPOSE) logs -f $(REDIS_SERVICE)

logs-redis-prod: ## Просмотр логов Redis (Prod)
	$(COMPOSE_PROD) logs -f $(REDIS_SERVICE)

logs-queue: ## Просмотр логов Queue Worker (Dev)
	$(COMPOSE) logs -f $(QUEUE_SERVICE)

logs-queue-prod: ## Просмотр логов Queue Worker (Prod)
	$(COMPOSE_PROD) logs -f $(QUEUE_SERVICE)

logs-scheduler: ## Просмотр логов Scheduler (Dev)
	$(COMPOSE) logs -f $(SCHEDULER_SERVICE)

logs-scheduler-prod: ## Просмотр логов Scheduler (Prod)
	$(COMPOSE_PROD) logs -f $(SCHEDULER_SERVICE)

status: ## Статус контейнеров
	$(COMPOSE) ps

shell: ## Войти в контейнер приложения (Swoole)
	$(COMPOSE) exec $(APP_SERVICE) sh

shell-prod: ## Войти в контейнер приложения (Prod)
	$(COMPOSE_PROD) exec $(APP_SERVICE) sh

shell-node: ## Подключиться к контейнеру Node
	$(COMPOSE) exec $(NODE_SERVICE) sh

shell-queue: ## Войти в контейнер Queue Worker
	$(COMPOSE) exec $(QUEUE_SERVICE) sh

shell-queue-prod: ## Войти в контейнер Queue Worker (Prod)
	$(COMPOSE_PROD) exec $(QUEUE_SERVICE) sh

shell-scheduler: ## Войти в контейнер Scheduler
	$(COMPOSE) exec $(SCHEDULER_SERVICE) sh

shell-scheduler-prod: ## Войти в контейнер Scheduler (Prod)
	$(COMPOSE_PROD) exec $(SCHEDULER_SERVICE) sh

shell-postgres: ## Подключиться к PostgreSQL CLI
	@echo "$(YELLOW)Подключение к базе...$(NC)"
	@DB_USER=$$(grep '^DB_USERNAME=' .env | cut -d '=' -f 2- | tr -d '[:space:]'); \
	DB_NAME=$$(grep '^DB_DATABASE=' .env | cut -d '=' -f 2- | tr -d '[:space:]'); \
	$(COMPOSE) exec $(POSTGRES_SERVICE) psql -U $$DB_USER -d $$DB_NAME

shell-postgres-prod: ## Подключиться к PostgreSQL CLI (Prod)
	@echo "$(YELLOW)Подключение к базе (Prod)...$(NC)"
	@DB_USER=$$(grep '^DB_USERNAME=' .env.production | cut -d '=' -f 2- | tr -d '[:space:]'); \
	DB_NAME=$$(grep '^DB_DATABASE=' .env.production | cut -d '=' -f 2- | tr -d '[:space:]'); \
	$(COMPOSE_PROD) exec $(POSTGRES_SERVICE) psql -U $$DB_USER -d $$DB_NAME

shell-redis: ## Подключиться к Redis CLI
	@echo "$(YELLOW)Подключение к Redis...$(NC)"
	$(COMPOSE) exec $(REDIS_SERVICE) redis-cli ping

shell-redis-prod: ## Подключиться к Redis CLI (Prod)
	@echo "$(YELLOW)Подключение к Redis (Prod)...$(NC)"
	$(COMPOSE_PROD) exec $(REDIS_SERVICE) redis-cli ping

# --- Команды Laravel ---

setup: ## Полная инициализация проекта с нуля
	@make build
	@make up
	@echo "$(YELLOW)Ожидание готовности PostgreSQL...$(NC)"
	@$(COMPOSE) exec $(POSTGRES_SERVICE) sh -c 'until pg_isready; do sleep 1; done'
	@echo "$(YELLOW)Ожидание готовности Redis...$(NC)"
	@$(COMPOSE) exec $(REDIS_SERVICE) sh -c 'until redis-cli ping | grep -q PONG; do sleep 1; done'
	@make install-deps
	@make artisan CMD="key:generate"
	@make migrate
	@make permissions
	@echo "$(GREEN)✓ Проект готов: http://localhost:$(APP_PORT)$(NC)"

install-deps: ## Установка всех зависимостей (Composer + NPM)
	@echo "$(YELLOW)Установка зависимостей...$(NC)"
	@$(MAKE) composer-install
	@$(MAKE) npm-install

# --- Команды Composer ---

composer-install: ## Установить зависимости через Composer
	$(COMPOSE) exec $(APP_SERVICE) composer install

composer-update: ## Обновить зависимости через Composer
	$(COMPOSE) exec $(APP_SERVICE) composer update

composer-require: ## Установить пакет через Composer (make composer-require PACKAGE=vendor/package)
	$(COMPOSE) exec $(APP_SERVICE) composer require $(PACKAGE)

npm-install: ## Установить NPM зависимости
	$(COMPOSE) exec $(NODE_SERVICE) npm install

npm-dev: ## Запустить Vite в режиме разработки (hot reload)
	$(COMPOSE) exec $(NODE_SERVICE) npm run dev

npm-build: ## Собрать фронтенд
	$(COMPOSE) exec $(NODE_SERVICE) npm run build

# --- Команды Artisan ---

artisan: ## Запустить команду artisan (make artisan CMD="migrate")
	$(COMPOSE) exec $(APP_SERVICE) php artisan $(CMD)

composer: ## Запустить команду composer (make composer CMD="install")
	$(COMPOSE) exec $(APP_SERVICE) composer $(CMD)

migrate: ## Запустить миграции
	$(COMPOSE) exec $(APP_SERVICE) php artisan migrate

rollback: ## Откатить миграции
	$(COMPOSE) exec $(APP_SERVICE) php artisan migrate:rollback

fresh: ## Пересоздать базу и запустить сиды
	$(COMPOSE) exec $(APP_SERVICE) php artisan migrate:fresh --seed

tinker: ## Запустить Laravel Tinker
	$(COMPOSE) exec $(APP_SERVICE) php artisan tinker

test-php: ## Запустить тесты PHP (PHPUnit)
	$(COMPOSE) exec $(APP_SERVICE) php artisan test

# --- Swoole / Octane ---

swoole-reload: ## Перезагрузить воркеры Swoole Octane (без перезапуска контейнера)
	$(COMPOSE) exec $(APP_SERVICE) php artisan octane:reload

swoole-status: ## Показать статус Swoole Octane
	$(COMPOSE) exec $(APP_SERVICE) php artisan octane:status

# --- Утилиты ---

permissions: ## Исправить права доступа для Laravel (storage/cache)
	@echo "$(YELLOW)Исправление прав доступа...$(NC)"
	$(COMPOSE) exec $(APP_SERVICE) sh -c "if [ -d storage ]; then chown -R www-data:www-data storage bootstrap/cache && chmod -R ug+rwX storage bootstrap/cache; fi"
	@echo "$(GREEN)✓ Права доступа исправлены$(NC)"

info: ## Показать информацию о проекте
	@echo "$(YELLOW)Laravel Octane + Swoole Development Environment$(NC)"
	@echo "======================================"
	@echo "$(GREEN)Сервисы:$(NC)"
	@echo "  • PHP 8.5 CLI + Swoole (Alpine)"
	@echo "  • PostgreSQL 18.2"
	@echo "  • Redis"
	@echo "  • pgAdmin 4 (dev only)"
	@echo "  • Node.js (Vite HMR, dev only)"
	@echo ""
	@echo "$(GREEN)Структура:$(NC)"
	@echo "  • docker/           - Dockerfile и конфиги PHP"
	@echo "  • .env              - единый файл настроек (Laravel + Docker)"
	@echo ""
	@echo "$(GREEN)Порты:$(NC)"
	@echo "  • $(APP_PORT) - Swoole Octane (HTTP Server)"
	@echo "  • 5173 - Vite HMR (dev only)"
	@echo "  • 5432 - PostgreSQL (dev forwarded)"
	@echo "  • 6379 - Redis (dev forwarded)"
	@echo "  • 8080 - pgAdmin (dev only)"

validate: ## Проверить доступность сервисов по HTTP
	@echo "$(YELLOW)Проверка работы сервисов...$(NC)"
	@echo -n "Swoole Octane (http://localhost:$(APP_PORT)): "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:$(APP_PORT) && echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo -n "pgAdmin (http://localhost:8080): "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 && echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo "$(YELLOW)Статус контейнеров:$(NC)"
	@$(COMPOSE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

clean: ## Удалить контейнеры и тома (Dev)
	$(COMPOSE) down -v
	@echo "$(RED)! Контейнеры и данные БД удалены$(NC)"

clean-all: ## Полная очистка dev (контейнеры, образы, тома)
	@echo "$(YELLOW)Полная очистка dev...$(NC)"
	$(COMPOSE) down -v --rmi all
	@echo "$(GREEN)✓ Выполнена полная очистка dev$(NC)"

dev-reset: clean-all build up ## Сброс среды разработки
	@echo "$(GREEN)✓ Среда разработки сброшена и перезапущена!$(NC)"

clean-prod: ## Удалить prod контейнеры и тома
	$(COMPOSE_PROD) down -v
	@echo "$(RED)! Prod контейнеры и данные БД удалены$(NC)"

clean-all-prod: ## Полная очистка prod (контейнеры, образы, тома)
	@echo "$(YELLOW)Полная очистка prod...$(NC)"
	$(COMPOSE_PROD) down -v --rmi all
	@echo "$(GREEN)✓ Выполнена полная очистка prod$(NC)"

prod-reset: clean-all-prod rebuild-prod up-prod ## Сброс prod среды
	@echo "$(GREEN)✓ Prod среда сброшена и перезапущена!$(NC)"

.DEFAULT_GOAL := help
