#!/usr/bin/env bash

(( $DEBUG == 1 )) && set -x

function install {
    # Install dependencies for dSIPRouter
    apt-get install -y build-essential curl python3 python3-pip python-dev libmysqlclient-dev libmariadb-client-lgpl-dev libpq-dev \
        firewalld logrotate rsyslog perl libev-dev uuid-runtime

    # create dsiprouter user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "dSIPRouter SIP Provider Platform" dsiprouter

    # Reset python cmd in case it was just installed
    setPythonCmd

    # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl start firewalld

    # Setup Firewall for DSIP_PORT
    firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
    firewall-cmd --reload

    PIP_CMD="pip"
    cat ${DSIP_PROJECT_DIR}/gui/requirements.txt | xargs -n 1 $PYTHON_CMD -m ${PIP_CMD} install
    if [ $? -eq 1 ]; then
        echo "dSIPRouter install failed: Couldn't install required libraries"
        exit 1
    fi

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
    perl -p -e "s|^(ExecStart\=).+?([ \t].*)|\1$PYTHON_CMD\2|;" \
        -e "s|'DSIP_RUN_DIR\=.*'|'DSIP_RUN_DIR=$DSIP_RUN_DIR'|;" \
        -e "s|'DSIP_PROJECT_DIR\=.*'|'DSIP_PROJECT_DIR=$DSIP_PROJECT_DIR'|;" \
        -e "s|'DSIP_SYSTEM_CONFIG_DIR\=.*'|'DSIP_SYSTEM_CONFIG_DIR=$DSIP_SYSTEM_CONFIG_DIR'|;" \
        ${DSIP_PROJECT_DIR}/dsiprouter/dsiprouter.service > /etc/systemd/system/dsiprouter.service
    chmod 644 /etc/systemd/system/dsiprouter.service
    systemctl daemon-reload
    systemctl enable dsiprouter.service
}

function uninstall {
    # Uninstall dependencies for dSIPRouter
    PIP_CMD="pip"

    cat ${DSIP_PROJECT_DIR}/gui/requirements.txt | xargs -n 1 $PYTHON_CMD -m ${PIP_CMD} uninstall --yes
    if [ $? -eq 1 ]; then
        echo "dSIPRouter uninstall failed or the libraries are already uninstalled"
        exit 1
    else
        echo "DSIPRouter uninstall was successful"
        exit 0
    fi

    apt-get remove -y build-essential curl python3 python3-pip python-dev libmariadbclient-dev libmariadb-client-lgpl-dev libpq-dev firewalld

    # Remove Firewall for DSIP_PORT
    firewall-cmd --zone=public --remove-port=${DSIP_PORT}/tcp --permanent
    firewall-cmd --reload

    # Remove dSIPRouter Logging
    rm -f /etc/rsyslog.d/dsiprouter.conf

    # Remove logrotate settings
    rm -f /etc/logrotate.d/dsiprouter

    # Remove dSIProuter as a service
    systemctl disable dsiprouter.service
    rm -f /etc/systemd/system/dsiprouter.service
    systemctl daemon-reload
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
