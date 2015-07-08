#!/usr/bin/env sh

SCRIPT="$0"
PWD="${SCRIPT%/*}"

rm -rf "$CONTAINER_DB_DIR/*"
mysql_install_db >/dev/null

chown -R mysql:mysql "$CONTAINER_DB_DIR"
mysqld_safe --datadir="$CONTAINER_DB_DIR" &

i=0
while [ "$i" -lt 10 ]; do
    if [ -e /run/mysqld/mysqld.sock ]; then
        mysql -uroot < "$PWD/init.sql"
        [ $? -eq 0 ] && pkill mysql && exit 0
    fi

    sleep 1
    let i++
done

exit 1
