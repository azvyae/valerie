
# Valerie Framework 1.0.0

Valerie is a bundle framework that is compatible with pure Laravel environments such as Forge, Sanctum, Vite, and others. It is essentially a Docker Compose file that has Sail features and is composed of several services:

-   PHP-fpm
-   Nginx with SSL (OpenSSL for local and testing environments, and Certbot LetsEncrypt SSL for staging and production environments)
-   Redis
-   Selenium for testing.

## Getting started

To use Valerie, simply clone the repository from [https://github.com/erstevn/valerie.git](https://github.com/erstevn/valerie.git) and run the following commands:

-   Initial installation to prepare Laravel, Sail, and Composer dependencies

Copy code

`./install.sh` 

-   Start the Sail service

Copy code

`./vendor/bin/sail up` 

-   Install node modules

Copy code

`./vendor/bin/sail npm install` 

-   To start Vite

Copy code

`./vendor/bin/sail npm start` 

## Features

### Composer packages included

-   spatie/db-dumper (for dumping database tables to the `database/dump` folder)
-   kkomelin/laravel-translatable-string-exporter (for preparing translations called by the `__()` helper throughout the application's PHP files)
-   theanik/laravel-more-command (additional command)

## Compatibility

Valerie is built using Laravel and Sail, so it is compatible with any pure Laravel environment.

## Versioning

Valerie Framework currently in version 1.0.0