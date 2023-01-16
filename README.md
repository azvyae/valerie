
# Valerie Framework 2.0.2

Valerie is a bundle framework that is compatible with pure Laravel environments such as Forge, Sanctum, Vite, and others. It is essentially a Docker Compose file that has Sail features and is composed of several services:

-   PHP-FPM
-   Nginx with SSL (OpenSSL for local and testing environments, and Certbot LetsEncrypt SSL for staging and production environments)
-   Redis
-   Selenium for testing.

## Getting Started

To use Valerie, simply clone the repository from [erstevn/valerie](https://github.com/erstevn/valerie.git) and run the following commands:

You can use the script by run directly `./valerie.sh` or if you have aliased the command so you can use directly by typing `valerie`

### First Run (Interactive)
```SHELL
git clone https://github.com/erstevn/valerie.git
cd valerie
./valerie.sh
```
Then follow the prompts on the console.
### Command Line Usage
Usage: `valerie [OPTIONS]`
```SHELL
Valerie runtime interactive shell

Options:
-h, --help            Print this Help.
-v, --version         Print software version and exit.
    --noninteractive  Run script without interactive prompts

Options required if you using --noninteractive
    --rcfile          Provide default rcfile (fullpath required)
    --xdebug-ide-key  Xdebug IDE key
    --xdebug-mode     Xdebug Mode (off, debug, develop, coverage)
    --environment     Environment for installing this app
    --env-key (opt)   Env crypted key for decrypting file, you may use (disable) as value for not decrypting any
```

### One Run Installation (Non Interactive)

You may want to run installation without interacting with the shell, e.g creating automation for preparing installation for testing, staging, or production environment. You can use the script like this:

> By default, Laravel will use the AES-256-CBC cipher which requires a 32 character key.

```SHELL
valerie --noninteractive --rcfile "$HOME/.bashrc" --xdebug-ide-key "vsc" --xdebug-mode "off" --environment "local" --env-key "disable"
```
You can also provide env-key to decrypt certain .env file*. You may want to use this command:
```SHELL
valerie --noninteractive --rcfile "$HOME/.bashrc" --xdebug-ide-key "vsc" --xdebug-mode "off" --environment "production" --env-key "randomKey"
```

*currently can only support .env file other than .env.example, if you want to decrypt this file you should use the default decryption method `sail artisan env:decrypt --key=randomKey`

## Features

-   Nginx with SSL support for local and production environments
-   Redis
-   Selenium for testing
-   Support Laravel 9 and PHP 8.2
-   Postgresql 15
-   Nodejs 18
-   All wrapped in Docker

## Packages

### Composer packages

|Package|Version|
|---|---|
|php|^8.0.2|
|guzzlehttp/guzzle|^7.2|
|http-interop/http-factory-guzzle|^1.2|
|laravel/framework|^9.19|
|laravel/sanctum|^3.0|
|laravel/scout|^9.7|
|laravel/tinker|^2.7|
|meilisearch/meilisearch-php|^0.27.0|
|spatie/db-dumper|^3.3|

### NPM packages

|Package|Version|
|---|---|
|axios|^1.1.2|
|laravel-vite-plugin|^0.7.2|
|lodash|^4.17.19|
|postcss|^8.1.14|
|vite|^4.0.0|

## Compatibility

Valerie is built using Laravel and Sail, so it is compatible with any pure Laravel environment. Currently using Laravel 9, PHP 8.2, Nodejs 18, and Postgresql 15. Docker is required to run this framework.

## Changelog

-   Version 1.0.0 : Initial release
-   Version 1.0.1 : Bug fix when installing Valerie
-   Version 1.1.0 : Adding Meilisearch to Dockerfile
-   Version 2.0.0 : Meilisearch included, environment separation for local, production, testing, and staging, and other major changes.
-   Version 2.0.1 : Bug fix for non interactive option doesn't working.
-   Version 2.0.2 : Bug fix for failed running nginx container. Added new testing env.

## License
The MIT License (MIT)

Copyright © 2023 Azvya Erstevan I <erstevn@gmail.com>