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
    apt-get install -y libmariadbd-dev
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

   ## compile and install RTPEngine as a DEB package
    ## reuse repo if it exists and matches version we want to install
    if [[ -d ${SRC_DIR}/rtpengine ]]; then
        if [[ "$(getGitTagFromShallowRepo ${SRC_DIR}/rtpengine)" != "${RTPENGINE_VER}" ]]; then
            rm -rf ${SRC_DIR}/rtpengine
            git clone --depth 1 -c advice.detachedHead=false -b ${RTPENGINE_VER} https://github.com/sipwise/rtpengine.git ${SRC_DIR}/rtpengine
        fi
    else
        git clone --depth 1 -c advice.detachedHead=false -b ${RTPENGINE_VER} https://github.com/sipwise/rtpengine.git ${SRC_DIR}/rtpengine
    fi

    # apply our patches
    (
        cd ${SRC_DIR}/rtpengine &&
        patch -p1 -N <${DSIP_PROJECT_DIR}/rtpengine/deb-${RTPENGINE_VER}.patch
    )
    if (( $? > 1 )); then
        printerr 'Failed patching RTPEngine files prior to build'
        return 1
    fi

    # build and install using dpkg
    (
        cd ${SRC_DIR}/rtpengine

        # install all missing dependencies from the control file
        MISSING_PKGS=$(getDebDependencies)
        [[ -n "$MISSING_PKGS" ]] && apt-get install -y $MISSING_PKGS

        dpkg-buildpackage -us -uc -sa --jobs=$NPROC || exit 1

        systemctl mask ngcp-rtpengine-daemon.service

        apt-get install -y ../ngcp-rtpengine-daemon_*${RTPENGINE_VER}*.deb ../ngcp-rtpengine-iptables_*${RTPENGINE_VER}*.deb \
            ../ngcp-rtpengine-kernel-dkms_*${RTPENGINE_VER}*.deb ../ngcp-rtpengine-utils_*${RTPENGINE_VER}*.deb
        exit $?
    )

    if (( $? != 0 )); then
        printerr "Problem installing RTPEngine DEB's"
        return 1
    fi

    # make sure RTPEngine kernel module configured
    # skip this check for older versions as we allow userspace forwarding
    if (( ${DISTRO_VER} > 10 )); then
        if [[ -z "$(find /lib/modules/${OS_KERNEL}/ -name 'xt_RTPENGINE.ko' 2>/dev/null)" ]]; then
            printerr "Problem installing RTPEngine kernel module"
            return 1
        fi
    fi

    # ensure config dirs exist
    mkdir -p /run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /run/rtpengine

    # allow root to fix permissions before starting services (required to work with SELinux enabled)
    usermod -a -G rtpengine root

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
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/systemd/rtpengine-v2.service /lib/systemd/system/rtpengine.service
    chmod 644 /lib/systemd/system/rtpengine.service
    systemctl daemon-reload
    systemctl enable rtpengine

    # Reload systemd configs
    systemctl daemon-reload
    # Enable the RTPEngine to start during boot
    systemctl enable rtpengine

    # preliminary check that rtpengine actually installed
    if cmdExists rtpengine; then
        return 0
    else
        return 1
    fi
}

# Remove RTPEngine
function uninstall {
    systemctl stop rtpengine
    systemctl disable rtpengine
    rm -f /{etc,lib}/systemd/system/rtpengine.service 2>/dev/null
    systemctl daemon-reload

    apt-get remove -y ngcp-rtpengine\*

 rm -f /usr/sbin/rtpengine* /usr/bin/rtpengine /etc/rsyslog.d/rtpengine.conf /etc/logrotate.d/rtpengine

    # remove our firewall changes
    firewall-cmd --zone=public --remove-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp --permanent
    firewall-cmd --reload

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
