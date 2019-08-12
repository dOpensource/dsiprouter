#!/usr/bin/env bash

#PYTHON_CMD=python3.5

(( $DEBUG == 1 )) && set -x

function install {
    
    # Get the default version of python enabled
    VER=`python -V 2>&1`
    VER=`echo $VER | cut -d " " -f 2`
    # Uninstall 3.6 and install a specific version of 3.6 if already installed
    if [[ "$VER" =~ 3.6 ]]; then
       yum remove -y rs-epel-release
       yum remove -y python36  python36-libs python36-devel python36-pip
       yum install -y https://centos7.iuscommunity.org/ius-release.rpm
       yum install -y python36u python36u-libs python36u-devel python36u-pip
    elif [[ "$VER" =~ 3 ]]; then
       yum remove -y rs-epel-release
       yum remove -y python3* python3*-libs python3*-devel python3*-pip
       yum install -y https://centos7.iuscommunity.org/ius-release.rpm
       yum install -y python36u python36u-libs python36u-devel python36u-pip
    elif [[ "$VER" =~ 2.7 ]]; then
        yum install -y https://centos7.iuscommunity.org/ius-release.rpm
        yum install -y python36u python36u-libs python36u-devel python36u-pip
    fi

   # Install dependencies for dSIPRouter
    yum install -y yum-utils
    yum --setopt=group_package_types=mandatory,default,optional groupinstall -y "Development Tools"
    yum install -y firewalld
    yum install -y python36 python36-libs python36-devel python36-pip MySQL-python
    yum install -y logrotate rsyslog perl

    # Reset python cmd in case it was just installed
    setPythonCmd


    # Fix for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1575845
    if (( $? != 0 )); then
        systemctl restart dbus
        systemctl restart firewalld
    fi

    # Setup Firewall for DSIP_PORT
    firewall-offline-cmd --zone=public --add-port=${DSIP_PORT}/tcp 
    
   # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl restart firewalld

    PIP_CMD="pip"
    cat ${DSIP_PROJECT_DIR}/gui/requirements.txt | xargs -n 1 $PYTHON_CMD -m ${PIP_CMD} install
    if [ $? -eq 1 ]; then
        echo "dSIPRouter install failed: Couldn't install required libraries"
        exit 1
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
        ${DSIP_PROJECT_DIR}/dsiprouter/dsiprouter.service > /etc/systemd/system/dsiprouter.service
    chmod 0644 /etc/systemd/system/dsiprouter.service
    systemctl daemon-reload
    systemctl enable dsiprouter
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
