docker run --rm -u "$(id -u):$(id -g)" -v $(pwd):/var/www/html -w /var/www/html laravelsail/php81-composer:latest composer install --ignore-platform-reqs 

if [ ! -f ./docker/php/config/opcache.ini ]; then
    cp ./docker/php/config/opcache.ini-example ./docker/php/config/opcache.ini
fi

if [ ! -f ./docker/php/config/xdebug.ini ]; then
    cp ./docker/php/config/xdebug.ini-example ./docker/php/config/xdebug.ini
fi

if [ ! -f ./.env ]; then
    cp ./.env.example ./.env
    app_url=$(grep "^[^#;]" ./.env | grep 'APP_URL=' | sed 's/^.*=//' | sed 's/\/\//\\\/\\\//')
    sed -i "s/APP_URL=$app_url/APP_URL=https\/\/localhost/" ./.env
fi
