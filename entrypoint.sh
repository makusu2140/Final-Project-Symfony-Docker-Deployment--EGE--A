#!/bin/bash
set -e

echo "==> Preparing production runtime directories..."
mkdir -p /var/www/html/var/cache /var/www/html/var/log /etc/nginx/conf.d /run/nginx
chown -R www-data:www-data /var/www/html/var

echo "==> Injecting custom Nginx configurations..."
# This moves your config file to the place your main nginx.conf is searching for!
cp nginx-main.conf /etc/nginx/conf.d/default.conf

echo "==> Force running pending database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod || echo "⚠️ Migration skipped or DB connection pending."

echo "==> Starting PHP-FPM daemon..."
php-fpm -D

echo "==> Starting Nginx Web Server..."
exec nginx -g "daemon off;"