#!/usr/bin/env bash

# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

(( $DEBUG == 1 )) && set -x

function install {
    # Install required libraries
    apt-get install -y logrotate rsyslog
    apt-get install -y firewalld
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

    # debian jessie/stretch need a few newer packages
    CODENAME="$(lsb_release -c -s)"
    if [[ "$CODENAME" == "jessie" ]] || [[ "$CODENAME" == "stretch" ]] || [[ "$CODENAME" == "buster" ]]; then
        apt-get install -y -t buster libarchive13
        apt-get install -y -t stretch-backports debhelper init-system-helpers
    else
        apt-get install -y debhelper
    fi

    # create rtpengine user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine

    # build deb packages and install
    cd ${SRC_DIR}

    # TODO: this needs replaced with a better build process (maybe cpack?)
    CODEC_VER=1.0.4
    rm -rf bcg729-${CODEC_VER}.bak 2>/dev/null
    mv -f bcg729-${CODEC_VER} bcg729-${CODEC_VER}.bak 2>/dev/null
    curl -s https://codeload.github.com/BelledonneCommunications/bcg729/tar.gz/${CODEC_VER} > bcg729_${CODEC_VER}.orig.tar.gz &&
    tar -xf bcg729_${CODEC_VER}.orig.tar.gz &&
    cd bcg729-${CODEC_VER} &&
    git clone https://github.com/ossobv/bcg729-deb.git debian &&
    dpkg-buildpackage -us -uc -sa &&
    cd .. &&
    dpkg -i ./libbcg729-*.deb

    if [ $? -ne 0 ]; then
        printerr "Problem installing G729 Codec"
        exit 1
    fi

    rm -rf rtpengine.bak 2>/dev/null
    mv -f rtpengine rtpengine.bak 2>/dev/null
    git clone https://github.com/sipwise/rtpengine.git -b ${RTPENGINE_VER} &&
    cd rtpengine &&
    if [[ -e "$(pwd)/debian/flavors/no_ngcp" ]]; then
        ./debian/flavors/no_ngcp
    fi &&
    dpkg-buildpackage &&
    cd .. &&
    dpkg -i ./ngcp-rtpengine-daemon_*.deb ./ngcp-rtpengine-iptables_*.deb ./ngcp-rtpengine-kernel-source_*.deb \
        ngcp-rtpengine-kernel-dkms_*.deb 
    #./ngcp-rtpengine-recording-daemon_*.deb ./ngcp-rtpengine-utils_*.deb

    if [ $? -ne 0 ]; then
        printerr "Problem installing RTPEngine DEB's"
        exit 1
    fi

    # ensure config dirs exist
    mkdir -p /var/run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /var/run/rtpengine

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
    rm -f /etc/systemd/system/rtpengine.service /etc/init.d/ngcp-rtpengine-daemon
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
    if [ $? -eq 1 ]; then
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
        uninstall
        ;;
    install)
        install
        ;;
    *)
        printerr "usage $0 [install | uninstall]" && exit 1
        ;;
esac
