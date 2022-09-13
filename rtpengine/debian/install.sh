#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

# TODO: add support for searching packages.debian.org
function debSearch() {
    local DEB_SEARCH="$1" SEARCH_RESULTS=""

    # search debian snapshots for package
    if [[ $(curl -sLI -w "%{http_code}" "https://snapshot.debian.org/binary/?bin=${DEB_SEARCH}" -o /dev/null) == "200" ]]; then
        SEARCH_RESULTS=$(curl -sL "https://snapshot.debian.org/binary/?bin=${DEB_SEARCH}" 2>/dev/null | grep -oP '<li><a href="../../\K.*(?=")' | head -1)
        SEARCH_RESULTS=$(curl -sL "https://snapshot.debian.org/${SEARCH_RESULTS}" 2>/dev/null | grep -oP "<a href=\"\K.*${DEB_SEARCH}.*\.deb(?=\")" | head -1)
        if [[ -n "$SEARCH_RESULTS" ]]; then
            echo "https://snapshot.debian.org${SEARCH_RESULTS}"
            return 0
        fi
    fi

    return 1
}

function aptInstallKernelHeadersFromURI() {
    local RET=0
    local KERN_HDR_URI="$1" KERN_HDR_DEB=$(basename "$1")
    local KERN_HDR_COMMON_URI="" KERN_HDR_COMMON_DEB=""

    (
        # download the .deb file
        cd /tmp/
        curl -sLO "$KERN_HDR_URI"

        # install dependent common headers
        KERN_HDR_COMMON_URI=$(debSearch $(dpkg --info "$KERN_HDR_DEB" 2>/dev/null | grep 'Depends:' | cut -d ':' -f 2 | tr ',' '\n' | grep -oP 'linux-headers-.*-common')) &&
            KERN_HDR_COMMON_DEB=$(basename "$KERN_HDR_COMMON_URI") &&
            curl -sLO "$KERN_HDR_COMMON_URI" && {
                apt-get install -y ./${KERN_HDR_COMMON_DEB}
                RET=$((RET + $?))
                apt-get install -y -f
                rm -f "$KERN_HDR_COMMON_DEB"
            }

        # install the kernel headers
        apt-get install -y ./${KERN_HDR_DEB}
        RET=$((RET + $?))
        rm -f "$KERN_HDR_DEB"
        exit $RET
    )

    return $?
}

function install {
    # Install required libraries
    # TODO: consolidate and version properly per supported distro versions
    apt-get install -y logrotate rsyslog
    apt-get install -y firewalld
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
    apt-get install -y libavcodec-extra
    # TODO: move mysql dev headers install to mysql dir for easier version management
    apt-get install -y default-libmysqlclient-dev ||
        apt-get install -y libmysqlclient-dev
    apt-get install -y libmariadbclient-dev
    apt-get install -y module-assistant
    apt-get install -y dkms
    apt-get install -y cmake
    apt-get install -y unzip
    apt-get install -y libavresample-dev

    apt-get install -y gperf libbencode-perl libcrypt-openssl-rsa-perl libcrypt-rijndael-perl libdigest-crc-perl libdigest-hmac-perl \
        libio-multiplex-perl libio-socket-inet6-perl libnet-interface-perl libsocket6-perl libspandsp-dev libsystemd-dev libwebsockets-dev

    # older versions need a few newer packages
    case "${DISTRO_VER}" in
        9)
            apt-get install -y -t buster libarchive13
            apt-get install -y -t stretch-backports debhelper init-system-helpers
            apt-get install -y -t bullseye libbcg729-0 libbcg729-dev
            apt-get install -y iptables-dev libiptc-dev
            ;;
        10)
            apt-get install -y -t bullseye libbcg729-0 libbcg729-dev
            apt-get install -y debhelper iptables-dev libiptc-dev
            ;;
        *)
            apt-get install -y debhelper libbcg729-0 libbcg729-dev libxtables-dev libiptc-dev
            ;;
    esac

    # try installing kernel dev headers in the following order:
    # 1: headers from repos
    # 2: headers from snapshot.debian.org
    # note: headers must be installed for all kernels on the system
    for OS_KERNEL in $(ls /lib/modules/ 2>/dev/null); do
        apt-get install -y linux-headers-${OS_KERNEL} ||
            aptInstallKernelHeadersFromURI $(debSearch linux-headers-${OS_KERNEL})
#       (
#           KERNEL_META_PKG=$(echo ${OS_KERNEL} | perl -pe 's%[0-9-.]+(.*)%\1%')
#            apt-get install -y linux-image-${KERNEL_META_PKG} linux-headers-${KERNEL_META_PKG}
#            printwarn 'Required Kernel Update Installed'
#            printwarn 'RTPEngine will not forward packets in-kernel until a reboot occurs'
#        )
    done

    if (( $? != 0 )); then
        printerr "Problem with installing the required libraries for RTPEngine"
        exit 1
    fi

    # create rtpengine user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel rtpengine &>/dev/null; groupdel rtpengine &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine

    ## compile and install RTPEngine as an RPM package
    ## reuse repo if it exists and matches version we want to install
    if [[ -d ${SRC_DIR}/rtpengine ]]; then
        if [[ "x$(cd ${SRC_DIR}/rtpengine 2>/dev/null && git branch --show-current 2>/dev/null)" != "x${RTPENGINE_VER}" ]]; then
            rm -rf ${SRC_DIR}/rtpengine
            git clone --depth 1 -b ${RTPENGINE_VER} https://github.com/sipwise/rtpengine.git ${SRC_DIR}/rtpengine
        fi
    else
        git clone --depth 1 -b ${RTPENGINE_VER} https://github.com/sipwise/rtpengine.git ${SRC_DIR}/rtpengine
    fi
    (
        cd ${SRC_DIR}/rtpengine &&
        if [[ -e "${SRC_DIR}/rtpengine/debian/flavors/no_ngcp" ]]; then
            ${SRC_DIR}/rtpengine/debian/flavors/no_ngcp
        fi &&
        dpkg-buildpackage -us -uc -sa &&
        cd .. &&
        apt-get install -y ./ngcp-rtpengine-daemon_*${RTPENGINE_VER}*.deb ./ngcp-rtpengine-iptables_*${RTPENGINE_VER}*.deb \
            ./ngcp-rtpengine-kernel-dkms_*${RTPENGINE_VER}*.deb ./ngcp-rtpengine-utils_*${RTPENGINE_VER}*.deb
#            ./ngcp-rtpengine-recording-daemon_*${RTPENGINE_VER}*.deb
        exit $?
    )

    if (( $? != 0 )); then
        printerr "Problem installing RTPEngine DEB's"
        exit 1
    fi

    # make sure RTPEngine kernel module configured
    if [[ -z "$(find /lib/modules/${OS_KERNEL}/ -name 'xt_RTPENGINE.ko' 2>/dev/null)" ]]; then
        printerr "Problem installing RTPEngine kernel module"
        exit 1
    fi

    # stop the demaon so we can configure it properly
    systemctl stop ngcp-rtpengine-daemon

    # ensure config dirs exist
    mkdir -p /var/run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /var/run/rtpengine

    # rtpengine config file
    # ref example config: https://github.com/sipwise/rtpengine/blob/master/etc/rtpengine.sample.conf
    # TODO: move from 2 seperate config files to generating entire config
    #       1st we should change to generating config using rtpengine-start-pre
    #       eventually we should create a config parser similar to how kamailio config is parsed
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/configs/rtpengine.conf ${SYSTEM_RTPENGINE_CONFIG_FILE}

    # setup rtpengine defaults file
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/configs/default.conf /etc/default/rtpengine.conf

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

    # Reconfigure systemd service files
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/systemd/rtpengine-v2.service /etc/systemd/system/rtpengine.service
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/rtpengine-start-pre /usr/sbin/
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/rtpengine-stop-post /usr/sbin/
    chmod +x /usr/sbin/rtpengine*

    # Reload systemd configs
    systemctl daemon-reload
    # Enable the RTPEngine to start during boot
    systemctl enable rtpengine

    # preliminary check that rtpengine actually installed
    if cmdExists rtpengine; then
        exit 0
    else
        exit 1
    fi
}

# Remove RTPEngine
function uninstall {
    systemctl disable rtpengine
    systemctl stop rtpengine
    rm -f /etc/systemd/system/rtpengine.service
    systemctl daemon-reload

    apt-get remove -y ngcp-rtpengine\*

    rm -f /usr/sbin/rtpengine* /etc/rsyslog.d/rtpengine.conf /etc/logrotate.d/rtpengine

    # check that rtpengine actually uninstalled
    if ! cmdExists rtpengine; then
        exit 0
    else
        exit 1
    fi
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
