#!/bin/bash
set -e

echo "==> Preparing production runtime directories..."
mkdir -p /var/www/html/var/cache /var/www/html/var/log /etc/nginx/conf.d /run/nginx
chown -R www-data:www-data /var/www/html/var

echo "==> Injecting custom Nginx configurations..."
cp nginx-main.conf /etc/nginx/conf.d/default.conf

echo "==> Forcing PHP-FPM to listen on TCP Port 9000..."
# This loops through common PHP-FPM pool configurations and overrides the socket setting to port 9000
if [ -d /etc/php ]; then
    find /etc/php/ -name "www.conf" -exec sed -i 's|^listen = .*|listen = 127.0.0.1:9000|g' {} +
fi

echo "==> Force running pending database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod || echo "⚠️ Migration skipped or DB connection pending."

echo "==> Starting PHP-FPM daemon..."
php-fpm -D

echo "==> Starting Nginx Web Server..."
exec nginx -g "daemon off;"