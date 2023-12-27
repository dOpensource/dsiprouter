#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install() {
    local KAM_VERSION_DOTTED RHEL_BASE_VER NPROC

    # Install Dependencies
    amazon-linux-extras install -y epel >/dev/null &&
    yum install -y yum-utils &&
    yum groupinstall --setopt=group_package_types=mandatory,default -y 'Development Tools' &&
    yum install -y psmisc curl wget sed gawk vim perl firewalld logrotate rsyslog cmake3 gcc10 \
        uuid-devel libtool jansson-devel libuuid-devel libcurl-devel libjwt-devel libatomic \
        bzip2-devel libffi-devel policycoreutils-python

    if (( $? != 0 )); then
        printerr 'Failed installing required packages'
        exit 1
    fi

    KAM_VERSION_DOTTED=$(perl -pe 's%([0-9])([0-9])%\1.\2%' <<<"$KAM_VERSION")
    RHEL_BASE_VER=$(rpm -E %{rhel})
    NPROC=$(nproc)

    # link latest version of cmake
    ln -sf $(which cmake3) /usr/local/bin/cmake

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
            make -j $NRPOC &&
            make -j $NPROC install
        ) || {
            printerr 'Failed to compile openssl'
            return 1
        }
    fi

    # python 3.8 or higher is required
    # if not installed already, install it now
    if [[ "$(python3 -V 2>/dev/null | cut -d ' ' -f 2)" != "3.9.18" ]]; then
        # installation / compilation never completed, start it now
        if [[ ! -d "${SRC_DIR}/Python-3.9.18" ]]; then
            (
                cd ${SRC_DIR} &&
                curl -s -o Python-3.9.18.tgz https://www.python.org/ftp/python/3.9.18/Python-3.9.18.tgz &&
                tar -xf Python-3.9.18.tgz &&
                rm -f Python-3.9.18.tgz
            )
        fi
        (
            cd ${SRC_DIR} &&
            cd Python-3.9.18/ &&
            ./configure --enable-optimizations CFLAGS=-I${SRC_DIR}/openssl/include LDFLAGS=-L${SRC_DIR}/openssl &&
            make -j $NPROC &&
            make -j $NPROC install
        ) || {
            printerr 'Failed to compile and install required python version'
            return 1
        }
        python3 -m pip install -U pip setuptools || {
            printerr 'Failed to update pip and setuptools'
            return 1
        }
    fi

    # we need a newer version of certbot than the distro repos offer
    yum remove -y *certbot*
    python3 -m venv /opt/certbot/
    /opt/certbot/bin/pip install --upgrade pip
    /opt/certbot/bin/pip install certbot
    ln -sf /opt/certbot/bin/certbot /usr/bin/certbot

    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel kamailio &>/dev/null; groupdel kamailio &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "Kamailio SIP Proxy" kamailio

    # TODO: amzn2 should be based off rhel not centos but the kamailio rhel repos are out of date
    yum-config-manager -y --add-repo https://rpm.kamailio.org/centos/kamailio.repo &&
    echo $RHEL_BASE_VER >/etc/yum/vars/rhelver &&
    perl -i -pe 's%\$releasever%\$rhelver%g' /etc/yum.repos.d/kamailio.repo
    yum-config-manager --disable 'kamailio*' >/dev/null &&
    yum-config-manager --enable "kamailio-$KAM_VERSION_DOTTED" >/dev/null &&
    yum install -y kamailio kamailio-ldap kamailio-mysql kamailio-sipdump kamailio-websocket kamailio-postgresql kamailio-debuginfo \
        kamailio-xmpp kamailio-unixodbc kamailio-utils kamailio-tls kamailio-presence kamailio-outbound kamailio-gzcompress \
        kamailio-http_async_client kamailio-dmq_userloc kamailio-jansson kamailio-json kamailio-uuid

    if (( $? != 0 )); then
        printerr 'Failed installing kamailio packages'
        exit 1
    fi

    # get info about the kamailio install for later use in script
    KAM_VERSION_FULL=$(kamailio -v 2>/dev/null | awk '/^version:/ {print $3}')
    KAM_MODULES_DIR=$(find /usr/lib{32,64,}/{i386*/*,i386*/kamailio/*,x86_64*/*,x86_64*/kamailio/*,*} -name drouting.so -printf '%h' -quit 2>/dev/null)

    # make sure run dir exists
    mkdir -p /var/run/kamailio
    chown -R kamailio:kamailio /var/run/kamailio

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
    cat <<EOF >${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
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

    # Execute 'kamdbctl create' to create the Kamailio database schema
    kamdbctl create

    # give kamailio permissions in SELINUX
    semanage port -a -t sip_port_t -p udp ${KAM_SIP_PORT} || semanage port -m -t sip_port_t -p udp ${KAM_SIP_PORT}
    semanage port -a -t sip_port_t -p tcp ${KAM_SIP_PORT} || semanage port -m -t sip_port_t -p tcp ${KAM_SIP_PORT}
    semanage port -a -t sip_port_t -p tcp ${KAM_SIPS_PORT} || semanage port -m -t sip_port_t -p tcp ${KAM_SIPS_PORT}
    semanage port -a -t sip_port_t -p tcp ${KAM_WSS_PORT} || semanage port -m -t sip_port_t -p tcp ${KAM_WSS_PORT}
    semanage port -a -t sip_port_t -p udp ${KAM_DMQ_PORT} || semanage port -m -t sip_port_t -p udp ${KAM_DMQ_PORT}

    # Start firewalld
    systemctl enable firewalld
    systemctl start firewalld

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

    # Configure Kamailio systemd service
    cp -f ${DSIP_PROJECT_DIR}/kamailio/systemd/kamailio-v1.service /lib/systemd/system/kamailio.service
    chmod 644 /lib/systemd/system/kamailio.service
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

    # setup STIR/SHAKEN module for kamailio
    ## compile and install libjwt
    #if [[ ! -d ${SRC_DIR}/libjwt ]]; then
    #    git clone --depth 1 -c advice.detachedHead=false https://github.com/benmcollins/libjwt.git ${SRC_DIR}/libjwt
    #fi
    #( cd ${SRC_DIR}/libjwt && autoreconf -i && ./configure --prefix=/usr --libdir=/usr/lib64 && make && make install; exit $?; ) ||
    #{ printerr 'Failed to compile and install libjwt'; return 1; }

    ## compile and install libks
    if [[ ! -d ${SRC_DIR}/libks ]]; then
        git clone --single-branch -c advice.detachedHead=false https://github.com/signalwire/libks -b v1.8.3 ${SRC_DIR}/libks
    fi
    (
        cd ${SRC_DIR}/libks &&
        cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release . &&
        make -j $NPROC &&
        make -j $NPROC install &&
        ln -sft /usr/lib64/ /usr/lib/libks.so* &&
        ln -sft /usr/lib64/pkgconfig/ /usr/lib/pkgconfig/libks.pc
    ) || {
        printerr 'Failed to compile and install libks'
        return 1
    }

    ## compile and install libstirshaken
    if [[ ! -d ${SRC_DIR}/libstirshaken ]]; then
        git clone --depth 1 -c advice.detachedHead=false https://github.com/signalwire/libstirshaken ${SRC_DIR}/libstirshaken
    fi
    (
        cd ${SRC_DIR}/libstirshaken &&
        ./bootstrap.sh &&
        ./configure --prefix=/usr --libdir=/usr/lib64 CC=/bin/gcc10-gcc CXX=/usr/bin/gcc10-g++ \
            CFLAGS=-I${SRC_DIR}/openssl/include LDFLAGS=-L${SRC_DIR}/openssl \
            PKG_CONFIG_PATH=${SRC_DIR}/openssl &&
        make -j $NPROC CFLAGS='-Wno-deprecated-declarations' &&
        make -j $NPROC install &&
        ldconfig
    ) || {
        printerr 'Failed to compile and install libstirshaken'
        return
    }

    ## compile and install STIR/SHAKEN module
    ## reuse repo if it exists and matches version we want to install
    if [[ -d ${SRC_DIR}/kamailio ]]; then
        if [[ "$(getGitTagFromShallowRepo ${SRC_DIR}/kamailio)" != "${KAM_VERSION_FULL}" ]]; then
            rm -rf ${SRC_DIR}/kamailio
            git clone --depth 1 -c advice.detachedHead=false -b ${KAM_VERSION_FULL} https://github.com/kamailio/kamailio.git ${SRC_DIR}/kamailio
        fi
    else
        git clone --depth 1 -c advice.detachedHead=false -b ${KAM_VERSION_FULL} https://github.com/kamailio/kamailio.git ${SRC_DIR}/kamailio
    fi
    (
        cd ${SRC_DIR}/kamailio/src/modules/stirshaken &&
        make -j $NPROC
    ) &&
    cp -f ${SRC_DIR}/kamailio/src/modules/stirshaken/stirshaken.so ${KAM_MODULES_DIR}/ || {
        printerr 'Failed to compile and install STIR/SHAKEN module'
        return 1
    }

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
