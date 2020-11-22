#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install {
    # Install dependencies for dSIPRouter
    apt-get install -y build-essential curl python3 python3-pip python-dev python3-openssl libpq-dev firewalld nginx
    apt-get install -y --allow-unauthenticated libmariadbclient-dev 
    apt-get install -y logrotate rsyslog perl sngrep libev-dev uuid-runtime libpq-dev

    # create dsiprouter user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "dSIPRouter SIP Provider Platform" dsiprouter

    # get the user that nginx is running under. 
    nginx_username=$(ps -o uname= -p `pidof -s nginx`)
    # make sure the nginx user has access to dsiprouter directories
    usermod -a -G dsiprouter $nginx_username
    # make dsiprouter user has access to kamailio files
    usermod -a -G kamailio dsiprouter

    # setup /var/run/dsiprouter directory
    mkdir -p /var/run/dsiprouter
    chown dsiprouter:dsiprouter /var/run/dsiprouter

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
        printerr "dSIPRouter install failed: Couldn't install required libraries"
        exit 1
    fi

   # Setup uwsgi configuration
   cp -f ${DSIP_PROJECT_DIR}/resources/uwsgi/dsiprouter.ini /etc/dsiprouter/dsiprouter.ini
   
    # Configure Nginx
    cp -f ${DSIP_PROJECT_DIR}/resources/nginx/dsiprouter /etc/nginx/sites-available
    ln -s /etc/nginx/sites-available/dsiprouter /etc/nginx/sites-enabled
    systemctl restart nginx  
 
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
        printerr "dSIPRouter uninstall failed or the libraries are already uninstalled"
        exit 1
    else
        printdbg "DSIPRouter uninstall was successful"
        exit 0
    fi

    apt-get remove -y build-essential curl python3 python3-pip python-dev python3-openssl libpq-dev firewalld nginx
    apt-get remove -y --allow-unauthenticated libmariadbclient-dev 
    apt-get remove -y logrotate rsyslog perl sngrep libev-dev uuid-runtime
    #apt-get remove -y build-essential curl python3 python3-pip python-dev libmariadbclient-dev libmariadb-client-lgpl-dev python-mysqldb libpq-dev firewalld

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
        printerr "usage $0 [install | uninstall]"
        ;;
esac
