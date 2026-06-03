#!/bin/bash
set -e

echo "==> Preparing production runtime directories and permissions..."
mkdir -p /var/www/html/var/cache /var/www/html/var/log /etc/nginx/conf.d /run/nginx
chown -R www-data:www-data /var/www/html

echo "==> Hard clearing cached build remnants..."
rm -rf /var/www/html/var/cache/*

echo "==> Compiling and warming up production cache..."
# This forces Symfony to build its routing table using Railway variables
php bin/console cache:warmup --env=prod

echo "==> Purging default Nginx configuration structures..."
rm -rf /etc/nginx/conf.d/*
rm -rf /etc/nginx/sites-enabled/*
rm -rf /etc/nginx/sites-available/*

echo "==> Overwriting master Nginx configuration..."
cp nginx-production.conf /etc/nginx/nginx.conf

echo "==> Force running pending database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod || echo "⚠️ Migration skipped or DB connection pending."

echo "==> Starting PHP Internal Server on Port 8000..."
php -S 0.0.0.0:8000 -t /var/www/html/public > /var/log/php_server.log 2>&1 &

echo "==> Giving the PHP back-end a moment to wake up..."
sleep 2

echo "==> Starting Nginx Web Server..."
exec nginx -g "daemon off;"