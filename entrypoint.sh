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
# This replaces the master config file directly!
cp nginx-production.conf /etc/nginx/nginx.conf

# Find the exact PHP-FPM binary name dynamically
FPM_BIN=$(which php-fpm || which php-fpm8.3 || which php-fpm8.2 || which php-fpm8.1 || find /usr/sbin /usr/bin -name "php-fpm*" | head -n 1)

echo "==> Forcing PHP-FPM to listen on TCP Port 9000..."
find /etc/ -name "www.conf" -exec sed -i 's|^listen = .*|listen = 127.0.0.1:9000|g' {} + 2>/dev/null || true

echo "==> Force running pending database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod || echo "⚠️ Migration skipped or DB connection pending."

echo "==> Starting PHP-FPM daemon..."
$FPM_BIN -d "listen=127.0.0.1:9000" -d "security.limit_extensions=.php" -D

echo "==> Starting Nginx Web Server..."
exec nginx -g "daemon off;"