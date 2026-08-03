#!/usr/bin/env bash

# Debian 13 (trixie) RTPEngine installer.
# Installs RTPEngine from distribution packages (ngcp-rtpengine-*) instead of
# compiling from source. See ../install.sh for the source-build variant.

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

# never prompt during apt operations (dkms/kernel modules can be interactive)
export DEBIAN_FRONTEND=noninteractive

# RTPEngine binary packages provided by Debian (sipwise/ngcp packaging)
RTPENGINE_PKGS=(
    ngcp-rtpengine-daemon
    ngcp-rtpengine-iptables
    ngcp-rtpengine-kernel-dkms
    ngcp-rtpengine-utils
)

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
        curl -sLO --retry 3 "$KERN_HDR_URI"

        # install dependent common headers
        KERN_HDR_COMMON_URI=$(
            debSearch $(
                dpkg --info "$KERN_HDR_DEB" 2>/dev/null |
                grep 'Depends:' |
                cut -d ':' -f 2 |
                tr ',' '\n' |
                grep -oP 'linux-headers-.*-common'
            )
        ) &&
        KERN_HDR_COMMON_DEB=$(basename "$KERN_HDR_COMMON_URI") &&
        curl -sLO --retry 3 "$KERN_HDR_COMMON_URI" && {
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
    local OS_KERNEL=""

    # Install required packages and remove conflicting packages
    { dpkg -l ufw &>/dev/null && apt-get remove -y ufw || :; } &&
    apt-get update -y &&
    apt-get install -y curl gnupg git logrotate rsyslog firewalld dkms
    if (( $? != 0 )); then
        printerr "Problem with installing the required libraries for RTPEngine"
        return 1
    fi

    # try installing kernel dev headers so the DKMS module can build:
    # 1: headers from repos
    # 2: headers from snapshot.debian.org
    # NOTE: headers should be installed for all kernels on the system
    #       but we do not want to support ancient kernel dependencies
    (
        RET=0
        for OS_KERNEL in $(ls /lib/modules/ 2>/dev/null); do
            apt-get install -y linux-headers-${OS_KERNEL} ||
            aptInstallKernelHeadersFromURI $(debSearch linux-headers-${OS_KERNEL})
            RET=$((RET+$?))
        done
        exit $RET
    )
    if (( $? != 0 )); then
        printwarn "Could not install one or more kernel headers; RTPEngine may fall back to userspace forwarding"
    fi

    # prevent the packaged daemon from auto-starting on install; we manage our own unit
    systemctl mask ngcp-rtpengine-daemon.service &>/dev/null

    ## install RTPEngine from distribution packages (no source build)
    apt-get install -y "${RTPENGINE_PKGS[@]}"
    if (( $? != 0 )); then
        printerr "Problem installing RTPEngine packages"
        systemctl unmask ngcp-rtpengine-daemon.service &>/dev/null
        return 1
    fi

    systemctl unmask ngcp-rtpengine-daemon.service &>/dev/null
    systemctl disable ngcp-rtpengine-daemon.service &>/dev/null

    # make sure RTPEngine kernel module configured
    if [[ -z "$(find /lib/modules/ -name 'xt_RTPENGINE.ko*' 2>/dev/null)" ]]; then
        printwarn "RTPEngine kernel module not found; RTPEngine will use userspace forwarding"
    fi

    # ensure config dirs exist
    mkdir -p /run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /run/rtpengine

    # allow root to fix permissions before starting services (required to work with SELinux enabled)
    usermod -a -G rtpengine root
    # allow rtpengine to read configs from dsiprouter group
    usermod -a -G dsiprouter rtpengine

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

    # Reconfigure systemd service files (use the dsiprouter-managed unit, not the packaged one)
    rm -f /lib/systemd/system/rtpengine*.service
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/systemd/rtpengine-v3.service /lib/systemd/system/rtpengine.service
    chmod 644 /lib/systemd/system/rtpengine.service
    systemctl daemon-reload
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
