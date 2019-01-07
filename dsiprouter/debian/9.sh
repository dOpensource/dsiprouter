#!/usr/bin/env bash

#PYTHON_CMD=python3.5
DSIP_KAMAILIO_CONF_DIR=(`pwd`)
set -x 

function install {
    # Install dependencies for dSIPRouter
    apt-get -y install build-essential curl python3 python3-pip python-dev libmariadbclient-dev libmariadb-client-lgpl-dev libpq-dev firewalld sngrep

    # Reset python cmd in case it was just installed
    setPythonCmd

    # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl start firewalld

    # Setup Firewall for DSIP_PORT
    firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
    firewall-cmd --reload

    PIP_CMD="pip"
    $PYTHON_CMD -m ${PIP_CMD} install -r ./gui/requirements.txt
    if [ $? -eq 1 ]; then
        echo "dSIPRouter install failed: Couldn't install required libraries"
        exit 1
    fi

    # Required changes if on an AMI instance
    if (( $AWS_ENABLED == 1 )); then
        # Change default password for debian-sys-maint
        # if user is not used we don't worry if this fails
        # we must however change the password in /etc/mysql/debian.cnf
        # to comply with AWS AMI image standards
        INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
        mysql -e "SET PASSWORD FOR 'debian-sys-maint'@'localhost' = PASSWORD('$(INSTANCE_ID)')" 2>/dev/null
        sed -i "s|password =.*|password = ${INSTANCE_ID}|g" /etc/mysql/debian.cnf
    fi

    #Install dSIPRouter as a service
    cp -f ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service.tmp
    sed -i s+PYTHON_CMD+$PYTHON_CMD+g ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service.tmp
    sed -i s+DSIP_KAMAILIO_CONF_DIR+$DSIP_KAMAILIO_CONF_DIR+g ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service.tmp

    cp -f ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service.tmp /lib/systemd/system/dsiprouter.service
    chmod 644 /lib/systemd/system/dsiprouter.service
    systemctl daemon-reload
    systemctl enable dsiprouter.service
}

function uninstall {
    # Uninstall dependencies for dSIPRouter
    apt-get remove -y build-essential curl python3 python3-pip python-dev libmariadbclient-dev libmariadb-client-lgpl-dev libpq-dev firewalld

    #Remove Firewall for DSIP_PORT
    firewall-cmd --zone=public --remove-port=${DSIP_PORT}/tcp --permanent
    firewall-cmd --reload

    #Remove dSIProuter as a service
    systemctl disable dsiprouter.service
    rm -f /lib/systemd/system/dsiprouter.service
    systemctl daemon-reload

    PIP_CMD="pip"

    /usr/bin/yes | ${PYTHON_CMD} -m ${PIP_CMD} uninstall -r ./gui/requirements.txt
    if [ $? -eq 1 ]; then
        echo "dSIPRouter uninstall failed or the libraries are already uninstalled"
        exit 1
    else
        echo "DSIPRouter uninstall was successful"
        exit 0
    fi
}

case "$1" in
    uninstall|remove)
        #Remove
        PYTHON_CMD=$3
        DSIP_PORT=$2
        $1
        ;;
    install)
        #Install
        PYTHON_CMD=$3
        DSIP_PORT=$2
        $1
        ;;
    *)
        echo "usage $0 [install <dsip_port> <python_cmd> | uninstall <dsip_port> <python_cmd>]"   
        ;;
esac
