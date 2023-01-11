#!/bin/bash

prepareEnvironmentVariables() {
    APP_NAME=$(grep "APP_NAME=" /var/www/html/.env | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
    APP_ENV=$(grep "APP_ENV=" /var/www/html/.env | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
    SSL_RENEW_MAIL=$(grep "SSL_RENEW_MAIL=" /var/www/html/.env | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
    APP_URL=$(grep "APP_URL=" /var/www/html/.env | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
    echo "$APP_URL" | grep -q '^https://' && IS_SECURE=true || IS_SECURE=false
    APP_URL=$(echo "$APP_URL" | sed -e 's|^https\?://||' -e 's|/*$||')
}

showEnvironmentVariables() {
    echo $APP_NAME
    echo $APP_ENV
    echo $APP_URL
    echo $IS_SECURE
}

createOpensslCert() {
    if [ ! -f /etc/nginx/ssl/$APP_URL.crt ]; then
        openssl req -x509 -nodes -days 365 -subj "/CN=$APP_NAME CA/OU=$APP_NAME IT/O=$APP_NAME/L=$APP_NAME/C=ID" -addext "subjectAltName=DNS.1:localhost,DNS.2:$APP_URL" -newkey rsa:2048 -keyout /etc/nginx/ssl/$APP_URL.key -out /etc/nginx/ssl/$APP_URL.crt
        chmod 644 /etc/nginx/ssl/*
    fi
    # create a server name based on .env file
    (cd /etc/nginx/sites-available && cp sites.conf-example sites.conf && sed -i "s/\${SERVER_NAME}/$APP_URL/" sites.conf)
}

createCertbotSsl() {
    if [ ! -f /etc/nginx/ssl/$APP_URL.crt ]; then
        certbot --nginx -d $APP_URL -d www.$APP_URL -n --agree-tos --email $SSL_RENEW_MAIL
    fi
    # create a server name based on .env file
    (cd /etc/nginx/sites-available && cp sites.conf-example sites.conf && sed -i "s/\${SERVER_NAME}/$APP_URL www.$APP_URL/" sites.conf)
}

configureSiteSettings() {
    sed -i "/listen 80;/d" /etc/nginx/sites-available/sites.conf
    sed -i "/listen \[::\]:80 ipv6only=on;/d" /etc/nginx/sites-available/sites.conf
    if [ "$IS_SECURE" ]; then
        echo "server {
            listen 80 default_server;
            listen [::]:80 default_server;
            server_name _ $APP_URL;
            return 301 https://\$host\$request_uri;
        }" >/etc/nginx/conf.d/redirect.conf

    else
        sed -i "s/server {/server {\n\tlisten 80;\n\tlisten [::]:80 ipv6only=on;/" /etc/nginx/sites-available/sites.conf
        echo "" >/etc/nginx/conf.d/redirect.conf
    fi
}

setCronJob() {
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

logCronJob() {
    * * * * * root nginx -s reload >>/var/log/cron.log
}

startNginx() {
    # Start nginx in foreground
    echo "NGINX started, daemon will restart every 00:00:00 UTC +7 now."
    nginx
}

# MAIN SCRIPT

prepareEnvironmentVariables
# showEnvironmentVariables
if [ "$APP_ENV" == "local" ]; then
    createOpensslCert
else
    createCertbotSsl
fi
configureSiteSettings
setCronJob
# logCronJob
startNginx
