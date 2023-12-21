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
        yum install -y python36u python36u-libs python36u-devel python36u-pip
    elif [[ "$VER" =~ 3 ]]; then
        yum remove -y rs-epel-release
        yum remove -y python3* python3*-libs python3*-devel python3*-pip
        yum install -y https://centos7.iuscommunity.org/ius-release.rpm
        yum install -y python36u python36u-libs python36u-devel python36u-pip
    else
        yum install -y https://centos7.iuscommunity.org/ius-release.rpm
        yum install -y python36u python36u-libs python36u-devel python36u-pip
    fi

   # Install dependencies for dSIPRouter
    yum install -y yum-utils
    yum --setopt=group_package_types=mandatory,default,optional groupinstall -y "Development Tools"
    yum install -y firewalld nginx
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

    # give nginx permissions in SELINUX
    semanage port -a -t http_port_t -p tcp ${DSIP_PORT} ||
    semanage port -m -t http_port_t -p tcp ${DSIP_PORT}
    # NOTE: /var/run is required here due to the aliasing in the fcontexts
    #semanage fcontext -a -t httpd_var_run_t '/var/run/dsiprouter/dsiprouter\.sock'
    # TODO: this is a workaround, this the "wrong" way to do it
    # we need to figure out why the fcontexts are not applying by default to new files
    # and possibly (preferably) create our own type with those specific permissions
    # for example a new type dsiprouter_run_t labeled on '/var/run/dsiprouter/.+'
    (
        if semodule -l | grep -q 'dsiprouter'; then
            semodule -r dsiprouter
        fi
        cd /tmp &&
        checkmodule -M -m -o dsiprouter.mod ${DSIP_PROJECT_DIR}/nginx/selinux/centos.te &&
        semodule_package -o dsiprouter.pp -m dsiprouter.mod &&
        semodule -i dsiprouter.pp
    )
    if (( $? != 0 )); then
        printerr 'failed updating selinux permissions'
        return 1
    fi

    # reset python cmd in case it was just installed
    setPythonCmd

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
    firewall-offline-cmd --zone=public --add-port=${DSIP_PORT}/tcp

    cat ${DSIP_PROJECT_DIR}/gui/requirements.txt | xargs -n 1 ${PYTHON_CMD} -m pip install
    if [ $? -eq 1 ]; then
        printerr "dSIPRouter install failed: Couldn't install required libraries"
        exit 1
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

    cp -f ${DSIP_PROJECT_DIR}/nginx/systemd/nginx-stop.sh /usr/sbin/nginx-stop
    cp -f ${DSIP_PROJECT_DIR}/nginx/systemd/nginx-v2.service /lib/systemd/system/nginx.service
    cp -f ${DSIP_PROJECT_DIR}/nginx/systemd/nginx-watcher-v2.service /lib/systemd/system/nginx-watcher.service
    perl -p \
        -e "s%PathChanged\=.*%PathChanged=${DSIP_CERTS_DIR}/%;" \
        ${DSIP_PROJECT_DIR}/nginx/systemd/nginx-watcher.path >/lib/systemd/system/nginx-watcher.path
    chmod 644 /lib/systemd/system/nginx.service
    chmod 644 /lib/systemd/system/nginx-watcher.service
    chmod 644 /lib/systemd/system/nginx-watcher.path
    systemctl daemon-reload
    systemctl enable nginx

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
