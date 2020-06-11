#!/usr/bin/env bash

(( $DEBUG == 1 )) && set -x

function install {
    local KAM_SOURCES_LIST="/etc/apt/sources.list.d/kamailio.list"

    # Install Dependencies
    apt-get install -y curl wget sed gawk vim perl
    apt-get install -y logrotate rsyslog

    # create kamailio user and group
    mkdir -p /var/run/kamailio
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "Kamailio SIP Proxy" kamailio
    chown -R kamailio:kamailio /var/run/kamailio

    # add repo sources to apt
    mkdir -p /etc/apt/sources.list.d
    (cat << EOF
# kamailio repo's
deb http://deb.kamailio.org/kamailio${KAM_VERSION} stretch main
deb-src http://deb.kamailio.org/kamailio${KAM_VERSION} stretch main
EOF
    ) > ${KAM_SOURCES_LIST}

    # Add Key for Kamailio Repo
    wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | apt-key add -

    # Update the repo
    apt-get update -y

    # Install Kamailio packages
    apt-get install -y --allow-unauthenticated firewalld certbot kamailio kamailio-mysql-modules mysql-server kamailio-extra-modules kamailio-tls-modules kamailio-websocket-modules

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

    # Make sure MariaDB and Local DNS start before Kamailio
    if grep -q -v 'mysql.service dnsmasq.service' /lib/systemd/system/kamailio.service; then
        sed -i -r -e 's/(After=.*)/\1 mysql.service dnsmasq.service/' /lib/systemd/system/kamailio.service
    fi
    if grep -q -v "${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig" /lib/systemd/system/kamailio.service; then
        sed -i -r -e "0,\|^ExecStart.*|{s||ExecStartPre=-${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig\n&|}" /lib/systemd/system/kamailio.service
    fi
    systemctl daemon-reload

    # Enable MySQL and Kamailio for system startup
    systemctl enable mysql
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
SHM_MEMORY=128
PKG_MEMORY=16
PIDFILE=/var/run/kamailio/kamailio.pid
CFGFILE=/etc/kamailio/kamailio.cfg
#DUMP_CORE=yes
EOF
    ) > /etc/default/kamailio
    # create kamailio tmp files
    echo "d /run/kamailio 0750 kamailio kamailio" > /etc/tmpfiles.d/kamailio.conf

    # Configure Kamailio and Required Database Modules
    mkdir -p ${SYSTEM_KAMAILIO_CONFIG_DIR}
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc.$(date +%Y%m%d_%H%M%S)
    if [[ -z "${MYSQL_ROOT_PASSWORD-unset}" ]]; then
        local ROOTPW_SETTING="DBROOTPWSKIP=yes"
    else
        local ROOTPW_SETTING="DBROOTPW=\"${MYSQL_ROOT_PASSWORD}\""
    fi

    # TODO: we should set STORE_PLAINTEXT_PW to 0, this is not default but would need tested
    (cat << EOF
DBENGINE=MYSQL
DBHOST=${KAM_DB_HOST}
DBPORT=${KAM_DB_PORT}
DBNAME=${KAM_DB_NAME}
DBRWUSER="${KAM_DB_USER}"
DBRWPW="${KAM_DB_PASS}"
DBROOTUSER="${MYSQL_ROOT_USERNAME}"
${ROOTPW_SETTING}
CHARSET=utf8
INSTALL_EXTRA_TABLES=yes
INSTALL_PRESENCE_TABLES=yes
INSTALL_DBUID_TABLES=yes
# STORE_PLAINTEXT_PW=0
EOF
    ) > ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc

    # fix bug in kamilio v5.3.4 installer
    if [[ "$(kamailio -V | head -1 | awk '{print $3}')" == "5.3.4" ]]; then
        (cat << 'EOF'
CREATE TABLE `secfilter` (
`id` INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
`action` SMALLINT DEFAULT 0 NOT NULL,
`type` SMALLINT DEFAULT 0 NOT NULL,
`data` VARCHAR(64) DEFAULT "" NOT NULL
);
CREATE INDEX secfilter_idx ON secfilter (`action`, `type`, `data`);
INSERT INTO version (table_name, table_version) values ("secfilter","1");
EOF
        ) > /usr/share/kamailio/mysql/secfilter-create.sql
    fi

    # Execute 'kamdbctl create' to create the Kamailio database schema
    kamdbctl create

    # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl start firewalld

    # Firewall settings
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIPS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_WSS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_DMQ_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp
    firewall-cmd --reload

    # Configure rsyslog defaults
    if ! grep -q 'dSIPRouter rsyslog.conf' /etc/rsyslog.conf 2>/dev/null; then
        cp -f ${DSIP_PROJECT_DIR}/resources/syslog/rsyslog.conf /etc/rsyslog.conf
    fi

    # Setup kamailio Logging
    cp -f ${DSIP_PROJECT_DIR}/resources/syslog/kamailio.conf /etc/rsyslog.d/kamailio.conf
    touch /var/log/kamailio.log
    systemctl restart rsyslog

    # Setup logrotate
    cp -f ${DSIP_PROJECT_DIR}/resources/logrotate/kamailio /etc/logrotate.d/kamailio

    # Setup Kamailio to use the CA cert's that are shipped with the OS
    mkdir -p ${DSIP_SYSTEM_CONFIG_DIR}/certs
    cp /etc/ssl/certs/ca-certificates.crt ${DSIP_SYSTEM_CONFIG_DIR}/certs/cacert.pem

    # Setup dSIPRouter Module
    KAM_VERSION=$(kamailio -V | head -1 | awk '{print $3}' | sed  's/\.//g')
    cp -f ${DSIP_PROJECT_DIR}/kamailio/debian/modules/dsiprouter_${KAM_VERSION}.so /usr/lib/x86_64-linux-gnu/kamailio/modules/dsiprouter.so
    if [ $? -gt 0 ]; then
        echo "No dSIPRouter module for Kamailio version ${KAM_VERSION}"
        return 1
    fi

    return 0
}

function uninstall {
    # Stop and disable services
    systemctl stop kamailio
    systemctl stop mysql
    systemctl disable kamailio
    systemctl disable mysql

    # Backup kamailio configuration directory
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR} ${SYSTEM_KAMAILIO_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)

    # Backup mysql / mariadb
    mv -f /var/lib/mysql /var/lib/mysql.bak.$(date +%Y%m%d_%H%M%S)

    # remove mysql unit files we created
    rm -f /lib/systemd/system/mysql.service /lib/systemd/system/mysqld.service

    # Uninstall Kamailio modules and Mariadb
    apt-get -y remove --purge mysql\*
    apt-get -y remove --purge mariadb\*
    apt-get -y remove --purge kamailio\*
    rm -rf /etc/my.cnf*; rm -f /etc/my.cnf*; rm -f ~/*my.cnf

    # Remove firewall rules that was created by us:
    firewall-cmd --zone=public --remove-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_SIP_PORT}/tcp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_SIPS_PORT}/tcp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_WSS_PORT}/tcp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_DMQ_PORT}/udp --permanent
    firewall-cmd --zone=public --remove-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp
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
