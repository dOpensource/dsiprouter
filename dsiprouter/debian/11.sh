#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install() {
    # create dsiprouter user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel dsiprouter &>/dev/null; groupdel dsiprouter &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "dSIPRouter SIP Provider Platform" dsiprouter

    # Install dependencies for dSIPRouter
    apt-get install -y build-essential curl python3 python3-pip python3-dev python3-venv \
        libpq-dev firewalld sudo logrotate rsyslog perl sngrep libev-dev uuid-runtime \
        libmariadb-dev pkg-config

    if (( $? != 0 )); then
        printerr 'Failed installing required packages'
        return 1
    fi

    # make sure the nginx user has access to dsiprouter directories
    usermod -a -G dsiprouter nginx
    # make dsiprouter user has access to kamailio files
    usermod -a -G kamailio dsiprouter

    # setup runtime directorys for dsiprouter
    mkdir -p ${DSIP_RUN_DIR}
    chown -R dsiprouter:dsiprouter ${DSIP_RUN_DIR}

    # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl start firewalld

    # Setup Firewall for DSIP_PORT
    firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
    firewall-cmd --reload

    python3 -m venv --system-site-packages --upgrade-deps ${PYTHON_VENV} &&
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
        ${DSIP_PROJECT_DIR}/dsiprouter/systemd/dsiprouter-v2.service > /lib/systemd/system/dsiprouter.service
    chmod 644 /lib/systemd/system/dsiprouter.service
    systemctl daemon-reload
    systemctl enable dsiprouter

    return 0
}

function uninstall() {
    rm -rf ${PYTHON_VENV}

    # TODO: this is dangerous without dependency management (i.e. our own DEB)
#    apt-get remove -y build-essential curl python3 python3-pip python-dev python3-openssl libpq-dev firewalld
#    apt-get remove -y --allow-unauthenticated libmariadbclient-dev
#    apt-get remove -y logrotate rsyslog perl sngrep libev-dev uuid-runtime

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
