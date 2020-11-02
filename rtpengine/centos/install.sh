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
cp xt_RTPENGINE.ko /lib/modules/$(uname -a)/extra/xt_RTPENGINE.ko
depmod -a
modprobe xt_RTPENGINE
echo 'add 0' > /proc/rtpengine/control
iptables -I INPUT -p udp -j RTPENGINE --id 0
ip6tables -I INPUT -p udp -j RTPENGINE --id 0
