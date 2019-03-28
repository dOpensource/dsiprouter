#!/usr/bin/env bash

# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

# compile and install rtpengine from RPM's
function install {
    local VERSION_NUM=""


    function installKernelDevHeaders {
        yum install -y "kernel-devel-uname-r == $(uname -r)"
        # if the headers for this kernel are not found try archives
        if [ $? -ne 0 ]; then
            yum install -y https://rpmfind.net/linux/centos/$(cat /etc/redhat-release | cut -d ' ' -f 4)/updates/$(uname -m)/Packages/kernel-devel-$(uname -r).rpm ||
            yum install -y https://rpmfind.net/linux/centos/$(cat /etc/redhat-release | cut -d ' ' -f 4)/os/$(uname -m)/Packages/kernel-devel-$(uname -r).rpm
        fi
    }

    # Install required libraries
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum-config-manager -y --add-repo https://negativo17.org/repos/epel-multimedia.repo
    sed -i 's|$releasever|7|g' /etc/yum.repos.d/epel-multimedia.repo
    rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
    rpm -Uh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm

    yum install -y gcc glib2 glib2-devel zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel \
        xmlrpc-c xmlrpc-c-devel libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel \
        iptables-devel kernel-devel kernel-headers xmlrpc-c-devel gperf redhat-lsb iptables-ipv6 redhat-rpm-config rpm-build pkgconfig \
        freetype-devel fontconfig-devel libxml2-devel nc dkms logrotate rsyslog

    yum --disablerepo='*' --enablerepo='epel-multimedia' install -y libbluray libbluray-devel
    yum install -y ffmpeg ffmpeg-devel

    installKernelDevHeaders

    if [ $? -ne 0 ]; then
        echo "Problem with installing the required libraries for RTPEngine"
        exit 1
    fi

    # alias and link rsyslog to syslog service as in debian
    # allowing rsyslog to be accessible via syslog namespace
    # the settings are already there just commented out by default
    sed -i -r 's|^[;#](.*)|\1|g' /usr/lib/systemd/system/rsyslog.service
    ln -s /usr/lib/systemd/system/rsyslog.service /etc/systemd/system/syslog.service
    systemctl daemon-reload

    # create rtpengine user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine

    # Make and Configure RTPEngine
    cd ${SRC_DIR}
    rm -rf rtpengine.bak 2>/dev/null
    mv -f rtpengine rtpengine.bak 2>/dev/null
    git clone https://github.com/sipwise/rtpengine.git -b ${RTPENGINE_VER}
    cd ./rtpengine

    VERSION_NUM=$(grep -oP 'Version:.+?\K[0-9\.]+' ./el/rtpengine.spec)
    mkdir -p ~/rpmbuild/SOURCES
    git archive --output ~/rpmbuild/SOURCES/ngcp-rtpengine-${VERSION_NUM}.tar.gz --prefix=ngcp-rtpengine-${VERSION_NUM}/ ${RTPENGINE_VER}
    rpmbuild -ba  ./el/rtpengine.spec
    rpm -i ~/rpmbuild/RPMS/$(uname -m)/ngcp-rtpengine-${VERSION_NUM}-*.rpm
    rpm -i ~/rpmbuild/RPMS/noarch/ngcp-rtpengine-dkms-${VERSION_NUM}-*.rpm
    rpm -i ~/rpmbuild/RPMS/$(uname -m)/ngcp-rtpengine-kernel-${VERSION_NUM}-*.rpm

    if [ $? -ne 0 ]; then
        echo "Problem installing RTPEngine RPM's"
        exit 1
    fi

    # ensure config dirs exist
    mkdir -p /var/run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /var/run/rtpengine


#    # Configure RTPEngine to support kernel packet forwarding
#    cd ${SRC_DIR}/rtpengine/kernel-module &&
#    make &&
#    cp -f xt_RTPENGINE.ko /lib/modules/$(uname -r)/updates/ &&
#    if [ $? -ne 0 ]; then
#        echo "Problem installing RTPEngine kernel-module"
#        exit 1
#    fi
#
#    # Remove RTPEngine kernel module if previously inserted
#    if lsmod | grep 'xt_RTPENGINE'; then
#        rmmod xt_RTPENGINE
#    fi
#    # Load new RTPEngine kernel module
#    depmod -a &&
#    modprobe xt_RTPENGINE


    if [ "$SERVERNAT" == "0" ]; then
        INTERFACE=$EXTERNAL_IP
    else
        INTERFACE=$INTERNAL_IP!$EXTERNAL_IP
    fi

    # rtpengine config file
    # set table = 0 for kernel packet forwarding
    (cat << EOF
[rtpengine]
table = -1
interface = ${INTERFACE}
listen-ng = 7722
port-min = ${RTP_PORT_MIN}
port-max = ${RTP_PORT_MAX}
log-level = 7
log-facility = local1
log-facility-cdr = local1
log-facility-rtcp = local1
EOF
    ) > ${SYSTEM_RTPENGINE_CONFIG_FILE}

    # setup rtpengine defaults file
    (cat << 'EOF'
RUN_RTPENGINE=yes
CONFIG_FILE=/etc/rtpengine/rtpengine.conf
# CONFIG_SECTION=rtpengine
PIDFILE=/var/run/rtpengine/rtpengine.pid
MANAGE_IPTABLES=yes
TABLE=0
SET_USER=rtpengine
SET_GROUP=rtpengine
LOG_STDERR=yes
EOF
    ) > /etc/default/rtpengine.conf

    # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl start firewalld

    # Fix for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1575845
    if (( $? != 0 )); then
        systemctl restart dbus
        systemctl restart firewalld
    fi

    # Setup Firewall rules for RTPEngine
    firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp --permanent
    firewall-cmd --reload

    # Setup RTPEngine Logging
    cp -f ${DSIP_PROJECT_DIR}/resources/syslog/rtpengine.conf /etc/rsyslog.d/rtpengine.conf
    touch /var/log/rtpengine.log
    systemctl restart rsyslog

    # Setup logrotate
    cp -f ${DSIP_PROJECT_DIR}/resources/logrotate/rtpengine /etc/logrotate.d/rtpengine

    # Setup Firewall rules for RTPEngine
    firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp --permanent
    firewall-cmd --reload

    # Setup tmp files
    echo "d /var/run/rtpengine.pid  0755 rtpengine rtpengine - -" > /etc/tmpfiles.d/rtpengine.conf
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/rtpengine.service /etc/systemd/system/rtpengine.service
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/rtpengine-start-pre /usr/sbin/
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/rtpengine-stop-post /usr/sbin/
    chmod +x /usr/sbin/rtpengine*

    # Reload systemd configs
    systemctl daemon-reload
    # Enable the RTPEngine to start during boot
    systemctl enable rtpengine
    # Start RTPEngine
    systemctl start rtpengine

    # Start manually if the service fails to start
    if [ $? -ne 0 ]; then
        /usr/sbin/rtpengine --config-file=${SYSTEM_RTPENGINE_CONFIG_FILE} --pidfile=/var/run/rtpengine/rtpengine.pid
    fi

    # File to signify that the install happened
    if [ $? -eq 0 ]; then
        touch ${DSIP_PROJECT_DIR}/.rtpengineinstalled
        echo "RTPEngine has been installed!"
    else
        echo "FAILED: RTPEngine could not be installed!"
    fi
}

# Remove RTPEngine
function uninstall {
    systemctl stop rtpengine
    rm -f /usr/sbin/rtpengine
    rm -f /etc/rsyslog.d/rtpengine.conf
    rm -f /etc/logrotate.d/rtpengine
    echo "Removed RTPEngine for $DISTRO"
}

case "$1" in
    uninstall|remove)
        uninstall && exit 0
        ;;
    install)
        install && exit 0
        ;;
    *)
        printerr "usage $0 [install | uninstall]" && exit 1
        ;;
esac
