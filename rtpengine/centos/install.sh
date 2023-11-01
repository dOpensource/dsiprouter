#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

## search for RPM using external APIs mirrors and archives
## not guaranteed to find an RPM, outputs empty string if search fails
## arguments:
##   $1 == rpm to search for
## options:
##   -d <distro filter>
##   --distro=<distro filter>
##   -f <grep filter>
##   --filter=<grep filter>
## TODO: add support for searching https://linuxsoft.cern.ch as well
#function rpmSearch() {
#    local RPM_SEARCH="" DISTRO_FILTER="$DISTRO" GREP_FILTER="" SEARCH_RESULTS=""
#
#    while (( $# > 0 )); do
#        # last arg is user and database
#        if (( $# == 1 )); then
#            RPM_SEARCH="$1"
#            shift
#            break
#        fi
#
#        case "$1" in
#            -d)
#                shift
#                DISTRO_FILTER="$1"
#                shift
#                ;;
#            --distro=*)
#                DISTRO_FILTER="$(echo "$1" | cut -d '=' -f 2)"
#                shift
#                ;;
#            -f)
#                shift
#                GREP_FILTER="$1"
#                shift
#                ;;
#            --filter=*)
#                GREP_FILTER="$(echo "$1" | cut -d '=' -f 2)"
#                shift
#                ;;
#        esac
#    done
#
#    # if grep filter not set it defaults to rpm search
#    if [[ -z "$GREP_FILTER" ]]; then
#        GREP_FILTER="${RPM_SEARCH}"
#    fi
#
#    # grab the results of the search using an API on rpmfind.net
#    SEARCH_RESULTS=$(
#        curl -sL "https://www.rpmfind.net/linux/rpm2html/search.php?query=${RPM_SEARCH}&system=${DISTRO_FILTER}&arch=${OS_ARCH}" 2>/dev/null |
#            perl -e "\$rpmfind_base_url='https://rpmfind.net'; \$rpm_search='${RPM_SEARCH}'; @matches=(); " -0777 -e \
#                '$html = do { local $/; <STDIN> };
#                @matches = ($html =~ m%(?<=\<a href=["'"'"'])([-a-zA-Z0-9\@\:\%\._\+~#=/]*${rpm_search}[-a-zA-Z0-9\@\:\%\._\+\~\#\=]*\.rpm)(?=["'"'"']\>)%g);
#                foreach my $match (@matches) { print "${rpmfind_base_url}${match}\n"; }' 2>/dev/null |
#            grep -m 1 "${GREP_FILTER}"
#    )
#
#    # if empty try searching the official archives on vault.centos.org
#    if [[ -z "$SEARCH_RESULTS" ]]; then
#        SEARCH_RESULTS=$(
#            curl --keepalive-time 5 --compressed -sL https://vault.centos.org/filelist.gz 2>/dev/null |
#                gunzip -c |
#                tac |
#                grep -oP ".*${OS_ARCH}.*${RPM_SEARCH}.*\.rpm" |
#                grep -m 1 "${GREP_FILTER}" |
#                perl -pe 's%^\./(.*\.rpm)$%https://vault.centos.org/\1%'
#        )
#    fi
#
#    if [[ -n "$SEARCH_RESULTS" ]]; then
#        echo "$SEARCH_RESULTS"
#    fi
#}

# compile and install rtpengine from RPM's
function install {
    local RTPENGINE_RPM_VER TMP
    local OS_ARCH=$(uname -m)
    local OS_KERNEL=$(uname -r)
    local RHEL_BASE_VER=$(rpm -E %{rhel})
    local NPROC=$(nproc)

    # Install required libraries
    if (( ${DISTRO_VER} == 9 )); then
        dnf install -y epel-release &&
        dnf install -y epel-next-release &&
        dnf install -y https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-${RHEL_BASE_VER}.noarch.rpm &&
        dnf install -y https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-${RHEL_BASE_VER}.noarch.rpm &&
        dnf --enablerepo=crb install -y ladspa libuv-devel xmlrpc-c-devel opus-devel
        dnf install -y ffmpeg ffmpeg-devel &&
        dnf install -y gcc glib2 glib2-devel zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel \
            xmlrpc-c libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel \
            iptables iptables-devel gperf nc dkms perl perl-IPC-Cmd spandsp spandsp-devel logrotate rsyslog mosquitto-devel \
            redhat-rpm-config rpm-build pkgconfig perl-Config-Tiny gperftools-libs gperftools gperftools-devel gzip \
            libwebsockets-devel iptables-legacy-devel pandoc
    elif (( ${DISTRO_VER} == 8 )); then
        dnf install -y epel-release &&
        dnf install -y epel-next-release &&
        dnf config-manager --enable powertools &&
        dnf install -y https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-${RHEL_BASE_VER}.noarch.rpm &&
        dnf install -y https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-${RHEL_BASE_VER}.noarch.rpm &&
        dnf install -y ffmpeg ffmpeg-devel &&
        dnf install -y gcc glib2 glib2-devel zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel \
            xmlrpc-c libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel \
            iptables iptables-devel gperf nc dkms perl perl-IPC-Cmd spandsp spandsp-devel logrotate rsyslog mosquitto-devel \
            redhat-rpm-config rpm-build pkgconfig perl-Config-Tiny gperftools-libs gperftools gperftools-devel gzip \
            libwebsockets-devel opus-devel xmlrpc-c-devel gcc-toolset-13 pandoc &&
        source scl_source enable gcc-toolset-13
    else
        yum install -y epel-release &&
        rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro &&
        rpm -Uh http://li.nux.ro/download/nux/dextop/el${DISTRO_VER}/${OS_ARCH}/nux-dextop-release-0-5.el${DISTRO_VER}.nux.noarch.rpm &&
        yum install -y ffmpeg ffmpeg-devel &&
        yum install -y gcc glib2 glib2-devel zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel mariadb-devel \
            xmlrpc-c xmlrpc-c-devel libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel \
            iptables iptables-devel xmlrpc-c-devel gperf redhat-lsb nc dkms perl perl-IPC-Cmd spandsp spandsp-devel logrotate rsyslog \
            redhat-rpm-config rpm-build pkgconfig perl-Config-Tiny gperftools-libs gperftools gperftools-devel gzip libwebsockets-devel
    fi

    if (( $? != 0 )); then
        printerr "Could not install the required libraries for RTPEngine"
        exit 1
    fi

    if (( ${DISTRO_VER} >= 8 )); then
        dnf install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL} || {
            printwarn 'could not install kernel headers for current kernel'
            echo 'upgrading kernel and installing new headers'
            printwarn 'you will need to reboot the machine for changes to take effect'
            dnf install -y kernel-devel kernel-headers
        }
    else
        yum install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL} || {
            printwarn 'could not install kernel headers for current kernel'
            echo 'upgrading kernel and installing new headers'
            printwarn 'you will need to reboot the machine for changes to take effect'
            yum install -y kernel-devel kernel-headers
        }
    fi

    if (( $? != 0 )); then
        printerr "Could not install kernel headers"
        exit 1
    fi

    # create rtpengine user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel rtpengine &>/dev/null; groupdel rtpengine &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine

    # reuse repo if it exists and matches version we want to install
    if [[ -d ${SRC_DIR}/rtpengine ]]; then
        if [[ "$(getGitTagFromShallowRepo ${SRC_DIR}/rtpengine)" != "${RTPENGINE_VER}" ]]; then
            rm -rf ${SRC_DIR}/rtpengine
            git clone --depth 1 -c advice.detachedHead=false -b ${RTPENGINE_VER} https://github.com/sipwise/rtpengine.git ${SRC_DIR}/rtpengine
        fi
    else
        git clone --depth 1 -c advice.detachedHead=false -b ${RTPENGINE_VER} https://github.com/sipwise/rtpengine.git ${SRC_DIR}/rtpengine
    fi

    RTPENGINE_RPM_VER=$(grep -oP 'Version:.+?\K[\w\.\~\+]+' ${SRC_DIR}/rtpengine/el/rtpengine.spec)
    RPM_BUILD_ROOT="${HOME}/rpmbuild"
    rm -rf ${RPM_BUILD_ROOT} 2>/dev/null
    mkdir -p ${RPM_BUILD_ROOT}/SOURCES &&
    (
        # some packages had to be compiled from source and therefore the default rpm build will fail
        # we remove these from the the rpm spec files so we can still reliably install the other deps
        # this also allows us to keep the standard post/pre build configurations from the spec file
        cd ${SRC_DIR} &&
        tar -czf ${RPM_BUILD_ROOT}/SOURCES/ngcp-rtpengine-${RTPENGINE_RPM_VER}.tar.gz \
            --transform="s%^rtpengine%ngcp-rtpengine-$RTPENGINE_RPM_VER%g" rtpengine/ &&
        echo "%__make /usr/bin/make -j $NPROC" >~/.rpmmacros &&
        # build the RPM's
        rpmbuild -ba ${SRC_DIR}/rtpengine/el/rtpengine.spec &&
        rm -f ~/.rpmmacros &&
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
        exit 1
    fi

    # make sure RTPEngine kernel module configured
    # skip if the kernel headers were not installed
    if rpm -qa | grep -q "kernel-headers-$(uname -r)"; then
        if [[ -z "$(find /lib/modules/${OS_KERNEL}/ -name 'xt_RTPENGINE.ko*' 2>/dev/null)" ]]; then
            printerr "Problem installing RTPEngine kernel module"
            exit 1
        fi
    fi

    # ensure config dirs exist
    mkdir -p /var/run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /var/run/rtpengine

    # rtpengine config file
    # ref example config: https://github.com/sipwise/rtpengine/blob/master/etc/rtpengine.sample.conf
    # TODO: move from 2 separate config files to generating entire config
    #       1st we should change to generating config using rtpengine-start-pre
    #       eventually we should create a config parser similar to how kamailio config is parsed
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/configs/rtpengine.conf ${SYSTEM_RTPENGINE_CONFIG_FILE}

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

    rm -f /usr/bin/rtpengine
    rm -f /etc/rsyslog.d/rtpengine.conf
    rm -f /etc/logrotate.d/rtpengine

    # remove our selinux changes
    semanage port -D -t rtp_media_port_t -p udp

    # remove our firewall changes
    firewall-cmd --zone=public --remove-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp --permanent
    firewall-cmd --reload

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

