#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

# Get more detailed OS info
DISTRO=${DISTRO:-centos}
DISTRO_VER=${DISTRO_VER:-$(cat /etc/redhat-release | cut -d ' ' -f 4 | cut -d '.' -f 1)}
OS_VER=$(cat /etc/redhat-release | cut -d ' ' -f 4)
OS_ARCH=$(uname -m)
OS_KERNEL=$(uname -r)

# search for RPM using external APIs mirrors and archives
# not guaranteed to find an RPM, outputs empty string if search fails
# arguments:
# $1 == rpm to search for
# options:
# -f <grep filter>
# --filter=<grep filter>
# TODO: add support for searching https://linuxsoft.cern.ch as well
function rpmSearch() {
    local RPM_SEARCH="" GREP_FILTER="" SEARCH_RESULTS=""

    while (( $# > 0 )); do
        # last arg is user and database
        if (( $# == 1 )); then
            RPM_SEARCH="$1"
            shift
            break
        fi

        case "$1" in
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
        curl -sL "https://www.rpmfind.net/linux/rpm2html/search.php?query=${RPM_SEARCH}&system=${DISTRO}&arch=${OS_ARCH}" 2>/dev/null |
            perl -e "\$rpmfind_base_url='https://rpmfind.net'; \$rpm_search='${RPM_SEARCH}'; @matches=(); " -0777 -e \
                '$html = do { local $/; <STDIN> };
                @matches = ($html =~ m%(?<=\<a href=["'"'"'])([-a-zA-Z0-9\@\:\%\._\+~#=/]*kernel-devel[-a-zA-Z0-9\@\:\%\._\+\~\#\=]*\.rpm)(?=["'"'"']\>)%g);
                foreach my $match (@matches) { print "${rpmfind_base_url}${match}\n"; }' 2>/dev/null |
            grep -m 1 "${GREP_FILTER}"
    )

    # if empty try searching the official archives on vault.centos.org
    if [[ -z "$SEARCH_RESULTS" ]]; then
        SEARCH_RESULTS=$(
            curl --keepalive-time 5 --compressed -sL https://vault.centos.org/filelist.gz 2>/dev/null |
                gunzip -c |
                tac |
                grep -oP ".*${OS_ARCH}.*${RPM_SEARCH}.*\.rpm" |
                grep -m 1 "${GREP_FILTER}" |
                perl -pe 's%^\./(.*\.rpm)$%https://vault.centos.org/\1%'
        )
    fi

    if [[ -n "$SEARCH_RESULTS" ]]; then
        echo "$SEARCH_RESULTS"
    fi
}

# compile and install rtpengine from RPM's
function install {
    local RTPENGINE_RPM_VER=""

    # try installing in the following order:
    # 1: headers from repos
    # 2: headers from rpmfind.net
    function installKernelDevHeaders {
        yum install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL} ||
            yum install -y $(rpmSearch -f kernel-devel-${OS_KERNEL} kernel-devel) $(rpmSearch -f kernel-headers-${OS_KERNEL} kernel-headers)
    }

    # Install required libraries
    yum install -y epel-release
    if (( ${DISTRO_VER} >= 8 )); then
        yum install -y dnf-plugins-core dnf-utils
        yum config-manager --set-enabled PowerTools
        yum-config-manager --add-repo=https://negativo17.org/repos/epel-multimedia.repo
        dnf install -y ffmpeg ffmpeg-devel
        #yum -y install gperf gperftools-libs gperftools gperftools-devel
        #yum -y install elfutils-libelf-devel gcc-toolset-9-elfutils-libelf-devel
    else
        rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
        rpm -Uh http://li.nux.ro/download/nux/dextop/el${DISTRO_VER}/${OS_ARCH}/nux-dextop-release-0-5.el${DISTRO_VER}.nux.noarch.rpm
        yum install -y ffmpeg ffmpeg-devel
    fi
    yum install -y gcc glib2 glib2-devel zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel mariadb-devel \
        xmlrpc-c xmlrpc-c-devel libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel \
        iptables iptables-devel xmlrpc-c-devel gperf redhat-lsb nc dkms perl perl-IPC-Cmd spandsp spandsp-devel logrotate rsyslog bc \
        redhat-rpm-config rpm-build pkgconfig perl-Config-Tiny gperf gperftools-libs gperftools gperftools-devel gzip libwebsockets-devel

    installKernelDevHeaders

    if (( $? != 0 )); then
        printerr "Problem with installing the required libraries for RTPEngine"
        exit 1
    fi

    # alias and link rsyslog to syslog service as in debian
    # allowing rsyslog to be accessible via syslog namespace
    # the settings are already there just commented out by default
    sed -i -r 's|^[;](.*)|\1|g' /usr/lib/systemd/system/rsyslog.service
    ln -sf /usr/lib/systemd/system/rsyslog.service /etc/systemd/system/syslog.service
    systemctl daemon-reload

    # create rtpengine user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine

    # Make and Configure RTPEngine
    cd ${SRC_DIR}
    rm -rf rtpengine.bak 2>/dev/null
    mv -f rtpengine rtpengine.bak 2>/dev/null
    git clone https://github.com/sipwise/rtpengine.git -b ${RTPENGINE_VER}
    cd ./rtpengine

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
    # install the required RPM's
    rpm -i ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-${RTPENGINE_RPM_VER}*.rpm
    rpm -q ngcp-rtpengine &>/dev/null; ret=$?
    rpm -i ${RPM_BUILD_ROOT}/RPMS/noarch/ngcp-rtpengine-dkms-${RTPENGINE_RPM_VER}*.rpm
    rpm -q ngcp-rtpengine-dkms &>/dev/null; ((ret+=$?))
    rpm -i ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-kernel-${RTPENGINE_RPM_VER}*.rpm
    rpm -q ngcp-rtpengine-kernel &>/dev/null; ((ret+=$?))
    # install extra RPM's if they exist (version dependent)
    RTPENGINE_RECORDING_RPM=$(find ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH} -name "ngcp-rtpengine-recording-${RTPENGINE_RPM_VER}*.rpm" -print -quit)
    if [[ -f "$RTPENGINE_RECORDING_RPM" ]]; then
        rpm -i ${RTPENGINE_RECORDING_RPM}
        rpm -q ngcp-rtpengine-recording &>/dev/null; ((ret+=$?))
    fi

    if (( $ret != 0 )); then
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

    if [ "$SERVERNAT" == "0" ]; then
        INTERFACE=$EXTERNAL_IP
    else
        INTERFACE=$INTERNAL_IP!$EXTERNAL_IP
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

    # Fix for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1575845
    if (( $? != 0 )); then
        systemctl restart dbus
        systemctl restart firewalld
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
    if [ $? -ne 0 ]; then
        /usr/sbin/rtpengine --config-file=${SYSTEM_RTPENGINE_CONFIG_FILE} --pidfile=/var/run/rtpengine/rtpengine.pid
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
    rm -f /usr/sbin/rtpengine
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

