#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install() {
    local KAM_SOURCES_LIST="/etc/apt/sources.list.d/kamailio.list"
    local KAM_PREFS_CONF="/etc/apt/preferences.d/kamailio.pref"
    local NPROC=$(nproc)

    # nf_tables is the default fw on ubuntu but it has too many bugs at this time
    # instead we will use legacy iptables until these issues are ironed out
    update-alternatives --set iptables /usr/sbin/iptables-legacy
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

    # Install Dependencies
    apt-get install -y curl wget sed gawk vim perl uuid-dev libssl-dev logrotate rsyslog \
        libcurl4-openssl-dev libjansson-dev cmake firewalld python3 python3-venv

    if (( $? != 0 )); then
        printerr 'Failed installing required packages'
        exit 1
    fi

    ## compile and install openssl v1.1.1 (workaround for amazon linux repo conflicts)
    ## we must overwrite system packages (openssl/openssl-devel) otherwise python's openssl package is not supported
    if [[ "$(openssl version 2>/dev/null | awk '{print $2}')" != "1.1.1w" ]]; then
        if [[ ! -d ${SRC_DIR}/openssl ]]; then
            ( cd ${SRC_DIR} &&
            curl -sL https://www.openssl.org/source/openssl-1.1.1w.tar.gz 2>/dev/null |
            tar -xzf - --transform 's%openssl-1.1.1w%openssl%'; )
        fi
        (
            cd ${SRC_DIR}/openssl &&
            ./Configure --prefix=/usr linux-$(uname -m) &&
            make -j $NPROC &&
            make -j $NPROC install
        ) || {
            printerr 'Failed to compile openssl'
            return 1
        }
    fi

    # we need a newer version of certbot than the distro repos offer
    apt-get remove -y *certbot*
    python3 -m venv /opt/certbot/
    /opt/certbot/bin/pip install --upgrade pip
    /opt/certbot/bin/pip install certbot
    ln -sf /opt/certbot/bin/certbot /usr/bin/certbot

    # create kamailio user and group
    mkdir -p /var/run/kamailio
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel kamailio &>/dev/null; groupdel kamailio &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "Kamailio SIP Proxy" kamailio
    chown -R kamailio:kamailio /var/run/kamailio

    # add repo sources to apt
    mkdir -p /etc/apt/sources.list.d
    (cat << EOF
# kamailio repo's
deb https://deb-archive.kamailio.org/repos/kamailio-${KAM_VERSION} jammy main
#deb-src https://deb-archive.kamailio.org/repos/kamailio-${KAM_VERSION} jammy main
EOF
    ) > ${KAM_SOURCES_LIST}

    # give higher precedence to packages from kamailio repo
    mkdir -p /etc/apt/preferences.d
    (cat << 'EOF'
Package: *
Pin: origin deb-archive.kamailio.org
Pin-Priority: 1000
EOF
    ) > ${KAM_PREFS_CONF}

    # Add Key for Kamailio Repo
    wget -O- https://deb-archive.kamailio.org/kamailiodebkey.gpg | apt-key add -

    # Update repo sources cache
    apt-get update -y

    # Install Kamailio packages
    apt-get install -y kamailio kamailio-mysql-modules kamailio-extra-modules kamailio-tls-modules \
        kamailio-websocket-modules kamailio-presence-modules kamailio-json-modules kamailio-sctp-modules

    # get info about the kamailio install for later use in script
    KAM_MODULES_DIR=$(find /usr/lib{32,64,}/{i386*/*,i386*/kamailio/*,x86_64*/*,x86_64*/kamailio/*,*} -name drouting.so -printf '%h' -quit 2>/dev/null)

    # create kamailio defaults config
    cp -f ${DSIP_PROJECT_DIR}/kamailio/systemd/kamailio.conf /etc/default/kamailio.conf
    # create kamailio tmp files
    echo "d /run/kamailio 0750 kamailio kamailio" > /etc/tmpfiles.d/kamailio.conf

    # Configure Kamailio and Required Database Modules
    mkdir -p ${SYSTEM_KAMAILIO_CONFIG_DIR} ${BACKUPS_DIR}/kamailio
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc ${BACKUPS_DIR}/kamailio/kamctlrc.$(date +%Y%m%d_%H%M%S)
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
EXTRA_MODULES="imc cpl siptrace domainpolicy carrierroute drouting userblocklist htable purple uac pipelimit mtree sca mohqueue rtpproxy rtpengine secfilter"
INSTALL_EXTRA_TABLES=yes
INSTALL_PRESENCE_TABLES=yes
INSTALL_DBUID_TABLES=yes
#STORE_PLAINTEXT_PW=0
EOF
    ) > ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc

    # Execute 'kamdbctl create' to create the Kamailio database schema
    kamdbctl create

    # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl start firewalld

    # Setup firewall rules
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIPS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_WSS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_DMQ_PORT}/udp --permanent
    firewall-cmd --reload

    # Make sure MariaDB and Local DNS start before Kamailio
    if ! grep -q -v 'mariadb.service dnsmasq.service' /lib/systemd/system/kamailio.service 2>/dev/null; then
        sed -i -r -e 's/(After=.*)/\1 mariadb.service dnsmasq.service/' /lib/systemd/system/kamailio.service
    fi
    if ! grep -q -v "${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig" /lib/systemd/system/kamailio.service 2>/dev/null; then
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
    ln -s /etc/ssl/certs/ca-certificates.crt ${DSIP_SSL_CA}
    updateCACertsDir

    # setup STIR/SHAKEN module for kamailio
    ## compile and install libjwt (version in repos is too old)
    if [[ ! -d ${SRC_DIR}/libjwt ]]; then
        git clone --depth 1 -c advice.detachedHead=false -b v2.1.1 https://github.com/devopsec/libjwt.git ${SRC_DIR}/libjwt
    fi
    (
        cd ${SRC_DIR}/libjwt &&
        autoreconf -i &&
        ./configure --prefix=/usr &&
        make -j $NPROC &&
        make -j $NPROC install
    ) || {
        printerr 'Failed to compile and install libjwt'
        return 1
    }

    ## compile and install libks
    if [[ ! -d ${SRC_DIR}/libks ]]; then
        git clone --single-branch -c advice.detachedHead=false https://github.com/signalwire/libks -b v1.8.3 ${SRC_DIR}/libks
    fi
    (
        cd ${SRC_DIR}/libks &&
        cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release . &&
        make -j $NPROC &&
        make -j $NPROC install
    ) || {
        printerr 'Failed to compile and install libks'
        return 1
    }

    ## compile and install libstirshaken
    if [[ ! -d ${SRC_DIR}/libstirshaken ]]; then
        git clone --depth 1 -c advice.detachedHead=false https://github.com/signalwire/libstirshaken ${SRC_DIR}/libstirshaken
    fi
    (
        # TODO: commit updates to upstream to fix EVP_PKEY_cmp being deprecated
        cd ${SRC_DIR}/libstirshaken &&
        ./bootstrap.sh &&
        ./configure --prefix=/usr CFLAGS='-Wno-deprecated-declarations' LDFLAGS='-L/usr/lib' &&
        make -j $NPROC &&
        make -j $NPROC install &&
        ldconfig
    ) || {
        printerr 'Failed to compile and install libstirshaken'
        return 1
    }

    ## compile and install STIR/SHAKEN module
    ## reuse repo if it exists and matches version we want to install
    if [[ -d ${SRC_DIR}/kamailio ]]; then
        if [[ "$(getGitTagFromShallowRepo ${SRC_DIR}/kamailio)" != "${KAM_VERSION}" ]]; then
            rm -rf ${SRC_DIR}/kamailio
            git clone --depth 1 -c advice.detachedHead=false -b ${KAM_VERSION} https://github.com/kamailio/kamailio.git ${SRC_DIR}/kamailio
        fi
    else
        git clone --depth 1 -c advice.detachedHead=false -b ${KAM_VERSION} https://github.com/kamailio/kamailio.git ${SRC_DIR}/kamailio
    fi
    (
        cd ${SRC_DIR}/kamailio/src/modules/stirshaken &&
        make -j $NPROC
    ) &&
    cp -f ${SRC_DIR}/kamailio/src/modules/stirshaken/stirshaken.so ${KAM_MODULES_DIR}/ || {
        printerr 'Failed to compile and install STIR/SHAKEN module'
        return 1
    }

    # patch uac module to support reload_delta
    # TODO: commit upstream (https://github.com/kamailio/kamailio.git)
    (
        cd ${SRC_DIR}/kamailio/src/modules/uac &&
        patch -p4 -N <${DSIP_PROJECT_DIR}/kamailio/uac.patch
        (( $? > 1 )) && exit 1
        make -j $NPROC &&
        cp -f ${SRC_DIR}/kamailio/src/modules/uac/uac.so ${KAM_MODULES_DIR}/
    ) || {
        printerr 'Failed to patch uac module'
        return 1
    }

    return 0
}

function uninstall() {
    # Stop and disable services
    systemctl stop kamailio
    systemctl disable kamailio

    # Backup kamailio configuration directory
    cp -rf ${SYSTEM_KAMAILIO_CONFIG_DIR}/. ${BACKUPS_DIR}/kamailio/
    rm -rf ${SYSTEM_KAMAILIO_CONFIG_DIR}

    # Uninstall Stirshaken Required Packages
    ( cd ${SRC_DIR}/libjwt; make uninstall; exit $?; ) && rm -rf ${SRC_DIR}/libjwt
    ( cd ${SRC_DIR}/libks; make uninstall; exit $?; ) && rm -rf ${SRC_DIR}/libks
    ( cd ${SRC_DIR}/libstirshaken; make uninstall;exit $?; ) && rm -rf ${SRC_DIR}/libstirshaken
    rm -rf ${SRC_DIR}/kamailio

    # Uninstall Kamailio modules
    apt-get -y remove --purge kamailio\*

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

    return 0
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
