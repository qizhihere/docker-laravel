#!/usr/bin/env bash

# project settings
PROJECT_NAME="default-project.local"

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

sed-escape () {
    local _v=$(printf "%q" "$*")
    echo ${_v//@/\\@}
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

sed -i -e "s@\$DB_USER@$(sed-escape $DB_USER)@g" \
       -e "s@\$DB_PASS@$(sed-escape $DB_PASS)@g" \
       -e "s@\$DB_HOST@$(sed-escape $DB_HOST)@g" \
       -e "s@\$DB_NAME@$(sed-escape $DB_NAME)@g" \
       -e "s@\$DB_ROOT_PASS@$(sed-escape $DB_ROOT_PASS)@g" \
       -e "s@\$PROJECT_NAME@$(sed-escape $PROJECT_NAME)@g" \
       -e "s@\$CONTAINER_DB_DIR@$(sed-escape $CONTAINER_DB_DIR)@g" \
       -e "s@\$LARAVEL_DB_DIR@$(sed-escape $LARAVEL_DB_DIR)@g" \
       ./database/* ./configs/*

drun-once littleqz/php /root/.composer/vendor/bin/laravel new "$PROJECT_NAME" &&

cp -rf ./configs/* "$PROJECT_NAME/" &&

drun-once -v "$(realpath ./$PROJECT_NAME/${LARAVEL_DB_DIR#./})":"$CONTAINER_DB_DIR" littleqz/mariadb \
          sh /var/www/database/init.sh &&

sed -i -e "s@DB_HOST=.*@DB_HOST=mariadb@" \
       -e "s@DB_DATABASE=.*@DB_DATABASE=$(sed-escape ${DB_NAME})@" \
       -e "s@DB_USERNAME=.*@DB_USERNAME=$(sed-escape ${DB_USER})@" \
       -e "s@DB_PASSWORD=.*@DB_PASSWORD=$(sed-escape ${DB_PASS})@" \
       "./$PROJECT_NAME/.env" &&

chown -R 1000:1000 "./$PROJECT_NAME" &&
chown -R 60:60 "./$PROJECT_NAME/${LARAVEL_DB_DIR#./}" &&

echo "Project initialize finished!" &&

cp "$0" "$SCRIPT_DIR/db.ini" &&
sed -i '/^DB_.\+=.*$/!d' "$SCRIPT_DIR/db.ini" &&
rm -rf ./{database,configs,init.sh,README.org} &>/dev/null && exit 0

echo "Failed!"
exit 1
