#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install {
    # create mysql user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel mysql &>/dev/null; groupdel mysql &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "Mysql Database Server" mysql

    # install mysql packages
    apt-get install -y mariadb-server

    if (( $? != 0 )); then
        printerr 'Failed installing mariadb packages'
        return 1
    fi

    # if db is remote don't run local service
    reconfigureMysqlSystemdService

    # Make sure no extra configs present on fresh install
    rm -f ~/.my.cnf

    # ensure data directory exists
    mkdir -p /var/lib/mysql
    chown mysql:mysql /var/lib/mysql

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
    systemctl stop mariadb
    systemctl disable mariadb

    # Backup mysql / mariadb
    mv -f /var/lib/mysql /var/lib/mysql.bak.$(date +%Y%m%d_%H%M%S)

    # Uninstall mariadb packages
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
