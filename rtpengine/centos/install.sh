function installKernelDevHeaders {
        local OS_VER="$(cat /etc/redhat-release | cut -d ' ' -f 4)"
        local OS_ARCH="$(uname -m)"
        local OS_KERNEL="$(uname -r)"

        yum --disablerepo='*' --enablerepo=elrepo install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL} ||
        yum install -y https://rpmfind.net/linux/centos/${OS_VER}/updates/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://rpmfind.net/linux/centos/${OS_VER}/updates/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y https://rpmfind.net/linux/centos/${OS_VER}/os/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://rpmfind.net/linux/centos/${OS_VER}/os/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y https://linuxsoft.cern.ch/cern/centos/${OS_VER}/updates/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://linuxsoft.cern.ch/cern/centos/${OS_VER}/updates/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y https://linuxsoft.cern.ch/cern/centos/${OS_VER}/os/${OS_ARCH}/Packages/kernel-devel-${OS_KERNEL}.rpm \
            https://linuxsoft.cern.ch/cern/centos/${OS_VER}/os/${OS_ARCH}/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y http://linuxsoft.cern.ch/cern/centos/${OS_VER}/BaseOS/${OS_ARCH}/os/Packages/kernel-devel-${OS_KERNEL}.rpm \
                       http://linuxsoft.cern.ch/cern/centos/${OS_VER}/BaseOS/${OS_ARCH}/os/Packages/kernel-headers-${OS_KERNEL}.rpm ||
        yum install -y http://linuxsoft.cern.ch/cern/centos/${OS_VER}/BaseOS/${OS_ARCH}/os/images/kernel-devel-${OS_KERNEL}.rpm \
                       http://linuxsoft.cern.ch/cern/centos/${OS_VER}/BaseOS/${OS_ARCH}/os/images/kernel-headers-${OS_KERNEL}.rpm
    }

yum -y install dnf-plugins-core
yum config-manager --set-enabled PowerTools
dnf -y install https://download.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
dnf -y install --nogpgcheck https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
dnf -y install http://rpmfind.net/linux/epel/7/x86_64/Packages/s/SDL2-2.0.10-1.el7.x86_64.rpm
dnf -y install ffmpeg
dnf -y install ffmpeg-devel
yum -y install iptables-devel kernel-devel kernel-headers xmlrpc-c xmlrpc-c-client
yum -y install kernel-devel
yum -y install glib2 glib2-devel gcc zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel xmlrpc-c-devel
yum -y install libevent-devel glib2-devel json-glib-devel gperf gperftools-libs gperftools gperftools-devel libpcap libpcap-devel git hiredis hiredis-devel redis perl-IPC-Cmd
yum -y install spandsp-devel spandsp
yum -y install epel-release
yum -y install elfutils-libelf-devel gcc-toolset-9-elfutils-libelf-devel
rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm

installKernelDevHeaders

cd /usr/local/src
rm -rf rtpengine/
git clone https://github.com/sipwise/rtpengine.git -b mr7.5.4
cd /usr/local/src/rtpengine/daemon/
make
cp rtpengine /usr/sbin/rtpengine
cd /usr/local/src/rtpengine/iptables-extension
make all
cp libxt_RTPENGINE.so /usr/lib64/xtables/.
cd /usr/local/src/rtpengine/kernel-module
make
mkdir /lib/modules/$(uname -r)/extra
cp xt_RTPENGINE.ko /lib/modules/$(uname -r)/extra/xt_RTPENGINE.ko
depmod -a
modprobe xt_RTPENGINE
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
        echo "RTPEngine has been installed!"
    else
        echo "FAILED: RTPEngine could not be installed!"
    fi
