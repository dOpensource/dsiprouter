#!/usr/bin/env bash

set -x

function install {
    # Install Dependencies
    apt-get install -y curl wget sed gawk vim perl
    apt-get install -y logrotate rsyslog

    # create kamailio user and group
    mkdir -p /var/run/kamailio
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "Kamailio SIP Proxy" kamailio
    chown -R kamailio:kamailio /var/run/kamailio

    grep -ioP '.*deb.kamailio.org/kamailio[0-9]* wheezy.*' /etc/apt/sources.list > /dev/null
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

    # create kamailio defaults config
    (cat << 'EOF'
 RUN_KAMAILIO=yes
 USER=kamailio
 GROUP=kamailio
 SHM_MEMORY=64
 PKG_MEMORY=8
 PIDFILE=/var/run/kamailio/kamailio.pid
 CFGFILE=/etc/kamailio/kamailio.cfg
 #DUMP_CORE=yes
EOF
    ) > /etc/default/kamailio
    # create kamailio tmp files
    echo "d /run/kamailio 0750 kamailio kamailio" > /etc/tmpfiles.d/kamailio.conf

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

    # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl start firewalld

    # Firewall settings
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp
    firewall-cmd --reload

    # Setup kamailio Logging
    cp -f ${DSIP_PROJECT_DIR}/resources/syslog/kamailio.conf /etc/rsyslog.d/kamailio.conf
    touch /var/log/kamailio.log
    systemctl restart rsyslog

    # Setup logrotate
    cp -f ${DSIP_PROJECT_DIR}/resources/logrotate/kamailio /etc/logrotate.d/kamailio

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
        uninstall
        ;;
    install)
        install
        ;;
    *)
        echo "usage $0 [install | uninstall]"
        ;;
esac
