#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install() {
    local KAM_VERSION_DOTTED=$(perl -pe 's%([0-9])([0-9])%\1.\2%' <<<"$KAM_VERSION")
    local RHEL_BASE_VER=$(rpm -E %{rhel})

    # Install Dependencies
    amazon-linux-extras install -y epel >/dev/null
    yum groupinstall --setopt=group_package_types=mandatory,default,optional -y 'Development Tools'
    yum install -y psmisc curl wget sed gawk vim perl firewalld logrotate rsyslog python3 cmake3 gcc10
    yum install -y uuid-devel openssl-devel libtool jansson-devel libuuid-devel libcurl-devel

    # we need a newer version of certbot than the distro repos offer
    yum remove -y *certbot*
    python3 -m venv /opt/certbot/
    /opt/certbot/bin/pip install --upgrade pip
    /opt/certbot/bin/pip install certbot
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot

    # link latest version of cmake
    ln -sf /bin/cmake3 /usr/local/bin/cmake

    # TODO: we should detect if SELINUX is enabled and if so add proper permissions for kamailio, dsip, etc..
    # Disable SELinux
    sed -i -e 's/(^SELINUX=).*/SELINUX=disabled/' /etc/selinux/config

    # create kamailio user and group
    mkdir -p /var/run/kamailio
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel kamailio &>/dev/null; groupdel kamailio &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "Kamailio SIP Proxy" kamailio
    chown -R kamailio:kamailio /var/run/kamailio

    # Add the Kamailio repos to yum
    (cat <<EOF
[kamailio]
name=Kamailio
baseurl=https://rpm.kamailio.org/rhel/${RHEL_BASE_VER}/${KAM_VERSION_DOTTED}/${KAM_VERSION_DOTTED}/\$basearch/
enabled=1
metadata_expire=30d
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://rpm.kamailio.org/rpm-pub.key
type=rpm
EOF
    ) >/etc/yum.repos.d/kamailio.repo
    rpm --import https://rpm.kamailio.org/rpm-pub.key

    yum makecache -y
    yum install -y kamailio kamailio-ldap kamailio-mysql kamailio-sipdump kamailio-websocket kamailio-postgresql kamailio-debuginfo \
        kamailio-xmpp kamailio-unixodbc kamailio-utils kamailio-tls kamailio-presence kamailio-outbound kamailio-gzcompress \
        kamailio-http_async_client kamailio-dmq_userloc kamailio-jansson kamailio-json kamailio-uuid


    # get info about the kamailio install for later use in script
    KAM_VERSION_FULL=$(kamailio -v 2>/dev/null | grep '^version:' | awk '{print $3}')
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
INSTALL_EXTRA_TABLES=yes
INSTALL_PRESENCE_TABLES=yes
INSTALL_DBUID_TABLES=yes
#STORE_PLAINTEXT_PW=0
EOF
    ) > ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc

    # Execute 'kamdbctl create' to create the Kamailio database schema
    kamdbctl create

    # Start firewalld
    systemctl enable firewalld
    systemctl start firewalld

    # Fix for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1575845
    if (( $? != 0 )); then
        systemctl restart dbus
        systemctl restart firewalld
    fi

    # Setup firewall rules
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIPS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_WSS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_DMQ_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp
    firewall-cmd --reload

    # Configure Kamailio systemd service
    cp -f ${DSIP_PROJECT_DIR}/kamailio/systemd/kamailio-v1.service /etc/systemd/system/kamailio.service
    chmod 644 /etc/systemd/system/kamailio.service
    systemctl daemon-reload
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
    ln -s /etc/ssl/certs/ca-bundle.crt ${DSIP_SSL_CA}
    updateCACertsDir

    # setup dSIPRouter module for kamailio
    ## reuse repo if it exists and matches version we want to install
    if [[ -d ${SRC_DIR}/kamailio ]]; then
        if [[ "x$(cd ${SRC_DIR}/kamailio 2>/dev/null && git branch --show-current 2>/dev/null)" != "x${KAM_VERSION_FULL}" ]]; then
            rm -rf ${SRC_DIR}/kamailio
            git clone --depth 1 -b ${KAM_VERSION_FULL} https://github.com/kamailio/kamailio.git ${SRC_DIR}/kamailio
        fi
    else
        git clone --depth 1 -b ${KAM_VERSION_FULL} https://github.com/kamailio/kamailio.git ${SRC_DIR}/kamailio
    fi

    # setup STIR/SHAKEN module for kamailio
    ## compile and install libjwt
    if [[ ! -d ${SRC_DIR}/libjwt ]]; then
        git clone --depth 1 https://github.com/benmcollins/libjwt.git ${SRC_DIR}/libjwt
    fi
    ( cd ${SRC_DIR}/libjwt && autoreconf -i && ./configure --prefix=/usr --libdir=/usr/lib64 && make && make install; exit $?; ) ||
    { printerr 'Failed to compile and install libjwt'; return 1; }

    ## compile and install libks
    if [[ ! -d ${SRC_DIR}/libks ]]; then
        git clone --depth 1 https://github.com/signalwire/libks ${SRC_DIR}/libks
    fi
    ( cd ${SRC_DIR}/libks && cmake -DCMAKE_INSTALL_PREFIX=/usr . && make install &&
        ln -sft /usr/lib64/ /usr/lib/libks.so* && ln -sft /usr/lib64/pkgconfig/ /usr/lib/pkgconfig/libks.pc; exit $?;
    ) || { printerr 'Failed to compile and install libks'; return 1; }

    ## compile and install openssl v1.1.1 (workaround for amazon linux repo conflicts)
    ## we must overwrite system packages (openssl/openssl-devel) otherwise python's openssl package is not supported
    if [[ ! -d ${SRC_DIR}/openssl ]]; then
        ( cd ${SRC_DIR} &&
        curl -sL https://www.openssl.org/source/openssl-1.1.1q.tar.gz 2>/dev/null |
        tar -xzf - --transform 's%openssl-1.1.1q%openssl%'; )
    fi
    ( cd ${SRC_DIR}/openssl && ./Configure --prefix=/usr linux-$(uname -m) && make && make install; exit $?;
    ) || { printerr 'Failed to compile openssl'; return 1; }

    ## compile and install libstirshaken
    if [[ ! -d ${SRC_DIR}/libstirshaken ]]; then
        git clone --depth 1 https://github.com/signalwire/libstirshaken ${SRC_DIR}/libstirshaken
    fi
    ( cd ${SRC_DIR}/libstirshaken && ./bootstrap.sh && ./configure --prefix=/usr --libdir=/usr/lib64 \
        CC=/bin/gcc10-gcc CFLAGS=-I${SRC_DIR}/openssl/include PKG_CONFIG_PATH=${SRC_DIR}/openssl LDFLAGS=-L${SRC_DIR}/openssl &&
        make && make install && ldconfig; exit $?;
    ) || { printerr 'Failed to compile and install libstirshaken'; return 1; }

    ## compile and install STIR/SHAKEN module
    ( cd ${SRC_DIR}/kamailio/src/modules/stirshaken && make; exit $?; ) &&
    cp -f ${SRC_DIR}/kamailio/src/modules/stirshaken/stirshaken.so ${KAM_MODULES_DIR}/ ||
    { printerr 'Failed to compile and install STIR/SHAKEN module'; return 1; }

    return 0
}

function uninstall() {
    # Stop servers
    systemctl stop kamailio
    systemctl disable kamailio

    # Backup kamailio configuration directory
    cp -rf ${SYSTEM_KAMAILIO_CONFIG_DIR}/. ${BACKUPS_DIR}/kamailio/
    rm -rf ${SYSTEM_KAMAILIO_CONFIG_DIR}

    # Uninstall Stirshaken Required Packages
    ( cd ${SRC_DIR}/libjwt; make uninstall; exit $?; ) && rm -rf ${SRC_DIR}/libjwt
    ( cd ${SRC_DIR}/libks; make uninstall; exit $?; ) && { rm -rf ${SRC_DIR}/libks; rm -f /usr/lib64/{,pkgconfig/}libks*; }
    ( cd ${SRC_DIR}/libstirshaken; make uninstall; exit $?; ) && rm -rf ${SRC_DIR}/libstirshaken
    rm -rf ${SRC_DIR}/openssl
    rm -rf ${SRC_DIR}/kamailio

    # Uninstall Kamailio modules
    yum remove -y kamailio\*

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
