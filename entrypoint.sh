#!/bin/bash
set -e

echo "==> Clearing and warming up production caches..."
php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod

echo "==> Running pending database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod || true

echo "==> Starting PHP-FPM daemon..."
php-fpm -D

echo "==> Starting Nginx Web Server..."
exec nginx -g "daemon off;"