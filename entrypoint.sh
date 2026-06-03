#!/bin/bash
set -e

echo "==> Preparing production runtime directories and permissions..."
mkdir -p /var/www/html/var/cache /var/www/html/var/log /etc/nginx/conf.d /run/nginx
chown -R www-data:www-data /var/www/html

echo "==> Purging default Nginx configuration structures..."
rm -rf /etc/nginx/conf.d/*
rm -rf /etc/nginx/sites-enabled/*
rm -rf /etc/nginx/sites-available/*

echo "==> Overwriting master Nginx configuration..."
cp nginx-production.conf /etc/nginx/nginx.conf

echo "==> Force running pending database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod || echo "⚠️ Migration skipped or DB connection pending."

echo "==> Starting PHP Internal Server on Port 8000..."
# Start the built-in PHP server pointing to Symfony's public directory in the background
php -S 127.0.0.1:8000 -t /var/www/html/public &

echo "==> Starting Nginx Web Server..."
exec nginx -g "daemon off;"