#!/usr/bin/env bash

set -x

function install() {
    # Install Dependencies
    yum groupinstall -y 'core'
    yum groupinstall -y 'base'
    yum groupinstall -y 'Development Tools'
    yum install -y psmisc curl wget sed gawk vim epel-release perl firewalld
    yum install -y logrotate rsyslog

    yum install -y mariadb mariadb-libs mariadb-devel mariadb-server
    ln -s /usr/share/mariadb/ /usr/share/mysql
    # Make sure no extra configs present on fresh install
    rm -f ~/.my.cnf

    # allow symlinks in mariadb service
    sed -i 's/symbolic-links=0/#symbolic-links=0/' /etc/my.cnf

    # alias mariadb.service to mysql.service and mysqld.service as in debian repo
    # allowing us to use same service name across platforms
    (cat << 'EOF'
# Add mysql Aliases by including distro script
# as recommended in /lib/systemd/system/mariadb.service
.include /lib/systemd/system/mariadb.service

[Install]
Alias=mysql.service
Alias=mysqld.service
EOF
    ) > /etc/systemd/system/mariadb.service
    chmod 0644 /etc/systemd/system/mariadb.service

    # link the services so we can use the mysql namespace from systemctl
    ln -s /etc/systemd/system/mariadb.service /etc/systemd/system/mysql.service
    ln -s /etc/systemd/system/mariadb.service /etc/systemd/system/mysqld.service
    systemctl daemon-reload

    # create mysql user and group
    mkdir -p /var/run/mariadb
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "Mysql Database Server" mysql
    chown -R mysql:mysql /var/run/mariadb /var/lib/mysql /var/log/mariadb /usr/share/mysql

    # Enable and Start MySql service
    systemctl enable mysql
    systemctl start mysql

    # Disable SELinux
    sed -i -e 's/(^SELINUX=).*/SELINUX=disabled/' /etc/selinux/config

    # create kamailio user and group
    mkdir -p /var/run/kamailio
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock
    useradd --system --user-group --shell /bin/false --comment "Kamailio SIP Proxy" kamailio
    chown -R kamailio:kamailio /var/run/kamailio

    # Add the Kamailio repos to yum
    (cat << 'EOF'
[home_kamailio_v5.1.x-rpms]
name=RPM Packages for Kamailio v5.1.x (CentOS_7)
type=rpm-md
baseurl=http://download.opensuse.org/repositories/home:/kamailio:/v5.1.x-rpms/CentOS_7/
gpgcheck=1
gpgkey=http://download.opensuse.org/repositories/home:/kamailio:/v5.1.x-rpms/CentOS_7/repodata/repomd.xml.key
enabled=1
EOF
    ) > /etc/yum.repos.d/kamailio.repo

    yum update -y
    yum install -y kamailio kamailio-ldap kamailio-mysql kamailio-postgres kamailio-debuginfo kamailio-xmpp \
        kamailio-unixodbc kamailio-utils kamailio-tls kamailio-presence kamailio-outbound kamailio-gzcompress

    # workaround for kamailio rpm transaction failures
    if (( $? != 0 )); then
        rpm --import $(grep 'gpgkey' /etc/yum.repos.d/kamailio.repo | cut -d '=' -f 2)
        REPOS='kamailio kamailio-ldap kamailio-mysql kamailio-postgresql kamailio-debuginfo kamailio-xmpp kamailio-unixodbc kamailio-utils kamailio-tls kamailio-presence kamailio-outbound kamailio-gzcompress'
        for REPO in $REPOS; do
            yum install -y $(grep 'baseurl' /etc/yum.repos.d/kamailio.repo | cut -d '=' -f 2)$(uname -m)/$(repoquery -i ${REPO} | head -4 | tail -n 3 | tr -d '[:blank:]' | cut -d ':' -f 2 | perl -pe 'chomp if eof' | tr '\n' '-').$(uname -m).rpm
        done
    fi

    touch /etc/tmpfiles.d/kamailio.conf
    echo "d /run/kamailio 0750 kamailio users" > /etc/tmpfiles.d/kamailio.conf
 
    # create kamailio defaults config
    (cat << 'EOF'
 RUN_KAMAILIO=yes
 USER=kamailio
 GROUP=kamailio
 SHM_MEMORY=64
 PKG_MEMORY=8
 PIDFILE=/var/run/kamailio/kamailio.pid
 CFGFILE=/etc/kamailio/kamailio.cfg
 #DUMP_CORE=yes
EOF
    ) > /etc/default/kamailio

    # Configure Kamailio and Required Database Modules
    mkdir -p ${SYSTEM_KAMAILIO_CONFIG_DIR}
    echo "" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    echo "DBENGINE=MYSQL" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    echo "INSTALL_EXTRA_TABLES=yes" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    echo "INSTALL_PRESENCE_TABLES=yes" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    echo "INSTALL_DBUID_TABLES=yes" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    echo "DBROOTUSER=\"${MYSQL_ROOT_USERNAME}\"" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    if [[ -z "${MYSQL_ROOT_PASSWORD-unset}" ]]; then
        echo "DBROOTPWSKIP=yes" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    else
        echo "DBROOTPW=\"${MYSQL_ROOT_PASSWORD}\"" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc
    fi

    # Will hardcode lation1 as the database character set used to create the Kamailio schema due to
    # a potential bug in how Kamailio additional tables are created
    echo "CHARSET=latin1" >> ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc

    # Execute 'kamdbctl create' to create the Kamailio database schema
    kamdbctl create

    # Start firewalld
    systemctl start firewalld
    systemctl enable firewalld

    # Fix for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1575845
    if (( $? != 0 )); then
        systemctl restart dbus
        systemctl restart firewalld
    fi

    # Setup firewall rules
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${KAM_SIP_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp
    firewall-cmd --reload

    # Make sure MariaDB starts before Kamailio
    sed -i -E "s/(After=.*)/\1 mysql.service/g" /lib/systemd/system/kamailio.service
    systemctl daemon-reload

    # Setup kamailio Logging
    cp -f ${DSIP_PROJECT_DIR}/resources/syslog/kamailio.conf /etc/rsyslog.d/kamailio.conf
    touch /var/log/kamailio.log
    systemctl restart rsyslog

    # Setup logrotate
    cp -f ${DSIP_PROJECT_DIR}/resources/logrotate/kamailio /etc/logrotate.d/kamailio
}

function uninstall {
    # Stop servers
    systemctl stop kamailio
    systemctl stop mysql

    # Backup kamailio configuration directory
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR} ${SYSTEM_KAMAILIO_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)

    # Backup mysql / mariadb
    mv -f /var/lib/mysql /var/lib/mysql.bak.$(date +%Y%m%d_%H%M%S)

    # Uninstall Kamailio modules and mysql / Mariadb
    yum remove -y mysql\*
    yum remove -y mariadb\*
    yum remove -y kamailio\*
    rm -rf /etc/my.cnf*; rm -f /etc/my.cnf*; rm -f ~/*my.cnf

    # Remove firewall rules that was created by us:
    firewall-cmd --zone=public --remove-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --remove-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp --permanent
    firewall-cmd --reload

    # Remove kamailio Logging
    rm -f /etc/rsyslog.d/kamailio.conf

    # Remove logrotate settings
    rm -f /etc/logrotate.d/kamailio
}

case "$1" in
    uninstall|remove)
        uninstall
        ;;
    install)
        install
        ;;
    *)
        echo "usage $0 [install | uninstall]"
        ;;
esac
