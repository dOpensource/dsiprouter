#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install() {
    # Install Dependencies
    yum groupinstall -y 'core' &&
    yum groupinstall -y 'base' &&
    yum groupinstall -y 'Development Tools' &&
    yum install -y psmisc curl wget sed gawk vim epel-release perl firewalld uuid-devel \
        openssl-devel logrotate rsyslog certbot policycoreutils-python

    if (( $? != 0 )); then
        printerr 'Failed installing required packages'
        return 1
    fi

    # create kamailio user and group
    mkdir -p /var/run/kamailio
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "Kamailio SIP Proxy" kamailio
    chown -R kamailio:kamailio /var/run/kamailio

    KAM_REPO="kamailio-$(perl -pe 's%([0-9])(?=[0-9])%\1\.%g' <<<${KAM_VERSION})"
    yum install -y yum-utils
    yum-config-manager --add-repo https://rpm.kamailio.org/centos/kamailio.repo
    rpm --import $(grep 'gpgkey' /etc/yum.repos.d/kamailio.repo | cut -d '=' -f 2 | sort -u)
    # TODO: get the kamailio guys to fix their rpm signing
    yum install -y --disablerepo=kamailio --enablerepo=${KAM_REPO} --nogpgcheck kamailio kamailio-ldap kamailio-mysql \
        kamailio-postgresql kamailio-debuginfo kamailio-xmpp kamailio-unixodbc kamailio-utils kamailio-tls \
        kamailio-presence kamailio-outbound kamailio-gzcompress kamailio-http_async_client kamailio-dmq_userloc \
        kamailio-sipdump kamailio-websocket

    # get info about the kamailio install for later use in script
    KAM_VERSION_FULL=$(kamailio -v 2>/dev/null | grep '^version:' | awk '{print $3}')
    KAM_MODULES_DIR=$(find /usr/lib{32,64,}/{i386*/*,i386*/kamailio/*,x86_64*/*,x86_64*/kamailio/*,*} -name drouting.so -printf '%h' -quit 2>/dev/null)

    touch /etc/tmpfiles.d/kamailio.conf
    echo "d /run/kamailio 0750 kamailio users" > /etc/tmpfiles.d/kamailio.conf

    # create kamailio defaults config
    cp -f ${DSIP_PROJECT_DIR}/kamailio/systemd/kamailio.conf /etc/default/kamailio.conf

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
# STORE_PLAINTEXT_PW=0
EOF
    ) > ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc

    # Execute 'kamdbctl create' to create the Kamailio database schema
    kamdbctl create

    # give kamailio permissions in SELINUX
    semanage port -a -t sip_port_t -p udp ${KAM_SIP_PORT} || semanage port -m -t sip_port_t -p udp ${KAM_SIP_PORT}
    semanage port -a -t sip_port_t -p tcp ${KAM_SIP_PORT} || semanage port -m -t sip_port_t -p tcp ${KAM_SIP_PORT}
    semanage port -a -t sip_port_t -p tcp ${KAM_SIPS_PORT} || semanage port -m -t sip_port_t -p tcp ${KAM_SIPS_PORT}
    semanage port -a -t sip_port_t -p tcp ${KAM_WSS_PORT} || semanage port -m -t sip_port_t -p tcp ${KAM_WSS_PORT}
    semanage port -a -t sip_port_t -p udp ${KAM_DMQ_PORT} || semanage port -m -t sip_port_t -p udp ${KAM_DMQ_PORT}

    # Start firewalld
    systemctl start firewalld
    systemctl enable firewalld

    if (( $? != 0 )); then
        # fix for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1575845
        systemctl restart dbus
        systemctl restart firewalld
        # fix for ensuing bug: https://bugzilla.redhat.com/show_bug.cgi?id=1372925
        systemctl restart systemd-logind
    fi

    # Setup firewall rules
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIPS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_WSS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_DMQ_PORT}/udp --permanent
    firewall-cmd --reload

    # Make sure MariaDB and Local DNS start before Kamailio
    if ! grep -q v 'mariadb.service dnsmasq.service' /lib/systemd/system/kamailio.service 2>/dev/null; then
        sed -i -r -e 's/(After=.*)/\1 mariadb.service dnsmasq.service/' /lib/systemd/system/kamailio.service
    fi
    if ! grep -q v "${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig" /lib/systemd/system/kamailio.service 2>/dev/null; then
        sed -i -r -e "0,\|^ExecStart.*|{s||ExecStartPre=-${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig\n&|}" /lib/systemd/system/kamailio.service
    fi
    systemctl daemon-reload

    # Enable Kamailio for system startup
    systemctl enable kamailio

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
    mkdir -p ${DSIP_SYSTEM_CONFIG_DIR}/certs/stirshaken
    cp ${DSIP_PROJECT_DIR}/kamailio/ca-list.pem ${DSIP_SSL_CA}

    # Setup dSIPRouter Module
    rm -rf /tmp/kamailio 2>/dev/null
    git clone --depth 1 -c advice.detachedHead=false -b ${KAM_VERSION_FULL} https://github.com/kamailio/kamailio.git /tmp/kamailio 2>/dev/null &&
    cp -rf ${DSIP_PROJECT_DIR}/kamailio/modules/dsiprouter/ /tmp/kamailio/src/modules/ &&
    ( cd /tmp/kamailio/src/modules/dsiprouter; make; exit $?; ) &&
    cp -f /tmp/kamailio/src/modules/dsiprouter/dsiprouter.so ${KAM_MODULES_DIR} ||
    return 1

    return 0
}

function uninstall {
    # Stop servers
    systemctl stop kamailio
    systemctl disable kamailio

    # Backup kamailio configuration directory
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR} ${SYSTEM_KAMAILIO_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)

    # Uninstall Kamailio modules
    yum remove -y kamailio\*

    # Remove firewall rules that was created by us:
    firewall-cmd --zone=public --remove-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_SIP_PORT}/tcp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_SIPS_PORT}/tcp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_WSS_PORT}/tcp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_DMQ_PORT}/udp --permanent
    firewall-cmd --reload

    # Remove kamailio Logging
    rm -f /etc/rsyslog.d/kamailio.conf

    # Remove logrotate settings
    rm -f /etc/logrotate.d/kamailio
}

case "$1" in
    install)
        install && exit 0 || exit 1
        ;;
    uninstall)
        uninstall && exit 0 || exit 1
        ;;
    *)
        printerr "Usage: $0 [install | uninstall]"
        exit 1
        ;;
esac
