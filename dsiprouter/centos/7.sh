#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install {

    # Get the default version of python enabled
    VER=`python -V 2>&1`
    VER=`echo $VER | cut -d " " -f 2`
    # Uninstall 3.6 and install a specific version of 3.6 if already installed
    if [[ "$VER" =~ 3.6 ]]; then
        yum remove -y rs-epel-release
        yum remove -y python36  python36-libs python36-devel python36-pip
        yum install -y https://centos7.iuscommunity.org/ius-release.rpm
        yum install -y python36u python36u-libs python36u-devel python36u-pip python36u-virtualenv
    elif [[ "$VER" =~ 3 ]]; then
        yum remove -y rs-epel-release
        yum remove -y python3* python3*-libs python3*-devel python3*-pip
        yum install -y https://centos7.iuscommunity.org/ius-release.rpm
        yum install -y python36u python36u-libs python36u-devel python36u-pip python36u-virtualenv
    else
        yum install -y https://centos7.iuscommunity.org/ius-release.rpm
        yum install -y python36u python36u-libs python36u-devel python36u-pip python36u-virtualenv
    fi

   # Install dependencies for dSIPRouter
    yum install -y yum-utils
    yum --setopt=group_package_types=mandatory,default,optional groupinstall -y "Development Tools"
    yum install -y firewalld nginx sudo
    yum install -y python36 python36-libs python36-devel python36-pip MySQL-python
    yum install -y logrotate rsyslog perl libev-devel util-linux postgresql-devel mariadb-devel

    # create dsiprouter and nginx user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "dSIPRouter SIP Provider Platform" dsiprouter
    useradd --system --user-group --shell /bin/false --comment "nginx HTTP Service Provider" nginx

    # make sure the nginx user has access to dsiprouter directories
    usermod -a -G dsiprouter nginx
    # make dsiprouter user has access to kamailio files
    usermod -a -G kamailio dsiprouter

    # setup runtime directorys for dsiprouter and nginx
    mkdir -p ${DSIP_RUN_DIR} /run/nginx
    chown -R dsiprouter:dsiprouter ${DSIP_RUN_DIR}
    chown -R nginx:nginx /run/nginx

    # give dsiprouter permissions in SELINUX
    semanage port -a -t http_port_t -p tcp ${DSIP_PORT} ||
        semanage port -m -t http_port_t -p tcp ${DSIP_PORT}

   # Enable and start firewalld
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

    # Configure nginx
    # determine available TLS protocols (try using highest available)
    OPENSSL_VER=$(openssl version 2>/dev/null | awk '{print $2}' | perl -pe 's%([0-9])\.([0-9]).([0-9]).*%\1\2\3%')
    if (( ${OPENSSL_VER} < 101 )); then
        TLS_PROTOCOLS="TLSv1"
    elif (( ${OPENSSL_VER} < 111 )); then
        TLS_PROTOCOLS="TLSv1.1 TLSv1.2"
    else
        TLS_PROTOCOLS="TLSv1.2 TLSv1.3"
    fi
    mkdir -p /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/nginx.conf.d/
    # remove the defaults
    rm -f /etc/nginx/sites-enabled/* /etc/nginx/sites-available/* /etc/nginx/nginx.conf.d/*
    # setup our own nginx configs
    perl -e "\$tls_protocols='${TLS_PROTOCOLS}';" \
        -pe 's%TLS_PROTOCOLS%${tls_protocols}%g;' \
        ${DSIP_PROJECT_DIR}/nginx/configs/nginx.conf >/etc/nginx/nginx.conf
    perl -e "\$dsip_port='${DSIP_PORT}'; \$dsip_unix_sock='${DSIP_UNIX_SOCK}'; \$dsip_ssl_cert='${DSIP_SSL_CERT}'; \$dsip_ssl_key='${DSIP_SSL_KEY}';" \
        -pe 's%DSIP_UNIX_SOCK%${dsip_unix_sock}%g; s%DSIP_PORT%${dsip_port}%g; s%DSIP_SSL_CERT%${dsip_ssl_cert}%g; s%DSIP_SSL_KEY%${dsip_ssl_key}%g;' \
        ${DSIP_PROJECT_DIR}/nginx/configs/dsiprouter.conf >/etc/nginx/sites-available/dsiprouter.conf
    ln -sf /etc/nginx/sites-available/dsiprouter.conf /etc/nginx/sites-enabled/dsiprouter.conf

    systemctl enable nginx
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
        ${DSIP_PROJECT_DIR}/dsiprouter/systemd/dsiprouter-v2.service > /lib/systemd/system/dsiprouter.service
    chmod 644 /lib/systemd/system/dsiprouter.service
    systemctl daemon-reload
    systemctl enable dsiprouter

    # add hook to bash_completion in the standard debian location
    echo '. /usr/share/bash-completion/bash_completion' > /etc/bash_completion

    return 0
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

    yum remove -y python36u\*
    yum remove -y ius-release
    yum remove -y nginx
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
