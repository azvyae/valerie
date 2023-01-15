#!/bin/bash
#
# Valerie performs interactive or non interactive
# command-line configuration for sail application.

#######################################
# Display version
#######################################
display_version() {
    # Display Help
    echo "Valerie 1.0.1"
    echo "MIT LICENSE Copyright © 2023 Azvya Erstevan I <erstevn@gmail.com>"
    echo
}

#######################################
# Display help
#######################################
display_help() {
    # Display Help
    echo "Usage: valerie [OPTIONS]"
    echo
    echo "Valerie runtime interactive shell"
    echo
    echo "Options:"
    echo "-h, --help            Print this Help."
    echo "-v, --version         Print software version and exit."
    echo "    --noninteractive  Run script without interactive prompts"
    echo
    echo "Options required if you using --noninteractive"
    echo "    --rcfile          Provide default rcfile (fullpath required)"
    echo "    --xdebug-ide-key  Xdebug IDE key"
    echo "    --xdebug-mode     Xdebug Mode (off, debug, develop, coverage)"
    echo "    --environment     Environment for installing this app"
    echo "    --env-key (opt)   Env crypted key for decrypting file"
    echo
}

#######################################
# Display and outputs error message to stderr.
# Arguments:
#   String to be outputted
#######################################
err() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

#######################################
# Run non interactive shell for installation.
# Arguments:
#   Check help to see options
#######################################
install_non_interactive() {
    local rcfile
    local xdebug_ide_key
    local xdebug_mode
    local environment
    local env_key

    show_valerie_logo

    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        --rcfile)
            rcfile="$2"
            shift
            ;;
        --xdebug-ide-key)
            xdebug_ide_key="$2"
            shift
            ;;
        --xdebug-mode)
            xdebug_mode="$2"
            shift
            ;;
        --environment)
            environment="$2"
            shift
            ;;
        --env-key)
            env_key="$2"
            shift
            ;;
        *)
            echo "Invalid option: $key"
            display_help
            exit 1
            ;;
        esac
        shift
    done

    # Check if all required options are passed
    if [[ -z "$rcfile" || -z "$xdebug_ide_key" || -z "$xdebug_mode" || -z "$environment" ]]; then
        echo "You have to provide --rcfile, --xdebug-ide-key, --xdebug-mode, --environment when using --noninteractive"
        exit 1
    fi

    echo "Preparing noninteractive installation of the app"
    sleep 1
    echo "Rcfile used is [$rcfile]"
    sleep 1
    echo "Xdebug IDE key used is [$xdebug_ide_key]"
    sleep 1
    echo "Xdebug mode is [$xdebug_mode]"
    sleep 1
    echo "With environment [$environment]"
    sleep 1
    echo "With env key = [********************************]"
    echo

    install_main_app $rcfile $xdebug_ide_key $xdebug_mode $environment $env_key
}

#######################################
# Show Valerie logo.
# Arguments:
#   Determine should clear terminal before showing logo
#######################################
show_valerie_logo() {
    local clear=$1
    if [ $clear = "--clear" ]; then
        clear
    fi
    echo " __      __   _           _      "
    echo " \ \    / /  | |         (_)     "
    echo "  \ \  / __ _| | ___ _ __ _  ___ "
    echo "   \ \/ / _\` | |/ _ | '__| |/ _ \\"
    echo "    \  | (_| | |  __| |  | |  __/"
    echo "     \/ \__,_|_|\___|_|  |_|\___|"
    echo "---------------------------------"
}

#######################################
# Show interactive shell main menu.
#######################################
show_main_menu() {
    echo "Menu:"
    echo "1. Install Main Application"
    echo "2. Configure Xdebug"
    echo "3. Change Docker Settings"
    echo "4. Configure Sail Aliases"
    echo "5. Check Sail Aliases"
    echo "0. Exit"
}

#######################################
# Choose main menu options.
# Arguments:
#   Numbers, to execute based on input
#######################################
choose_main_menu() {
    case $1 in
    1)
        install_main_app
        ;;
    2)
        configure_xdebug
        ;;
    3)
        change_docker_settings
        ;;
    4)
        configure_sail_aliases
        ;;
    5)
        check_sail_aliases
        ;;
    0)
        show_valerie_logo --clear
        echo "Valerie out, bye."
        exit
        ;;
    *)
        echo "Option is invalid"
        ;;
    esac
}

#######################################
# Launch interactive Valerie shell.
# Arguments:
#   String to be outputted
#######################################
start_interactive_shell() {
    local choice
    while true; do
        show_valerie_logo --clear
        show_main_menu
        read -p "Choose menu: " choice
        choose_main_menu $choice
        unset choice
    done
}

#######################################
# Prepares sail env configuration.
# Arguments:
#    like .bashrc with full path
#   Env key to decrypt file
#######################################
prepare_sail_env() {
    local environment=$1
    local env_key=$2
    local app_key_val=$(grep -o "^APP_KEY=.*" .env | awk -F 'APP_KEY=' '{print $2}')

    if [ -z "$environment" ]; then
        show_valerie_logo --clear
        read -p "Environment (optional): " environment
    fi
    if [ -z "$env_key" ]; then
        show_valerie_logo --clear
        read -p "Env key: " env_key
    fi

    # Run sail
    vendor/bin/sail down && vendor/bin/sail up -d >/dev/null 2>&1

    # Link storage
    if [ ! -f ./public/storage ]; then
        vendor/bin/sail artisan storage:link

    fi

    # Generate app key
    if [ -z $app_key_val ]; then
        vendor/bin/sail artisan key:generate
    fi

    # Decrypt env file if env_key is provided
    if [ ! -z "$env_key" ]; then
        if [ -z "$environment" ]; then
            vendor/bin/sail artisan env:decrypt --key=$env_key
        else
            vendor/bin/sail artisan env:decrypt --key=$env_key --env=$environment
        fi
    fi

    # Install required Node Modules
    vendor/bin/sail npm install

    # Stop sail
    vendor/bin/sail down >/dev/null 2>&1
}

#######################################
# Install main application.
# Arguments:
#   Rcfile like .bashrc with full path
#   Xdebug IDE key
#   Xdebug Mode (off, debug, coverage, develop)
#   Environment for the app
#######################################
install_main_app() {
    local rcfile=$1
    local xdebug_ide_key=$2
    local xdebug_mode=$3
    local environment=$4
    local env_key=$5

    configure_sail_aliases $rcfile

    if [ ! -d ./vendor ]; then
        echo "Installing required composer files"
        docker run --rm \
            -u "$(id -u):$(id -g)" \
            -v "$(pwd):/var/www/html" \
            -w /var/www/html \
            laravelsail/php81-composer:latest \
            composer install --ignore-platform-reqs
    else
        echo "Continue installing without composer"
        sleep 2
    fi

    echo "Updating opcache configuration"
    cp ./docker/php/config/opcache.ini-example ./docker/php/config/opcache.ini
    sleep 2

    configure_xdebug $xdebug_ide_key $xdebug_mode
    change_docker_settings $environment

    prepare_sail_env $environment $env_key

    echo "Successfully installed the application"
    sleep 2
}

#######################################
# Sets Xdebug configuration.
# Arguments:
#   Xdebug IDE key
#   Xdebug Mode (off, debug, coverage, develop)
#######################################
configure_xdebug() {
    cp ./docker/php/config/xdebug.ini-example ./docker/php/config/xdebug.ini

    local idekey=$1
    local mode=$2
    local host=$(hostname -I | xargs)

    if [ -z "$idekey" ]; then
        show_valerie_logo --clear
        read -p "Xdebug Ide Key [vsc]: " idekey
        if [ -z "$idekey" ]; then
            idekey="vsc"
        fi
    fi

    if [ -z "$mode" ]; then
        show_valerie_logo --clear
        read -p "Xdebug mode [off]: " mode
        if [ -z "$mode" ]; then
            mode="off"
        fi
    fi

    sed -i "s/xdebug.idekey=.*/xdebug.idekey=$idekey/g" ./docker/php/config/xdebug.ini
    sed -i "s/xdebug.mode=.*/xdebug.mode=$mode/g" ./docker/php/config/xdebug.ini
    sed -i "s/xdebug.client_host=.*/xdebug.client_host=$host/g" ./docker/php/config/xdebug.ini
    echo "You have to restart sail in order Xdebug to be updated"
    sleep 2
}

#######################################
# Generate .env and docker compose override files
# Arguments:
#   Environment for the app
#######################################
change_docker_settings() {
    local environment=$1

    if [ -z "$environment" ]; then
        show_valerie_logo --clear
        read -p "Change environment [local]: " environment
        if [ -z "$environment" ]; then
            environment="local"
        fi
    fi

    if [ ! -f ./docker-compose.$environment.yml ]; then
        err "./docker-compose.$environment.yml is not found"
        exit 0
    fi

    if [ -f ./.env.$environment ]; then
        cp ./.env.$environment ./.env
    else
        echo "Using default .env.example file"
        cp ./.env.example ./.env
    fi

    ln -sf ./docker-compose.$environment.yml ./docker-compose.override.yml

    echo "Successfully change docker environment to docker-compose.$environment.yml and .env.$environment"
}

#######################################
# Sets Sail aliases
# Arguments:
#   Rcfile like .bashrc with full path
#######################################
configure_sail_aliases() {
    local rcfile=$1

    if [ -z "$rcfile" ]; then
        show_valerie_logo --clear
        read -p "Enter the location of your rcfile [$HOME/.bashrc]: " rcfile
    fi

    rcfile=${rcfile:-"$HOME/.bashrc"}

    if [ -f $rcfile ]; then
        sed -i '/alias sail/d' $rcfile
        sed -i '/alias sail-restart/d' $rcfile
        sed -i '/alias valerie/d' $rcfile

        echo "alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'" >>$rcfile
        echo "alias sail-restart='sail down && sail up -d && sail npm start'" >>$rcfile
        echo "alias valerie='./valerie.sh'" >>$rcfile

        echo "Aliases have been set up in $rcfile, you should run : source $rcfile"
    else
        err "$rcfile is not found"
        exit 0
    fi
    sleep 2
}

#######################################
# Interactive shell for displaying aliases in the rcfile
# Arguments:
#   Rcfile like .bashrc with full path
#######################################
check_sail_aliases() {
    local rcfile=$1

    show_valerie_logo --clear

    # Load thercfile
    if [ -z "$rcfile" ]; then
        read -p "Enter the location of your rcfile [$HOME/.bashrc]: " rcfile
    fi

    rcfile=${rcfile:-"$HOME/.bashrc"}

    show_valerie_logo --clear

    # Print rcfile
    grep --color=always -e "sail" -e "artisan" -e "valerie" $rcfile | sed -e "s/\(sail\|artisan\|valerie\)/$(echo -e "\033[31m\1\033[0m")/g"
    read -p "Type anything to continue: "
}

#######################################
# Main Application
#######################################
#######################################
# Handle inputs.
# Arguments:
#   Options
#######################################

# Parse options
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -h | --help)
        display_help
        exit 0
        ;;
    -v | --version)
        display_version
        exit 0
        ;;
    --noninteractive)
        shift
        install_non_interactive "$@"
        exit 0
        ;;
    *)
        echo "Invalid option: $key"
        display_help
        exit 1
        ;;
    esac
    shift
done

start_interactive_shell
