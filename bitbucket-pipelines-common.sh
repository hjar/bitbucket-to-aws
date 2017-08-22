apt-get update && \
apt-get install -y libicu-dev libxml2-dev python-dev unzip && \
docker-php-ext-install -j$(nproc) intl && \
docker-php-ext-install -j$(nproc) mbstring && \
docker-php-ext-install -j$(nproc) pdo && \
docker-php-ext-install -j$(nproc) xml && \
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
composer install && \
cp .env.example .env && \
php artisan key:generate
