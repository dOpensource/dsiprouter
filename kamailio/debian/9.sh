#!/usr/bin/env bash

set -x

function install {
    # Install Dependencies
    apt-get install -y curl wget sed gawk vim perl
    apt-get install -y logrotate rsyslog

    grep -ioP '.*deb.kamailio.org/kamailio[0-9]* stretch.*' /etc/apt/sources.list > /dev/null
    # If repo is not installed
    if [ $? -eq 1 ]; then
        echo -e "\n# kamailio repo's" >> /etc/apt/sources.list
        echo "deb http://deb.kamailio.org/kamailio${KAM_VERSION} stretch main" >> /etc/apt/sources.list
        echo "deb-src http://deb.kamailio.org/kamailio${KAM_VERSION} stretch  main" >> /etc/apt/sources.list
    fi

    # Add Key for Kamailio Repo
    wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | apt-key add -

    # Update the repo
    apt-get update

    # Install Kamailio packages
    apt-get install -y --allow-unauthenticated firewalld kamailio kamailio-mysql-modules mysql-server

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
    mkdir -p ${SYSTEM_KAMAILIO_CONFIG_DIR}
    echo "DBENGINE=MYSQL" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    echo "INSTALL_EXTRA_TABLES=yes" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    echo "INSTALL_PRESENCE_TABLES=yes" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    echo "INSTALL_DBUID_TABLES=yes" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
        echo "DBROOTUSER=\"${MYSQL_ROOT_USERNAME}\"" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    if [[ -z "${MYSQL_ROOT_PASSWORD-unset}" ]]; then
        echo "DBROOTPWSKIP=yes" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    else
        echo "DBROOTPW=\"${MYSQL_ROOT_PASSWORD}\"" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    fi

    # Will hardcode lation1 as the database character set used to create the Kamailio schema due to
    # a potential bug in how Kamailio additional tables are created
    echo "CHARSET=latin1" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc

    # Execute 'kamdbctl create' to create the Kamailio database schema
    kamdbctl create

    # Firewall settings
    firewall-cmd --zone=public --add-port=5060/udp --permanent

    if [ -n "$DSIP_PORT" ]; then
        firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
    fi

    firewall-cmd --reload

    # Setup kamailio Logging
    echo "local0.*     -/var/log/kamailio.log" > /etc/rsyslog.d/kamailio.conf
    touch /var/log/kamailio.log
    systemctl restart rsyslog

    # Setup logrotate
    cp -f ${DSIP_PROJECT_DIR}/logrotate/kamailio /etc/logrotate.d/kamailio

    # Start Kamailio
    #systemctl start kamailio
    #return #?
    return 0
}

function uninstall {
    # Stop servers
    systemctl stop kamailio
    systemctl stop mysql

    # Backup kamailio configuration directory
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR} ${SYSTEM_KAMAILIO_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)

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

    # Remove kamailio Logging
    rm -f /etc/rsyslog.d/kamailio.conf

    # Remove logrotate settings
    rm -f /etc/logrotate.d/kamailio
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
