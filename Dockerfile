FROM php:8.3-fpm-alpine

# Install production system dependencies, Nginx, and MySQL drivers
RUN apk add --no-cache \
    nginx \
    bash \
    acl \
    openssl \
    git \
    unzip

RUN docker-php-ext-install pdo pdo_mysql

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html

# Copy application codebase
COPY . .

# Optimize Composer packages for a lean production footprint
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Create necessary directories and set permissions for Symfony caches
RUN mkdir -p /run/nginx /var/www/html/var && \
    chown -R www-data:www-data /var/www/html/var

# Move Nginx settings into place
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-main.conf /etc/nginx/conf.d/default.conf

# Set up the runtime entrypoint script
RUN chmod +x entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/var/www/html/entrypoint.sh"]