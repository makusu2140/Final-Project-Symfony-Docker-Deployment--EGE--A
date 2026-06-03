#!/bin/bash
set -e

echo "==> Clearing and warming up production caches..."
php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod

echo "==> Waiting for cloud database to become accessible..."
# This attempts an actual low-level PDO connection using your injected DATABASE_URL.
# If it fails, it catches the exception, waits 3 seconds, and tries again.
until php -r "
try {
    \$dsn = getenv('DATABASE_URL');
    if (!\$dsn) { exit(1); }
    
    // Convert a standard mysql:// URL structure to a valid PHP PDO connection string
    \$dbparts = parse_url(\$dsn);
    if (!isset(\$dbparts['host'])) {
        // Fallback if parse_url struggles: try direct PDO attempt via string manipulation
        \$dsn = str_replace('mysql://', 'mysql:dns=', \$dsn);
    }
    
    // Instantiating a connection will throw an exception if the server isn't ready
    \$pdo = new PDO(getenv('DATABASE_URL'));
    exit(0);
} catch (Exception \$e) {
    // If the error is just 'Database doesn't exist' or 'Access denied', the server IS up!
    if (strpos(\$e->getMessage(), '1049') !== false || strpos(\$e->getMessage(), '1045') !== false) {
        exit(0);
    }
    exit(1);
}
" 2>/dev/null; do
    echo "    --> Database port or server is still initializing. Retrying in 3 seconds..."
    sleep 3
done

echo "==> Database online! Running pending migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --env=prod || true

echo "==> Starting PHP-FPM daemon..."
php-fpm -D

echo "==> Starting Nginx Web Server..."
exec nginx -g "daemon off;"