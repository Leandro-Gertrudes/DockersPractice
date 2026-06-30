#!/bin/bash
set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld


DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)


if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "First boot: initializing MariaDB..."

    chown -R mysql:mysql /var/lib/mysql

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null

    cat > /tmp/init.sql <<EOF
-- Set the root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

-- Application database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Application user, reachable from other containers ('%' = any host)
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Remove insecure defaults
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;

FLUSH PRIVILEGES;
EOF


    mariadbd --user=mysql --bootstrap < /tmp/init.sql
    rm -f /tmp/init.sql

    echo "Initialization complete."
else
    echo "Existing database found, skipping init."
fi

exec mariadbd --user=mysql
