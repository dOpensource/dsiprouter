#!/usr/bin/env bash

# TODO: update based off latest changes in rtpengine/debian/install.sh

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install {
    # Install required libraries
    apt-get install -y logrotate rsyslog
    apt-get install -y firewalld
    apt-get install -y debhelper
    apt-get install -y iptables-dev
    apt-get install -y libcurl4-openssl-dev
    apt-get install -y libpcre3-dev libxmlrpc-core-c3-dev
    apt-get install -y markdown
    apt-get install -y libglib2.0-dev
    apt-get install -y libavcodec-dev
    apt-get install -y libevent-dev
    apt-get install -y libhiredis-dev
    apt-get install -y libjson-glib-dev libpcap0.8-dev libpcap-dev libssl-dev
    apt-get install -y libavfilter-dev
    apt-get install -y libavformat-dev
    apt-get install -y libmysqlclient-dev
    apt-get install -y libmariadbclient-dev
    apt-get install -y default-libmysqlclient-dev
    apt-get install -y module-assistant
    apt-get install -y dkms
    apt-get install -y unzip
    apt-get install -y libavresample-dev
    apt-get install -y linux-headers-$(uname -r)
    apt-get install -y gperf libbencode-perl libcrypt-openssl-rsa-perl libcrypt-rijndael-perl libdigest-crc-perl libdigest-hmac-perl \
        libio-multiplex-perl libio-socket-inet6-perl libnet-interface-perl libsocket6-perl libspandsp-dev libsystemd-dev libwebsockets-dev

    # try upgrading debhelper with backports if lower ver than 10
    CURRENT_VERSION=$(dpkg -s debhelper 2>/dev/null | grep Version | sed -rn 's|[^0-9\.]*([0-9]).*|\1|mp')
    if (( ${CURRENT_VERSION:-0} < 10 )); then
        CODENAME=$(cat /etc/os-release | grep '^VERSION_CODENAME=' | cut -d '=' -f 2)
        BACKPORT_REPO="${CODENAME}-backports"
        apt-get install -y -t ${BACKPORT_REPO} debhelper

        # if current backports fail (again aws repo's are not very reliable) try and older repo
        if [ $? -ne 0 ]; then
            printf '%s\n%s\n' \
                "deb http://archive.ubuntu.com/debian-archive/ubuntu/ ${CODENAME}-backports main" \
                "deb-src http://archive.debian.org/debian-archive/ubuntu/ ${CODENAME}-backports main" \
                > /etc/apt/sources.list.d/tmp-backports.list
            apt-get -o Acquire::Check-Valid-Until=false update -y

            apt-get -o Acquire::Check-Valid-Until=false install -y -t ${BACKPORT_REPO} debhelper
            rm -f /etc/apt/sources.list.d/tmp-backports.list
        fi

        # pin debhelper package to stay on backports repo
        printf '%s\n%s\n%s\n' \
            "Package: debhelper" \
            "Pin: release n=${BACKPORT_REPO}" \
            "Pin-Priority: 750" > /etc/apt/preferences.d/debhelper
    fi

    # create rtpengine user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine

    cd ${SRC_DIR}
    rm -rf rtpengine.bak 2>/dev/null
    mv -f rtpengine rtpengine.bak 2>/dev/null
    git clone https://github.com/sipwise/rtpengine.git -b ${RTPENGINE_VER}
    cd rtpengine
    ./debian/flavors/no_ngcp
    dpkg-buildpackage
    cd ..
    dpkg -i ngcp-rtpengine-daemon_*
    dpkg -i ngcp-rtpengine-iptables_*
    dpkg -i ngcp-rtpengine-kernel-source_*
    dpkg -i ngcp-rtpengine-kernel-dkms_*

    if [ $? -ne 0 ]; then
        printerr "Problem installing RTPEngine DEB's"
        exit 1
    fi

    # ensure config dirs exist
    mkdir -p /var/run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /var/run/rtpengine

    # Remove RTPEngine kernel module if previously inserted
    if lsmod | grep 'xt_RTPENGINE'; then
        rmmod xt_RTPENGINE
    fi
    # Load new RTPEngine kernel module
    depmod -a &&
    modprobe xt_RTPENGINE

    # set the forwarding table for the kernel module
    echo 'add 0' > /proc/rtpengine/control
    iptables -I INPUT -p udp -j RTPENGINE --id 0
    ip6tables -I INPUT -p udp -j RTPENGINE --id 0

    if (( ${SERVERNAT:-0} == 0 )); then
        INTERFACE="ipv4/${INTERNAL_IP}"
        if (( ${IPV6_ENABLED} == 1 )); then
            INTERFACE="${INTERFACE}; ipv6/${INTERNAL_IP6}"
        fi
    else
        INTERFACE="ipv4/${INTERNAL_IP}!${EXTERNAL_IP}"
        if (( ${IPV6_ENABLED} == 1 )); then
            INTERFACE="${INTERFACE}; ipv6/${INTERNAL_IP6}!${EXTERNAL_IP6}"
        fi
    fi

    # rtpengine config file
    # set table = 0 for kernel packet forwarding
    (cat << EOF
[rtpengine]
table = 0
interface = ${INTERFACE}
listen-ng = 127.0.0.1:7722
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

    # Setup Firewall rules for RTPEngine
    firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp --permanent
    firewall-cmd --reload

    # Setup RTPEngine Logging
    cp -f ${DSIP_PROJECT_DIR}/resources/syslog/rtpengine.conf /etc/rsyslog.d/rtpengine.conf
    touch /var/log/rtpengine.log
    systemctl restart rsyslog

    # Setup logrotate
    cp -f ${DSIP_PROJECT_DIR}/resources/logrotate/rtpengine /etc/logrotate.d/rtpengine

    # Setup tmp files
    echo "d /var/run/rtpengine.pid  0755 rtpengine rtpengine - -" > /etc/tmpfiles.d/rtpengine.conf
    systemctl stop ngcp-rtpengine-daemon

    # Reconfigure systemd service files
    rm -f /lib/systemd/system/rtpengine.service /etc/init.d/ngcp-rtpengine-daemon
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/systemd/rtpengine-v2.service /lib/systemd/system/rtpengine.service
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/rtpengine-{start-pre,stop-post} /usr/sbin/
    chmod +x /usr/sbin/rtpengine-{start-pre,stop-post} /usr/bin/rtpengine

    # Reload systemd configs
    systemctl daemon-reload
    # Enable the RTPEngine to start during boot
    systemctl enable rtpengine
    # Start RTPEngine
    systemctl start rtpengine

    # Start manually if the service fails to start
    if [ $? -eq 1 ]; then
        /usr/bin/rtpengine --config-file=${SYSTEM_RTPENGINE_CONFIG_FILE} --pidfile=/var/run/rtpengine/rtpengine.pid
    fi

    # File to signify that the install happened
    if [ $? -eq 0 ]; then
        touch ${DSIP_PROJECT_DIR}/.rtpengineinstalled
        printdbg "RTPEngine has been installed!"
    else
        printerr "FAILED: RTPEngine could not be installed!"
    fi
}

# Remove RTPEngine
function uninstall {
    systemctl stop rtpengine
    rm -f /usr/bin/rtpengine
    rm -f /etc/rsyslog.d/rtpengine.conf
    rm -f /etc/logrotate.d/rtpengine
    printdbg "Removed RTPEngine for $DISTRO"
}

case "$1" in
    uninstall|remove)
        uninstall
        ;;
    install)
        install
        ;;
    *)
        printerr "usage $0 [install | uninstall]" && exit 1
        ;;
esac
