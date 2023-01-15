#!/bin/bash

prepare_environment_variables() {
    APP_NAME=$(grep "APP_NAME=" /var/www/html/.env | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
    APP_ENV=$(grep "APP_ENV=" /var/www/html/.env | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
    SSL_RENEW_MAIL=$(grep "SSL_RENEW_MAIL=" /var/www/html/.env | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
    APP_URL=$(grep "APP_URL=" /var/www/html/.env | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
    echo "$APP_URL" | grep -q '^https://' && IS_SECURE=true || IS_SECURE=false
    APP_URL=$(echo "$APP_URL" | sed -e 's|^https\?://||' -e 's|/*$||')
}

show_environment_variables() {
    echo $APP_NAME
    echo $APP_ENV
    echo $APP_URL
    echo $SSL_RENEW_MAIL
    echo $IS_SECURE
}

create_openssl_cert() {
    if [ ! -f /etc/nginx/ssl/$APP_URL.crt ]; then
        openssl req -x509 -nodes -days 365 -subj "/CN=$APP_NAME CA/OU=$APP_NAME IT/O=$APP_NAME/L=$APP_NAME/C=ID" -addext "subjectAltName=DNS.1:localhost,DNS.2:$APP_URL,DNS.3:meilisearch.$APP_URL" -newkey rsa:2048 -keyout /etc/nginx/ssl/$APP_URL.key -out /etc/nginx/ssl/$APP_URL.crt
        chmod 644 /etc/nginx/ssl/*
    fi
    # create a server name based on .env file
    (cd /etc/nginx/sites-available && cp main.conf-example main.conf && sed -i "s/\${SERVER_NAME}/$APP_URL/" main.conf)
    (cd /etc/nginx/sites-available && cp meilisearch.conf-example meilisearch.conf && sed -i "s/\${SERVER_NAME}/$APP_URL/" meilisearch.conf)
}

create_certbot_cert() {
    if [ ! -f /etc/nginx/ssl/$APP_URL.crt ]; then
        certbot --nginx -d $APP_URL -d www.$APP_URL -d meilisearch.$APP_URL -n --agree-tos --email $SSL_RENEW_MAIL
    fi
    # create a server name based on .env file
    (cd /etc/nginx/sites-available && cp main.conf-example main.conf && sed -i "s/\${SERVER_NAME}/$APP_URL www.$APP_URL/" main.conf)
    (cd /etc/nginx/sites-available && cp meilisearch.conf-example meilisearch.conf && sed -i "s/\${SERVER_NAME}/$APP_URL/" meilisearch.conf)
}

configure_site_settings() {
    sed -i "/listen 80;/d" /etc/nginx/sites-available/main.conf
    sed -i "/listen \[::\]:80;/d" /etc/nginx/sites-available/main.conf
    sed -i "/listen 80;/d" /etc/nginx/sites-available/meilisearch.conf
    sed -i "/listen \[::\]:80;/d" /etc/nginx/sites-available/meilisearch.conf
    if [ "$IS_SECURE" = true ]; then
        echo "server {
            listen 80 default_server;
            listen [::]:80 default_server;
            server_name _ $APP_URL;
            return 301 https://\$host\$request_uri;
        }" >/etc/nginx/conf.d/redirect.conf

    else
        sed -i "s/server {/server {\n\tlisten 80;\n\tlisten [::]:80;/" /etc/nginx/sites-available/main.conf
        sed -i "s/server {/server {\n\tlisten 80;\n\tlisten [::]:80;/" /etc/nginx/sites-available/meilisearch.conf
        echo "" >/etc/nginx/conf.d/redirect.conf
    fi
}

set_cron_job() {
    # cron job to restart nginx every 00:00:00 UTC +7
    (
        crontab -l
        echo "0 17 */4 * * nginx -s reload"
    ) | crontab -

    if [ "$APP_ENV" != "local" ]; then
        (
            crontab -l
            echo "30 16 */4 * * certbot renew"
        ) | crontab -
    fi
    # Start crond in background
    crond -l 2 -b
}

log_cron_job() {
    * * * * * root nginx -s reload >>/var/log/cron.log
}

start_nginx() {
    # Start nginx in foreground
    echo "NGINX started, daemon will restart every 00:00:00 UTC +7 now."
    nginx
}

# MAIN SCRIPT

prepare_environment_variables
show_environment_variables
if [ "$APP_ENV" == "local" ]; then
    create_openssl_cert
else
    create_certbot_cert
fi
configure_site_settings
set_cron_job
log_cron_job
start_nginx
