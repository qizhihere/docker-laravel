#!/usr/bin/env bash

# project settings
PROJECT_NAME="compass.local"

# data save directories
LARAVEL_DB_DIR="./storage/mysql"
CONTAINER_DB_DIR="/var/lib/mysql"

# database settings
DB_USER='default'
DB_PASS='default'
DB_HOST='%'
DB_NAME='default'
DB_ROOT_PASS='root'

# internal settings(Don't modify)
SCRIPT_PATH="$0"
SCRIPT_DIR="${SCRIPT_PATH%/*}"

drun-once () {
    docker run --rm -v $(realpath .):/var/www -w /var/www $*
}

check-status () {
    [ -z "$is_success" ] && is_success=1
    [ "$is_success" = "1" ]
}

# check privileges
[ $EUID -ne 0 ] && {
    echo "This script must be run with root privilege."
    exit 1
}

# check if docker is running
if ! pgrep -f "docker" &>/dev/null; then
    systemctl start docker
fi

# check images
if ! docker images | grep -P "littleqz/(php|mariadb|nginx)" &>/dev/null; then
    echo "Please make sure images littleqz/php, littleqz/mariadb and littleqz/nginx exist."
    exit 1
fi

sed -i -e "s=\$DB_USER=${DB_USER}=g" \
       -e "s=\$DB_PASS=${DB_PASS}=g" \
       -e "s=\$DB_HOST=${DB_HOST}=g" \
       -e "s=\$DB_NAME=${DB_NAME}=g" \
       -e "s=\$DB_ROOT_PASS=${DB_ROOT_PASS}=g" \
       -e "s=\$PROJECT_NAME=${PROJECT_NAME}=g" \
       -e "s=\$CONTAINER_DB_DIR=${CONTAINER_DB_DIR}=g" \
       -e "s=\$LARAVEL_DB_DIR=${LARAVEL_DB_DIR}=g" \
       ./database/* ./configs/*

drun-once littleqz/php /root/.composer/vendor/bin/laravel new "$PROJECT_NAME" &&
cp -rf ./configs/* "$PROJECT_NAME/" &&
drun-once -v "$(realpath ./$PROJECT_NAME/${LARAVEL_DB_DIR#./})":"$CONTAINER_DB_DIR" littleqz/mariadb \
          sh /var/www/database/init.sh &&
echo "Project initialize finished!" &&
rm -rf ./{databases,configs,init.sh} &>/dev/null && exit 0

echo "Failed!"
exit 1
