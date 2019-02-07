#!/usr/bin/env bash

#PYTHON_CMD=python3.5
DSIP_KAMAILIO_CONF_DIR=$(pwd)

set -x

function install {
    # Install dependencies for dSIPRouter
    yum remove -y rs-epel-release*

    yum install -y yum-utils
    yum --setopt=group_package_types=mandatory,default,optional groupinstall -y "Development Tools"
    yum install -y https://centos7.iuscommunity.org/ius-release.rpm
    yum install -y firewalld
    yum install -y python36u python36u-libs python36u-devel python36u-pip
    yum install -y logrotate rsyslog

    # Reset python cmd in case it was just installed
    setPythonCmd


    # Setup Firewall for DSIP_PORT
    firewall-offline-cmd --zone=public --add-port=${DSIP_PORT}/tcp 
    
   # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl restart firewalld

    PIP_CMD="pip"
    $PYTHON_CMD -m ${PIP_CMD} install -r ./gui/requirements.txt
    if [ $? -eq 1 ]; then
        echo "dSIPRouter install failed: Couldn't install required libraries"
        exit 1
    fi

    # Setup dSIPRouter Logging
    cp -f ${DSIP_PROJECT_DIR}/resources/syslog/dsiprouter.conf /etc/rsyslog.d/dsiprouter.conf
    touch /var/log/dsiprouter.log
    systemctl restart rsyslog

    # Setup logrotate
    cp -f ${DSIP_PROJECT_DIR}/logrotate/dsiprouter /etc/logrotate.d/dsiprouter

    # Install dSIPRouter as a service
    cp -f ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/centos/dsiprouter.service ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/centos/dsiprouter.service.tmp
    sed -i s+PYTHON_CMD+$PYTHON_CMD+g ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/centos/dsiprouter.service.tmp
    sed -i s+DSIP_KAMAILIO_CONF_DIR+$DSIP_KAMAILIO_CONF_DIR+g ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/centos/dsiprouter.service.tmp

    cp -f ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/centos/dsiprouter.service.tmp /etc/systemd/system/dsiprouter.service
    chmod 644 /etc/systemd/system/dsiprouter.service
    systemctl daemon-reload
    systemctl enable dsiprouter.service
}


function uninstall {
    # Uninstall dependencies for dSIPRouter
    yum remove -y python36u\*
    yum remove -y ius-release
    yum groupremove -y "Development Tools"

    # Remove the repos
    rm -f /etc/yum.repos.d/ius*
    rm -f /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
    yum clean all

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
