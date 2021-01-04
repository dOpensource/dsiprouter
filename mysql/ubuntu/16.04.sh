#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install {
    # Install Dependencies
    # ...

    # install mysql packages
    apt-get install -y --allow-unauthenticated default-mysql-server ||
        apt-get install -y --allow-unauthenticated mariadb-server

    # alias mariadb.service to mysql.service and mysqld.service as in debian repo
    # allowing us to use same service name (mysql, mysqld, or mariadb) across platforms
    (cat << 'EOF'
# Add mysql Aliases by including distro script as recommended in /lib/systemd/system/mariadb.service
.include /lib/systemd/system/mariadb.service

[Install]
Alias=
Alias=mysqld.service
Alias=mariadb.service
EOF
    ) > /lib/systemd/system/mysql.service
    chmod 0644 /lib/systemd/system/mysql.service
    (cat << 'EOF'
# Add mysql Aliases by including distro script as recommended in /lib/systemd/system/mariadb.service
.include /lib/systemd/system/mariadb.service

[Install]
Alias=
Alias=mysql.service
Alias=mariadb.service
EOF
    ) > /lib/systemd/system/mysqld.service
    chmod 0644 /lib/systemd/system/mysqld.service
    systemctl daemon-reload

    # if db is remote don't run local service
    reconfigureMysqlSystemdService

    # Enable mysql on boot
    systemctl enable mysql

    # Make sure no extra configs present on fresh install
    rm -f ~/.my.cnf

    # TODO: selinux/apparmor permissions for mysql
    #       firewall rules (cluster install needs remote access)
    #       configure galera replication (cluster install)
    #       configure group replication (cluster install)

    # TODO: configure mysql to redirect error_log to syslog (as our other services do)
    #       https://mariadb.com/kb/en/systemd/#configuring-mariadb-to-write-the-error-log-to-syslog

    # TODO: configure logrotate to rotate syslog logs from mysql

    return 0
}

function uninstall {
    # Stop and disable services
    systemctl stop mysql
    systemctl disable mysql

    # Backup mysql / mariadb
    mv -f /var/lib/mysql /var/lib/mysql.bak.$(date +%Y%m%d_%H%M%S)

    # remove mysql unit files we created
    rm -f /lib/systemd/system/mysql.service /lib/systemd/system/mysqld.service

    # Uninstall mysql / mariadb packages
    apt-get -y remove --purge mysql\*
    apt-get -y remove --purge mariadb\*
    rm -rf /etc/my.cnf*; rm -f /etc/my.cnf*; rm -f ~/*my.cnf

    # TODO: remove selinux/apparmor rules

    # TODO: remove mysql firewall rules

    # TODO: remove mysql syslog config

    # TODO: remove mysql logrotate config

    return 0
}

case "$1" in
    uninstall|remove)
        uninstall
        ;;
    install)
        install
        ;;
    *)
        printerr "usage $0 [install | uninstall]"
        ;;
esac
