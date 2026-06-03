#!/bin/bash
set -e

echo "==> Preparing production runtime directories..."
mkdir -p /var/www/html/var/cache /var/www/html/var/log
chown -R www-data:www-data /var/www/html/var

echo "==> Force running pending database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod || echo "⚠️ Migration skipped or DB connection pending."

echo "==> Starting PHP-FPM daemon..."
php-fpm -D

echo "==> Starting Nginx Web Server..."
exec nginx -g "daemon off;"