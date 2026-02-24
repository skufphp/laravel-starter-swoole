# ==============================================================================
# Многоэтапный образ PHP + Swoole — PHP 8.5 Alpine (Laravel Octane)
# ==============================================================================
# Назначение:
# - Сборка фронтенда (Node.js)
# - Базовая среда PHP с расширением Swoole
# - Поддержка Xdebug для разработки
# - Оптимизированный Production образ
#
# Context: корень проекта (.)
# ==============================================================================

FROM node:24-alpine AS frontend-build

WORKDIR /app

# Ставим зависимости фронта отдельно для лучшего кеширования
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Копируем проект и собираем ассеты
COPY . ./
RUN npm run build

# ==============================================================================
# Базовая среда PHP с Swoole — используется для разработки и как основа для продакшена
# ==============================================================================
FROM phpswoole/swoole:php8.5-alpine AS php-base

# 1) Зависимости времени выполнения + Зависимости для сборки (удалим после компиляции)
RUN set -eux; \
    apk add --no-cache \
      curl git zip unzip \
      icu-libs libzip libpng libjpeg-turbo freetype postgresql-libs libxml2 oniguruma \
      openssl c-ares libstdc++ \
    && apk add --no-cache --virtual .build-deps \
      $PHPIZE_DEPS linux-headers \
      icu-dev libzip-dev libpng-dev libjpeg-turbo-dev freetype-dev \
      postgresql-dev libxml2-dev oniguruma-dev \
      openssl-dev c-ares-dev curl-dev

# 2) PHP расширения
RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
      pdo \
      pdo_pgsql \
      pgsql \
      mbstring \
      xml \
      gd \
      bcmath \
      zip \
      intl \
      sockets \
      pcntl

# 3) PIE (PHP Installer for Extensions) + Xdebug (только для разработки)
COPY --from=ghcr.io/php/pie:bin /pie /usr/bin/pie

ARG INSTALL_XDEBUG=false
RUN set -eux; \
    if [ "${INSTALL_XDEBUG}" = "true" ]; then \
      pie install xdebug/xdebug; \
      docker-php-ext-enable xdebug; \
    fi

# 5) Очистка временных файлов
RUN set -eux; \
    apk del .build-deps; \
    rm -rf /tmp/pear ~/.pearrc /var/cache/apk/*

# 6) Конфигурация php.ini (dev по умолчанию, prod переопределяется в production stage)
COPY docker/php/php.ini /usr/local/etc/php/conf.d/local.ini

# 7) Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/laravel

# Создаём пользователя www-data (если не существует) и назначаем права
RUN addgroup -g 82 -S www-data 2>/dev/null || true; \
    adduser -u 82 -D -S -G www-data www-data 2>/dev/null || true; \
    chown -R www-data:www-data /var/www/laravel

# Graceful shutdown: Swoole корректно завершает воркеры по SIGTERM
STOPSIGNAL SIGTERM

EXPOSE 8000

USER www-data

CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000"]

# ==============================================================================
# Production образ: код + vendor + собранные ассеты (идеально для деплоя)
# ==============================================================================
FROM php-base AS production

# Переключаемся на root для установки зависимостей
USER root

WORKDIR /var/www/laravel

# Копируем php.ini для продакшена (перезаписываем dev-версию)
COPY docker/php/php.prod.ini /usr/local/etc/php/conf.d/local.ini

# Копируем composer-файлы отдельно для кеширования слоя vendor
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts --no-progress

# Копируем весь проект
COPY . ./

# Копируем собранные ассеты из frontend-build
COPY --from=frontend-build /app/public/build /var/www/laravel/public/build

# Финализация composer (post-install scripts)
RUN composer dump-autoload --optimize --no-dev

# Кешируем конфигурацию, маршруты и представления Laravel
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && php artisan event:cache

# Назначаем права и переключаемся на www-data
RUN chown -R www-data:www-data /var/www/laravel
USER www-data
