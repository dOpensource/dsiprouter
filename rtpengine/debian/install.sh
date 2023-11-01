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

# prints $1 if not virtual or the package that provides $1 if virtual
function resolveAptVirtualPkg() {
    apt-cache search "^$1\$" | awk '{print $1}'
}

# when run from root of a debian repo finds the package dependencies
function getDebDependencies() {
    local TMP DISCRETE_PKGS CONDITIONAL_PKGS RESULT_PKGS=()

    TMP=$(
        dpkg-checkbuilddeps 2>&1 |
        awk -F 'Unmet build dependencies: ' '{print $2}' |
        perl -pe 's% \(.*?\)%%g'
    )
    DISCRETE_PKGS=$(perl -pe 's%[^ ]+ \| [^ ]+%%g' <<<"$TMP")
    CONDITIONAL_PKGS=$(
        grep -oP '[^ ]+ \| [^ ]+' <<<"$TMP" | (
            while IFS= read -r LINE; do
                PKG=$(resolveAptVirtualPkg $(awk -F ' | ' '{print $1}' <<<"$LINE"))
                if [[ -n "$(apt-cache search $PKG 2>/dev/null)" ]]; then
                    echo "$PKG"
                else
                    PKG=$(resolveAptVirtualPkg $(awk -F ' | ' '{print $2}' <<<"$LINE"))
                    [[ -n "$(apt-cache search $PKG 2>/dev/null)" ]] && echo "$PKG"
                fi
            done
        )
    )

    for PKG in $DISCRETE_PKGS; do
        RESULT_PKGS+=( $(resolveAptVirtualPkg "$PKG") )
    done
    for PKG in $CONDITIONAL_PKGS; do
        RESULT_PKGS+=( "$PKG" )
    done

    echo ${RESULT_PKGS[@]}
}

function install {
    local MISSING_PKGS
    local NPROC=$(nproc)

    # Install required packages
    case "${DISTRO_VER}" in
        10)
            apt-get install -y git logrotate rsyslog dpkg-dev
            apt-get install -y -t bullseye libbcg729-0 libbcg729-dev debhelper dkms libglib2.0-dev libncurses-dev \
                zlib1g-dev default-libmysqlclient-dev libmariadb-dev firewalld python3 python3-dev python3-websockets \
                perl libbencode-perl libcrypt-openssl-rsa-perl libcrypt-rijndael-perl libdigest-crc-perl libnet-interface-perl \
                libsocket6-perl libdigest-hmac-perl libio-multiplex-perl libio-socket-inet6-perl libjson-perl libtest2-suite-perl
            ;;
        *)
            apt-get install -y git logrotate rsyslog firewalld dpkg-dev
            ;;
    esac

    if (( $? != 0 )); then
        printerr "Problem with installing the required libraries for RTPEngine"
        exit 1
    fi

    # try installing kernel dev headers in the following order:
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

    # debian ver <= 10 has package conflicts with some older kernels so allow userspace forwarding
    if (( $? != 0 && ${DISTRO_VER} > 10 )); then
        printerr "Problems occurred installing one or more kernel headers"
        exit 1
    fi

    # create rtpengine user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel rtpengine &>/dev/null; groupdel rtpengine &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine

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
        exit 1
    fi

    # make sure RTPEngine kernel module configured
    # skip this check for older versions as we allow userspace forwarding
    if (( ${DISTRO_VER} > 10 )); then
        if [[ -z "$(find /lib/modules/${OS_KERNEL}/ -name 'xt_RTPENGINE.ko' 2>/dev/null)" ]]; then
            printerr "Problem installing RTPEngine kernel module"
            exit 1
        fi
    fi

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
    rm -f /lib/systemd/system/rtpengine.service 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/systemd/rtpengine-v2.service /lib/systemd/system/rtpengine.service
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/rtpengine-{start-pre,stop-post} /usr/sbin/
    chmod +x /usr/sbin/rtpengine-{start-pre,stop-post} /usr/bin/rtpengine

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
    rm -f /lib/systemd/system/rtpengine.service
    systemctl daemon-reload

    apt-get remove -y ngcp-rtpengine\*

    rm -f /usr/sbin/rtpengine* /usr/bin/rtpengine /etc/rsyslog.d/rtpengine.conf /etc/logrotate.d/rtpengine

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
