#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install {
    local KAM_SOURCES_LIST="/etc/apt/sources.list.d/kamailio.list"
    local KAM_PREFS_CONF="/etc/apt/preferences.d/kamailio.pref"

    # nf_tables is the default fw on debian but it has too many bugs at this time
    # instead we will use legacy iptables until these issues are ironed out
    update-alternatives --set iptables /usr/sbin/iptables-legacy
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

    # Install Dependencies
    apt-get install -y curl wget sed gawk vim perl uuid-dev libssl-dev
    apt-get install -y logrotate rsyslog

    # create kamailio user and group
    mkdir -p /var/run/kamailio
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "Kamailio SIP Proxy" kamailio
    chown -R kamailio:kamailio /var/run/kamailio

    KAM_VERSION=55
    # add repo sources to apt
    mkdir -p /etc/apt/sources.list.d
    (cat << EOF
# kamailio repo's
deb http://deb.kamailio.org/kamailio${KAM_VERSION} bullseye main
#deb-src http://deb.kamailio.org/kamailio${KAM_VERSION} bullseye main
EOF
    ) > ${KAM_SOURCES_LIST}

    # give higher precedence to packages from kamailio repo
    mkdir -p /etc/apt/preferences.d
    (cat << 'EOF'
Package: *
Pin: origin deb.kamailio.org
Pin-Priority: 1000
EOF
    ) > ${KAM_PREFS_CONF}

    # Add Key for Kamailio Repo
    wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | apt-key add -

    # Update repo sources cache
    apt-get update -y

    # Install Kamailio packages
    apt-get install -y --allow-unauthenticated firewalld certbot kamailio kamailio-mysql-modules kamailio-extra-modules \
        kamailio-tls-modules kamailio-websocket-modules kamailio-presence-modules kamailio-json-modules

    # get info about the kamailio install for later use in script
    KAM_VERSION_FULL=$(kamailio -v 2>/dev/null | grep '^version:' | awk '{print $3}')
    KAM_MODULES_DIR=$(find /usr/lib{32,64,}/{i386*/*,i386*/kamailio/*,x86_64*/*,x86_64*/kamailio/*,*} -name drouting.so -printf '%h' -quit 2>/dev/null)

    # Make sure MariaDB and Local DNS start before Kamailio
    if ! grep -q -v 'mysql.service dnsmasq.service' /lib/systemd/system/kamailio.service 2>/dev/null; then
        sed -i -r -e 's/(After=.*)/\1 mysql.service dnsmasq.service/' /lib/systemd/system/kamailio.service
    fi
    if ! grep -q -v "${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig" /lib/systemd/system/kamailio.service 2>/dev/null; then
        sed -i -r -e "0,\|^ExecStart.*|{s||ExecStartPre=-${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig\n&|}" /lib/systemd/system/kamailio.service
    fi
    systemctl daemon-reload

    # Enable Kamailio for system startup
    systemctl enable kamailio

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
    if [[ -z "${ROOT_DB_PASS-unset}" ]]; then
        local ROOTPW_SETTING="DBROOTPWSKIP=yes"
    else
        local ROOTPW_SETTING="DBROOTPW=\"${ROOT_DB_PASS}\""
    fi

    # TODO: we should set STORE_PLAINTEXT_PW to 0, this is not default but would need tested
    (cat << EOF
DBENGINE=MYSQL
DBHOST="${KAM_DB_HOST}"
DBPORT="${KAM_DB_PORT}"
DBNAME="${KAM_DB_NAME}"
DBROUSER="${KAM_DB_USER}"
DBROPW="${KAM_DB_PASS}"
DBRWUSER="${KAM_DB_USER}"
DBRWPW="${KAM_DB_PASS}"
DBROOTUSER="${ROOT_DB_USER}"
${ROOTPW_SETTING}
CHARSET=utf8
INSTALL_EXTRA_TABLES=yes
INSTALL_PRESENCE_TABLES=yes
INSTALL_DBUID_TABLES=yes
#STORE_PLAINTEXT_PW=0
EOF
    ) > ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc

    # fix bug in kamilio v5.3.4 installer
    if [[ "$KAM_VERSION_FULL" == "5.3.4" ]]; then
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
    cp ${DSIP_PROJECT_DIR}/kamailio/cacert_dsiprouter.pem ${DSIP_SYSTEM_CONFIG_DIR}/certs/cacert.pem

    # Setup dSIPRouter Module
    rm -rf /tmp/kamailio 2>/dev/null
    git clone --depth 1 -b ${KAM_VERSION_FULL} https://github.com/kamailio/kamailio.git /tmp/kamailio 2>/dev/null &&
    cp -rf ${DSIP_PROJECT_DIR}/kamailio/modules/dsiprouter/ /tmp/kamailio/src/modules/ &&
    ( cd /tmp/kamailio/src/modules/dsiprouter; make; exit $?; ) &&
    cp -f /tmp/kamailio/src/modules/dsiprouter/dsiprouter.so ${KAM_MODULES_DIR} ||
    return 1

    return 0
}

function uninstall {
    # Stop and disable services
    systemctl stop kamailio
    systemctl disable kamailio

    # Backup kamailio configuration directory
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR} ${SYSTEM_KAMAILIO_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)

    # Uninstall Kamailio modules
    apt-get -y remove --purge kamailio\*

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
        printerr "usage $0 [install | uninstall]"
        ;;
esac
