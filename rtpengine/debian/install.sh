#!/usr/bin/env bash

function install {
    local RTPENGINE_SRC_DIR="${SRC_DIR}/rtpengine"
    local RTP_UPDATE_OPTS=""

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

    # try upgrading debhelper with backports if lower ver than 10
    CURRENT_VERSION=$(dpkg -s debhelper 2>/dev/null | grep Version | sed -rn 's|[^0-9\.]*([0-9]).*|\1|mp')
    if (( ${CURRENT_VERSION:-0} < 10 )); then
        CODENAME=$(cat /etc/os-release | grep '^VERSION=' | cut -d '(' -f 2 | cut -d ')' -f 1)
        BACKPORT_REPO="${CODENAME}-backports"
        apt-get install -y -t ${BACKPORT_REPO} debhelper
        printf '%s\n%s\n%s\n' \
            "Package: debhelper" \
            "Pin: release n=${BACKPORT_REPO}" \
            "Pin-Priority: 750" > /etc/apt/preferences.d/debhelper
    fi

    cd ${SRC_DIR}
    rm -rf rtpengine.bak 2>/dev/null
    mv -f rtpengine rtpengine.bak 2>/dev/null
    git clone https://github.com/sipwise/rtpengine.git --branch ${RTPENGINE_VER} --depth 1
    cd rtpengine
    ./debian/flavors/no_ngcp
    dpkg-buildpackage
    cd ..
    dpkg -i ngcp-rtpengine-daemon_*

    # Stop the service after it's installed.  We need to configure it fist
    systemctl stop ngcp-rtpengine-daemon

    if [ "$SERVERNAT" == "0" ]; then
        INTERFACE=$EXTERNAL_IP
    else
        INTERFACE=$INTERNAL_IP!$EXTERNAL_IP
    fi

    # create rtpengine user and group
    mkdir -p /var/run/ngcp-rtpengine-daemon
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine
    chown -R rtpengine:rtpengine /var/run/ngcp-rtpengine-daemon

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
PIDFILE=/var/run/ngcp-rtpengine-daemon/ngcp-rtpengine-daemon.pid
MANAGE_IPTABLES=yes
TABLE=0
SET_USER=rtpengine
SET_GROUP=rtpengine
EOF
    ) > /etc/default/ngcp-rtpengine-daemon

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
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/debian/ngcp-rtpengine-daemon.init /etc/init.d/ngcp-rtpengine-daemon

    # update kam configs on reboot
    if (( ${SERVERNAT} == 1 )); then
        RTP_UPDATE_OPTS="-servernat"
    fi
    cronAppend "@reboot $(type -P bash) ${DSIP_PROJECT_DIR}/dsiprouter.sh updatertpconfig ${RTP_UPDATE_OPTS}"

    # Enable the RTPEngine to start during boot
    systemctl enable ngcp-rtpengine-daemon
    # Start RTPEngine
    systemctl start ngcp-rtpengine-daemon

    # Start manually if the service fails to start
    if [ $? -eq 1 ]; then
        /usr/sbin/rtpengine --config-file=${SYSTEM_RTPENGINE_CONFIG_FILE} --pidfile=/var/run/ngcp-rtpengine-daemon.pid
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
    echo "Removing RTPEngine for $DISTRO"
    systemctl stop rtpengine
    rm -f /usr/sbin/rtpengine
    rm -f /etc/rsyslog.d/rtpengine.conf
    rm -f /etc/logrotate.d/rtpengine
    echo "Removed RTPEngine for $DISTRO"
}

case "$1" in
    uninstall|remove)
        uninstall
        ;;
    install)
        install
        ;;
    *)
        echo "usage $0 [install | uninstall]" && exit 1
        ;;
esac
