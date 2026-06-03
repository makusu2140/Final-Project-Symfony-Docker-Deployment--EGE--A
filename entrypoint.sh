#!/bin/bash
set -e

echo "==> Clearing and warming up production caches..."
php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod

echo "==> Waiting for cloud database to become accessible..."
# This loop uses PHP to ping the MySQL database. 
# It will retry every 3 seconds until the connection succeeds.
until php -r "
try {
    \$url = parse_url(getenv('DATABASE_URL'));
    \$host = \$url['host'];
    \$port = isset(\$url['port']) ? \$url['port'] : 3306;
    \$fd = @fsockopen(\$host, \$port, \$errno, \$errstr, 2);
    if (\$fd) { fclose(\$fd); exit(0); }
} catch (Exception \$e) {}
exit(1);
" 2>/dev/null; do
    echo "    --> Database is still initializing. Retrying in 3 seconds..."
    sleep 3
done

echo "==> Database online! Running pending migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod || true

echo "==> Starting PHP-FPM daemon..."
php-fpm -D

echo "==> Starting Nginx Web Server..."
exec nginx -g "daemon off;"