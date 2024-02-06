# syntax=docker/dockerfile:1
FROM composer:2 AS build

WORKDIR /app/
COPY . .
RUN composer install --no-dev --ignore-platform-reqs --optimize-autoloader

FROM php:8.3-alpine
WORKDIR /app/
# recommended: install optional extensions ext-ev and ext-sockets
RUN apk --no-cache add ${PHPIZE_DEPS} libev linux-headers \
    && pecl install ev \
    && docker-php-ext-enable ev \
    && docker-php-ext-install sockets \
    && apk del ${PHPIZE_DEPS} linux-headers \
    && echo "memory_limit = -1" >> "$PHP_INI_DIR/conf.d/acme.ini"

COPY . .
# COPY src/ src/
COPY --from=build /app/vendor/ vendor/
RUN mkdir -p /var/cache/prod/ \
    && chown -R nobody:nobody /var/cache/prod/ \
    && chmod -R 777 /var/cache/prod/ \
    && chown -R nobody:nobody /var/log/ \
    && chmod -R 777 /var/log/

ENV X_LISTEN 0.0.0.0:8080
EXPOSE 8080

USER nobody:nobody
ENTRYPOINT ["bin/freddie"]
