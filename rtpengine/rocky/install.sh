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
        local OS_VER="$(cat /etc/redhat-release | cut -d ' ' -f 4)"
        local OS_ARCH="$(uname -m)"
        local OS_KERNEL="$(uname -r)"

        yum install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL} ||
        yum install -y https://rpmfind.net/linux/centos/${OS_VER}/updates/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://rpmfind.net/linux/centos/${OS_VER}/updates/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y https://rpmfind.net/linux/centos/${OS_VER}/os/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://rpmfind.net/linux/centos/${OS_VER}/os/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y https://linuxsoft.cern.ch/cern/centos/${OS_VER}/updates/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://linuxsoft.cern.ch/cern/centos/${OS_VER}/updates/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y https://linuxsoft.cern.ch/cern/centos/${OS_VER}/os/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://linuxsoft.cern.ch/cern/centos/${OS_VER}/os/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm
    }

# compile and install rtpengine from RPM's
function install {
    local OS_ARCH=$(uname -m)
    local OS_KERNEL=$(uname -r)
    local RHEL_BASE_VER=$(rpm -E %{rhel})

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
        libjpeg-turbo-devel mosquitto-devel
    yum install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL}

    if (( $? != 0 )); then
        printerr "Problem with installing the required libraries for RTPEngine"
        exit 1
    fi

    # create rtpengine user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine

    # Make and Configure RTPEngine
    cd ${SRC_DIR}
    rm -rf rtpengine.bak 2>/dev/null
    mv -f rtpengine rtpengine.bak 2>/dev/null
    git clone https://github.com/sipwise/rtpengine.git -b ${RTPENGINE_VER}
    cd rtpengine

    RTPENGINE_RPM_VER=$(grep -oP 'Version:.+?\K[\w\.\~\+]+' ./el/rtpengine.spec)
    if (( $(echo "$RTPENGINE_VER" | perl -0777 -pe 's|mr(\d+\.\d+)\.(\d+)\.(\d+)|\1\2\3 >= 6.511|gm' | bc -l) )); then
        PREFIX="rtpengine-${RTPENGINE_RPM_VER}/"
    else
        PREFIX="ngcp-rtpengine-${RTPENGINE_RPM_VER}/"
    fi

    RPM_BUILD_ROOT="${HOME}/rpmbuild"
    rm -rf ${RPM_BUILD_ROOT}
    mkdir -p ${RPM_BUILD_ROOT}/SOURCES
    git archive --output ${RPM_BUILD_ROOT}/SOURCES/ngcp-rtpengine-${RTPENGINE_RPM_VER}.tar.gz --prefix=${PREFIX} ${RTPENGINE_VER}
    # fix for rpm build path issue
    perl -i -pe 's|(%define archname) rtpengine-mr|\1 rtpengine-|' ./el/rtpengine.spec
    # build the RPM's
    rpmbuild -ba ./el/rtpengine.spec
    # install the RPM's
    yum localinstall -y ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-${RTPENGINE_RPM_VER}*.rpm \
        ${RPM_BUILD_ROOT}/RPMS/noarch/ngcp-rtpengine-dkms-${RTPENGINE_RPM_VER}*.rpm \
        ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-kernel-${RTPENGINE_RPM_VER}*.rpm
#        ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-recording-${RTPENGINE_RPM_VER}*.rpm

    if (( $? != 0 )); then
        printerr "Problem installing RTPEngine RPM's"
        exit 1
    fi

    # ensure config dirs exist
    mkdir -p /var/run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /var/run/rtpengine

    # Configure RTPEngine to support kernel packet forwarding
    cd ${SRC_DIR}/rtpengine/kernel-module &&
    make &&
    cp -f xt_RTPENGINE.ko /lib/modules/${OS_KERNEL}/updates/ &&
    if (( $? != 0 )); then
        printerr "Problem installing RTPEngine kernel-module"
        exit 1
    fi

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

    if (( $? != 0 )); then
        # fix for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1575845
        systemctl restart dbus
        systemctl restart firewalld
        # fix for ensuing bug: https://bugzilla.redhat.com/show_bug.cgi?id=1372925
        systemctl restart systemd-logind
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

    # Reconfigure systemd service files
    rm -f /lib/systemd/system/rtpengine.service 2>/dev/null
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
    if [ $? -ne 0 ]; then
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
        uninstall && exit 0
        ;;
    install)
        install && exit 0
        ;;
    *)
        printerr "usage $0 [install | uninstall]" && exit 1
        ;;
esac
