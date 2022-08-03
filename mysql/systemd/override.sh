#!/usr/bin/env bash

DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-/opt/dsiprouter}

# alias mariadb.service to mysql.service and mysqld.service using systemd drop-in replacements
# allowing us to use same service name (mysql.service) across platforms
mkdir -p /etc/systemd/system/mariadb.service.d
cp -f ${DSIP_PROJECT_DIR}/mysql/systemd/override.conf /etc/systemd/system/mariadb.service.d/override.conf
chmod 644 /etc/systemd/system/mariadb.service.d/override.conf
