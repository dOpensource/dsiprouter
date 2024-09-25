#!/usr/bin/env bash

# TODO: update based off latest changes in rtpengine/amzn/install.sh

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

# search for RPM using external APIs mirrors and archives
# not guaranteed to find an RPM, outputs empty string if search fails
# arguments:
#   $1 == rpm to search for
# options:
#   -a <arch filter>
#   --arch=<arch filter>
#   -d <distro filter>
#   --distro=<distro filter>
#   -f <grep filter>
#   --filter=<grep filter>
function rpmSearch() {
    local RPM_SEARCH="" DISTRO_FILTER="" ARCH_FILTER="" GREP_FILTER="" SEARCH_RESULTS=""

    while (( $# > 0 )); do
        # last arg is user and database
        if (( $# == 1 )); then
            RPM_SEARCH="$1"
            shift
            break
        fi

        case "$1" in
            -a)
                shift
                ARCH_FILTER="$1"
                shift
                ;;
            --arch=*)
                ARCH_FILTER="$(echo "$1" | cut -d '=' -f 2)"
                shift
                ;;
            -d)
                shift
                DISTRO_FILTER="$1"
                shift
                ;;
            --distro=*)
                DISTRO_FILTER="$(echo "$1" | cut -d '=' -f 2)"
                shift
                ;;
            -f)
                shift
                GREP_FILTER="$1"
                shift
                ;;
            --filter=*)
                GREP_FILTER="$(echo "$1" | cut -d '=' -f 2)"
                shift
                ;;
        esac
    done

    # if grep filter not set it defaults to rpm search
    if [[ -z "$GREP_FILTER" ]]; then
        GREP_FILTER="${RPM_SEARCH}"
    fi

    # grab the results of the search using an API on rpmfind.net
    SEARCH_RESULTS=$(
        curl -sL "https://www.rpmfind.net/linux/rpm2html/search.php?query=${RPM_SEARCH}&system=${DISTRO_FILTER}&arch=${ARCH_FILTER}" 2>/dev/null |
            perl -e "\$rpmfind_base_url='https://rpmfind.net'; \$rpm_search='${RPM_SEARCH}'; @matches=(); " -0777 -e \
                '$html = do { local $/; <STDIN> };
                @matches = ($html =~ m%(?<=\<a href=["'"'"'])([-a-zA-Z0-9\@\:\%\._\+~#=/]*${rpm_search}[-a-zA-Z0-9\@\:\%\._\+\~\#\=]*\.rpm)(?=["'"'"']\>)%g);
                foreach my $match (@matches) { print "${rpmfind_base_url}${match}\n"; }' 2>/dev/null |
            grep -m 1 "${GREP_FILTER}"
    )

    if [[ -n "$SEARCH_RESULTS" ]]; then
        echo "$SEARCH_RESULTS"
    fi
}

# try installing in the following order:
# 1: headers from repos
# 2: headers from rpmfind.net (updates branch)
# 3: headers from rpmfind.net (os branch)
# 4: headers from linuxsoft.cern.ch (updates branch)
# 5: headers from linuxsoft.cern.ch (os branch)
function installKernelDevHeaders {
    local DISTRO_VER="$DISTRO_VER"
    local OS_ARCH="$OS_ARCH"
    local OS_KERNEL="$OS_KERNEL"

    if (( ${DISTRO_VER} >= 8 )); then
        dnf install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL} ||
        dnf install -y https://rpmfind.net/linux/centos/${DISTRO_VER}/updates/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://rpmfind.net/linux/centos/${DISTRO_VER}/updates/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        dnf install -y https://rpmfind.net/linux/centos/${DISTRO_VER}/os/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://rpmfind.net/linux/centos/${DISTRO_VER}/os/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        dnf install -y https://linuxsoft.cern.ch/cern/centos/${DISTRO_VER}/updates/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://linuxsoft.cern.ch/cern/centos/${DISTRO_VER}/updates/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        dnf install -y https://linuxsoft.cern.ch/cern/centos/${DISTRO_VER}/os/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://linuxsoft.cern.ch/cern/centos/${DISTRO_VER}/os/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm
    else
        yum install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL} ||
        yum install -y https://rpmfind.net/linux/centos/${DISTRO_VER}/updates/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://rpmfind.net/linux/centos/${DISTRO_VER}/updates/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y https://rpmfind.net/linux/centos/${DISTRO_VER}/os/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://rpmfind.net/linux/centos/${DISTRO_VER}/os/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y https://linuxsoft.cern.ch/cern/centos/${DISTRO_VER}/updates/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://linuxsoft.cern.ch/cern/centos/${DISTRO_VER}/updates/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y https://linuxsoft.cern.ch/cern/centos/${DISTRO_VER}/os/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://linuxsoft.cern.ch/cern/centos/${DISTRO_VER}/os/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm
    fi
}

# compile and install rtpengine from RPM's
function install {
    local RTPENGINE_RPM_VER BUILD_KERN_VERSIONS
    local REBOOT_REQUIRED=0
    local OS_ARCH=$(uname -m)
    local OS_KERNEL=$(uname -r)
    local RHEL_BASE_VER=$(rpm -E %{rhel})
    local DISTRO_VER="$(cat /etc/redhat-release | cut -d ' ' -f 4)"
    local NPROC=$(nproc)

    # Install required libraries
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum-config-manager -y --add-repo https://negativo17.org/repos/epel-multimedia.repo
    sed -i 's|$releasever|'"${RHEL_BASE_VER}|g" /etc/yum.repos.d/epel-multimedia.repo
    rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
    rpm -Uh http://li.nux.ro/download/nux/dextop/el7/${OS_ARCH}/nux-dextop-release-0-5.el7.nux.noarch.rpm

    yum install -y gcc glib2 glib2-devel zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel \
        xmlrpc-c xmlrpc-c-devel libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel \
        iptables iptables-devel xmlrpc-c-devel gperf system-lsb redhat-rpm-config rpm-build pkgconfig \
        freetype-devel fontconfig-devel libxml2-devel nc dkms logrotate rsyslog perl perl-IPC-Cmd spandsp-devel bc libwebsockets-devel \
        gperf gperftools gperftools-devel gperftools-libs gzip mariadb-devel perl-Config-Tiny spandsp \
        $(rpmSearch -d centos -a x86_64 -f el7 librabbitmq) $(rpmSearch -d centos -a x86_64 -f el7 librabbitmq-devel) \
        libbluray-devel libavcodec-devel libavformat-devel libavutil-devel libswresample-devel libavfilter-devel ffmpeg ffmpeg-devel \
        libjpeg-turbo-devel mosquitto-devel &&
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
                make -j $NRPOC &&
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
        if (( ${DISTRO_VER} >= 8 )); then
            dnf install -y ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-${RTPENGINE_RPM_VER}*.rpm \
                ${RPM_BUILD_ROOT}/RPMS/noarch/ngcp-rtpengine-dkms-${RTPENGINE_RPM_VER}*.rpm \
                ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-kernel-${RTPENGINE_RPM_VER}*.rpm
        else
            yum localinstall -y ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-${RTPENGINE_RPM_VER}*.rpm \
                ${RPM_BUILD_ROOT}/RPMS/noarch/ngcp-rtpengine-dkms-${RTPENGINE_RPM_VER}*.rpm \
                ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-kernel-${RTPENGINE_RPM_VER}*.rpm
        fi
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

    if (( $? != 0 )) && (( ${DISTRO_VER} == 7 )); then
        # fix for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1575845
        systemctl restart dbus
        systemctl restart firewalld
        # fix for ensuing bug: https://bugzilla.redhat.com/show_bug.cgi?id=1372925
        systemctl restart systemd-logind
    fi

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
    if (( ${DISTRO_VER} > 7 )); then
        cp -f ${DSIP_PROJECT_DIR}/rtpengine/systemd/rtpengine-v3.service /lib/systemd/system/rtpengine.service
    else
        cp -f ${DSIP_PROJECT_DIR}/rtpengine/systemd/rtpengine-v2.service /lib/systemd/system/rtpengine.service
    fi
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
