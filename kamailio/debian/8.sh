#!/usr/bin/env bash

set -x

function install {
    grep -ioP '.*deb.kamailio.org/kamailio[0-9]* jessie.*' /etc/apt/sources.list > /dev/null
    # If repo is not installed
    if [ $? -eq 1 ]; then
        echo -e "\n# kamailio repo's" >> /etc/apt/sources.list
        echo "deb http://deb.kamailio.org/kamailio${KAM_VERSION} wheezy main" >> /etc/apt/sources.list
        echo "deb-src http://deb.kamailio.org/kamailio${KAM_VERSION} wheezy main" >> /etc/apt/sources.list
    fi

    # Add Key for Kamailio Repo
    wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | apt-key add -

    # Update the repo
    apt-get update

    # Install Kamailio packages
    apt-get install -y --allow-unauthenticated kamailio kamailio-mysql-modules mysql-server

    # Enable MySQL and Kamailio for system startup
    systemctl enable mysql

    # Make sure mysql starts before Kamailio
    sed -i s/After=.*/After=mysqld.service/g /lib/systemd/system/kamailio.service
    systemctl daemon-reload
    systemctl enable kamailio

    # Make sure no extra configs present on fresh install
    rm -f ~/.my.cnf

    # Start MySQL
    systemctl start mysql

    # Configure Kamailio and Required Database Modules
    sed -i -e 's/# DBENGINE=MYSQL/DBENGINE=MYSQL/' /etc/kamailio/kamctlrc

    mkdir /etc/kamailio
    echo "DBENGINE=MYSQL" >> /etc/kamailio/kamctlrc
    echo "INSTALL_EXTRA_TABLES=yes" >> /etc/kamailio/kamctlrc
    echo "INSTALL_PRESENCE_TABLES=yes" >> /etc/kamailio/kamctlrc
    echo "INSTALL_DBUID_TABLES=yes" >> /etc/kamailio/kamctlrc
        echo "DBROOTUSER=\"${MYSQL_ROOT_USERNAME}\"" >> /etc/kamailio/kamctlrc
    if [[ -z "${MYSQL_ROOT_PASSWORD-unset}" ]]; then
        echo "DBROOTPWSKIP=yes" >> /etc/kamailio/kamctlrc
    else
        echo "DBROOTPW=\"${MYSQL_ROOT_PASSWORD}\"" >> /etc/kamailio/kamctlrc
    fi

    #Will hardcode lation1 as the database character set used to create the Kamailio schema due to
    #a potential bug in how Kamailio additional tables are created
    echo "CHARSET=latin1" >> /etc/kamailio/kamctlrc

    # Execute 'kamdbctl create' to create the Kamailio database schema
    kamdbctl create

    # Firewall settings
    firewall-cmd --zone=public --add-port=5060/udp --permanent

    if [ -n "$DSIP_PORT" ]; then
        firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
    fi

    firewall-cmd --reload

    #Start Kamailio
    #systemctl start kamailio
    #return #?
    return 0
}

function uninstall {
    # Stop servers
    systemctl stop kamailio
    systemctl stop mysql

    # Backup kamailio configuration directory
    mv -f /etc/kamailio /etc/kamailio.bak.$(date +%Y%m%d_%H%M%S)

    # Backup mysql / mariadb
    mv -f /var/lib/mysql /var/lib/mysql.bak.$(date +%Y%m%d_%H%M%S)

    # Uninstall Kamailio modules and Mariadb
    apt-get -y remove --purge mysql\*
    apt-get -y remove --purge mariadb\*
    apt-get -y remove --purge kamailio\*
    rm -rf /etc/my.cnf*; rm -f /etc/my.cnf*; rm -f ~/*my.cnf

    # Remove firewall rules that was created by us:
    firewall-cmd --zone=public --remove-port=5060/udp --permanent

    if [ -n "$DSIP_PORT" ]; then
        firewall-cmd --zone=public --remove-port=${DSIP_PORT}/tcp --permanent
    fi

    firewall-cmd --reload
}

case "$1" in
    uninstall|remove)
        #Remove Kamailio
        DSIP_PORT=$3
        KAM_VERSION=$2
        $1
        ;;
    install)
        #Install Kamailio
        DSIP_PORT=$3
        KAM_VERSION=$2
        $1
        ;;
    *)
        echo "usage $0 [install <kamailio version> <dsip_port> | uninstall <kamailio version> <dsip_port>]"
        ;;
esac
