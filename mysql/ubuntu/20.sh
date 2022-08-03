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
    apt-get install -y mariadb-server mariadb-client libmariadbd-dev

    # Setup mysql config locations in a reliable manner
    rm -f ~/.my.cnf 2>/dev/null
    mkdir -p /var/run/mariadb
    chown -R mysql:mysql /var/run/mariadb /var/lib/mysql /var/log/mysql /usr/share/mysql
    #( cd /lib/systemd/system/; ln -s mariadb.service mysqld.service; ln -s mariadb.service mysql.service; )

    # setup aliases and if db is remote replace with dummy service file
    reconfigureMysqlSystemdService

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

    # remove mysql unit files we created
    rm -rf /etc/systemd/system/mariadb.service.d/
    rm -f /etc/systemd/system/mariadb.service 2>/dev/null
    systemctl daemon-reload

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
