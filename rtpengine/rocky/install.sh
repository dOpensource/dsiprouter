#!/usr/bin/env bash

# TODO: update based off latest changes in rtpengine/amzn/install.sh

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

# search for RPM using rocky linux vault repos
# not guaranteed to find an RPM, returns 1 if not found
# arguments:
#   $1 == rpm to search for
function vaultSearch() {
    local RPM_SEARCH RPM_PATH

    RPM_SEARCH="$1"

    RPM_PATH=$(
        curl -s https://dl.rockylinux.org/vault/rocky/fullfilelist |
        grep -m 1 "$RPM_SEARCH"'.rpm$'
    )
    (( $? == 0 )) || return 1

    VERSIONS_TO_SEARCH=($(
        curl -s https://dl.rockylinux.org/vault/rocky/ |
        perl -e "\$distro_majver='$DISTRO_MAJVER'; @matches=();" -0777 -e '
            $html = do { local $/; <STDIN> };
            @matches = ($html =~ m%(?<=\<a href=["'"'"'])(${distro_majver}\.[0-9a-zA-Z-]+)/(?=["'"'"']\>)%g);
            foreach my $match (@matches) { print "${match}\n"; }
        ' 2>/dev/null
    ))

    echo "https://dl.rockylinux.org/vault/rocky/${RPM_PATH}"
    return 0
}

# try installing in the following order:
# 1: headers from repos
# 2: headers from vault repos
function installKernelDevHeaders {
    local DISTRO_MAJVER="$DISTRO_MAJVER"
    local OS_ARCH="$OS_ARCH"
    local OS_KERNEL="$OS_KERNEL"
    local KERN_DEV KERN_HDR

    dnf install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL} || {
        KERN_DEV=$(vaultSearch "kernel-devel-${OS_KERNEL}") || return 1
        KERN_HDR=$(vaultSearch "kernel-headers-${OS_KERNEL}") || return 1

        dnf install -y "$KERN_DEV" &&
        dnf install -y "$KERN_HDR"
    }
}

# compile and install rtpengine from RPM's
function install {
    local RTPENGINE_RPM_VER BUILD_KERN_VERSIONS
    local REBOOT_REQUIRED=0
    local OS_ARCH=$(uname -m)
    local OS_KERNEL=$(uname -r)
    local RHEL_BASE_VER=$(rpm -E %{rhel})
    local DISTRO_VER=$(source /etc/os-release; echo "$VERSION_ID")
    local DISTRO_MAJVER=$(cut -d '.' -f 1 <<<"$DISTRO_VER")
    local NPROC=$(nproc)

    # Install required libraries
    dnf install -y distribution-gpg-keys &&
    dnf install -y epel-release &&
    dnf config-manager --enable -y devel &&
    if (( ${DISTRO_MAJVER} == 9 )); then
        dnf config-manager -y --set-enabled crb &&
        dnf install -y http://rpm.dsiprouter.org/dsiprouter-repo.noarch.rpm
    elif (( ${DISTRO_MAJVER} == 8 )); then
        dnf config-manager -y --set-enabled powertools &&
        rpmkeys --import /usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-free-el-${RHEL_BASE_VER} &&
        dnf --setopt=localpkg_gpgcheck=1 install -y https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-${RHEL_BASE_VER}.noarch.rpm
    fi &&
    dnf install -y jq curl gcc glib2 glib2-devel zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel \
        xmlrpc-c xmlrpc-c-devel libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel \
        iptables iptables-devel xmlrpc-c-devel gperf redhat-rpm-config rpm-build pkgconfig spandsp-devel pandoc \
        freetype-devel fontconfig-devel libxml2-devel nc dkms logrotate rsyslog perl perl-IPC-Cmd bc libwebsockets-devel \
        gperf gperftools gperftools-devel gperftools-libs gzip mariadb-devel perl-Config-Tiny spandsp librabbitmq librabbitmq-devel \
        ffmpeg ffmpeg-devel libjpeg-turbo-devel mosquitto-devel opus-devel iptables-legacy-devel gcc-toolset-14 &&
    installKernelDevHeaders

    if (( $? != 0 )); then
        printerr "Problem with installing the required libraries for RTPEngine"
        return 1
    fi

    BUILD_KERN_VERSIONS=$(joinwith '' ',' '' $(rpm -q kernel-headers | sed 's/kernel-headers-//g'))

    # rtpengine >= mr11.3.1.1 requires curl >= 7.43.0
    if versionCompare "$(tr -d '[a-zA-Z]' <<<"$RTPENGINE_VER")" gteq "11.3.1.1"; then
        if versionCompare "$(curl -V | head -1 | awk '{print $2}')" lt "7.43.0"; then
            printdbg 'curl version is not recent enough.. compiling curl 7.8.0'
            if [[ ! -d ${SRC_DIR}/curl ]]; then
                (
                    cd ${SRC_DIR} &&
                    curl -sL https://curl.haxx.se/download/curl-7.80.0.tar.gz 2>/dev/null |
                    tar -xzf - --transform 's%curl-7.80.0%curl%';
                )
            fi
            (
                cd ${SRC_DIR}/curl &&
                ./configure --prefix=/usr --libdir=/usr/lib64 --with-ssl &&
                make -j $NPROC &&
                make -j $NPROC install &&
                ldconfig
            )
            if (( $? != 0 )); then
                printerr 'Failed to compile curl'
                return 1
            fi
        fi
    fi

    # reuse repo if it exists and matches version we want to install
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
        patch -p1 -N <${DSIP_PROJECT_DIR}/rtpengine/el-${RTPENGINE_VER}.patch
    )
    if (( $? > 1 )); then
        printerr 'Failed patching RTPEngine files prior to build'
        return 1
    fi

    RTPENGINE_RPM_VER=$(grep -oP 'Version:.+?\K[\w\.\~\+]+' ${SRC_DIR}/rtpengine/el/rtpengine.spec)
    RPM_BUILD_ROOT="${HOME}/rpmbuild"
    rm -rf ${RPM_BUILD_ROOT} 2>/dev/null
    mkdir -p ${RPM_BUILD_ROOT}/SOURCES &&
    (
        source scl_source enable gcc-toolset-14 &&
        cd ${SRC_DIR} &&
        tar -czf ${RPM_BUILD_ROOT}/SOURCES/ngcp-rtpengine-${RTPENGINE_RPM_VER}.tar.gz \
            --transform="s%^rtpengine%ngcp-rtpengine-$RTPENGINE_RPM_VER%g" rtpengine/ &&
        echo "%__make $(which make) -j $NPROC" >~/.rpmmacros &&
        # fix for BUG: "exec_prefix: command not found"
        function exec_prefix() { echo -n '/usr'; } && export -f exec_prefix &&
        # build the RPM's
        rpmbuild -ba --define "kversion $BUILD_KERN_VERSIONS" ${SRC_DIR}/rtpengine/el/rtpengine.spec &&
        rm -f ~/.rpmmacros && unset -f exec_prefix &&
        systemctl mask ngcp-rtpengine-daemon.service

        # install the RPM's
        dnf install -y ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-${RTPENGINE_RPM_VER}*.rpm \
            ${RPM_BUILD_ROOT}/RPMS/noarch/ngcp-rtpengine-dkms-${RTPENGINE_RPM_VER}*.rpm \
            ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-kernel-${RTPENGINE_RPM_VER}*.rpm
    )

    if (( $? != 0 )); then
        printerr "Problems occurred compiling rtpengine"
        return 1
    fi

    # warn user if kernel module not loaded yet
    if (( $REBOOT_REQUIRED == 1 )); then
        printwarn "A reboot is required to load the RTPEngine kernel module"
    fi

    # ensure config dirs exist
    mkdir -p /run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /run/rtpengine

    # setup rtpengine defaults file
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/configs/default.conf /etc/default/rtpengine.conf

    # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl start firewalld

    # give rtpengine permissions in selinux
    semanage port -a -t rtp_media_port_t -p udp ${RTP_PORT_MIN}-${RTP_PORT_MAX} ||
    semanage port -m -t rtp_media_port_t -p udp ${RTP_PORT_MIN}-${RTP_PORT_MAX}

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
    echo "d /run/rtpengine/rtpengine.pid  0755 rtpengine rtpengine - -" > /etc/tmpfiles.d/rtpengine.conf

    # Reconfigure systemd service files
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

    yum remove -y ngcp-rtpengine\*

    rm -f /usr/bin/rtpengine
    rm -f /etc/rsyslog.d/rtpengine.conf
    rm -f /etc/logrotate.d/rtpengine

    # remove our selinux changes
    semanage port -D -t rtp_media_port_t -p udp

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
