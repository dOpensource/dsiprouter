#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install() {
    local NPROC=$(nproc)

    # create dsiprouter user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel dsiprouter &>/dev/null; groupdel dsiprouter &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "dSIPRouter SIP Provider Platform" dsiprouter

    # Install dependencies for dSIPRouter
    yum install -y yum-utils &&
    yum groupinstall --setopt=group_package_types=mandatory,default -y 'Development Tools' &&
    yum install -y firewalld logrotate rsyslog perl libev-devel util-linux postgresql-devel \
        bzip2-devel libffi-devel zlib-devel curl

    if (( $? != 0 )); then
        printerr 'Failed installing required packages'
        return 1
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

    # make sure the nginx user has access to dsiprouter directories
    usermod -a -G dsiprouter nginx
    # make dsiprouter user has access to kamailio files
    usermod -a -G kamailio dsiprouter

    # setup runtime directorys for dsiprouter
    mkdir -p ${DSIP_RUN_DIR}
    chown -R dsiprouter:dsiprouter ${DSIP_RUN_DIR}

    # give dsiprouter permissions in SELINUX
    semanage port -a -t http_port_t -p tcp ${DSIP_PORT} ||
        semanage port -m -t http_port_t -p tcp ${DSIP_PORT}

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

    # Setup Firewall for DSIP_PORT
    firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
    firewall-cmd --reload

    python3 -m venv --upgrade-deps ${PYTHON_VENV} &&
    ${PYTHON_CMD} -m pip install -r ${DSIP_PROJECT_DIR}/gui/requirements.txt
    if (( $? == 1 )); then
        printerr "Failed installing required python libraries"
        return 1
    fi

    # setup dsiprouter nginx configs
    perl -e "\$dsip_port='${DSIP_PORT}'; \$dsip_unix_sock='${DSIP_UNIX_SOCK}'; \$dsip_ssl_cert='${DSIP_SSL_CERT}'; \$dsip_ssl_key='${DSIP_SSL_KEY}';" \
        -pe 's%DSIP_UNIX_SOCK%${dsip_unix_sock}%g; s%DSIP_PORT%${dsip_port}%g; s%DSIP_SSL_CERT%${dsip_ssl_cert}%g; s%DSIP_SSL_KEY%${dsip_ssl_key}%g;' \
        ${DSIP_PROJECT_DIR}/nginx/configs/dsiprouter.conf >/etc/nginx/sites-available/dsiprouter.conf
    ln -sf /etc/nginx/sites-available/dsiprouter.conf /etc/nginx/sites-enabled/dsiprouter.conf

    # Configure rsyslog defaults
    if ! grep -q 'dSIPRouter rsyslog.conf' /etc/rsyslog.conf 2>/dev/null; then
        cp -f ${DSIP_PROJECT_DIR}/resources/syslog/rsyslog.conf /etc/rsyslog.conf
    fi

    # Setup dSIPRouter Logging
    cp -f ${DSIP_PROJECT_DIR}/resources/syslog/dsiprouter.conf /etc/rsyslog.d/dsiprouter.conf
    touch /var/log/dsiprouter.log
    systemctl restart rsyslog

    # Setup logrotate
    cp -f ${DSIP_PROJECT_DIR}/resources/logrotate/dsiprouter /etc/logrotate.d/dsiprouter

    # Install dSIPRouter as a service
    perl -p \
        -e "s|'DSIP_RUN_DIR\=.*'|'DSIP_RUN_DIR=$DSIP_RUN_DIR'|;" \
        -e "s|'DSIP_PROJECT_DIR\=.*'|'DSIP_PROJECT_DIR=$DSIP_PROJECT_DIR'|;" \
        -e "s|'DSIP_SYSTEM_CONFIG_DIR\=.*'|'DSIP_SYSTEM_CONFIG_DIR=$DSIP_SYSTEM_CONFIG_DIR'|;" \
        ${DSIP_PROJECT_DIR}/dsiprouter/systemd/dsiprouter-v1.service > /lib/systemd/system/dsiprouter.service
    chmod 644 /lib/systemd/system/dsiprouter.service
    systemctl daemon-reload
    systemctl enable dsiprouter

    # add hook to bash_completion in the standard debian location
    echo '. /usr/share/bash-completion/bash_completion' > /etc/bash_completion

    return 0
}


function uninstall() {
    rm -rf ${PYTHON_VENV}

    # Remove Firewall for DSIP_PORT
    firewall-cmd --zone=public --remove-port=${DSIP_PORT}/tcp --permanent
    firewall-cmd --reload

    # Remove dSIPRouter Logging
    rm -f /etc/rsyslog.d/dsiprouter.conf

    # Remove logrotate settings
    rm -f /etc/logrotate.d/dsiprouter

    # Remove dSIProuter as a service
    systemctl stop dsiprouter.service
    systemctl disable dsiprouter.service
    rm -f /lib/systemd/system/dsiprouter.service
    systemctl daemon-reload

    return 0
}

case "$1" in
    uninstall)
        uninstall && exit 0 || exit 1
        ;;
    install)
        install && exit 0 || exit 1
        ;;
    *)
        printerr "usage $0 [install | uninstall]"
        exit 1
        ;;
esac
