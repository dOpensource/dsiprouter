#!/usr/bin/env bash

(( $DEBUG == 1 )) && set -x

function install() {
    # Install Dependencies
    yum groupinstall --setopt=group_package_types=mandatory,default,optional -y 'core'
    yum groupinstall --setopt=group_package_types=mandatory,default,optional -y 'base'
    yum groupinstall --setopt=group_package_types=mandatory,default,optional -y 'Development Tools'
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install -y psmisc curl wget sed gawk vim perl firewalld uuid-devel
    yum install -y logrotate rsyslog

    yum install -y mariadb mariadb-libs mariadb-devel mariadb-server
    ln -s /usr/share/mariadb/ /usr/share/mysql
    # Make sure no extra configs present on fresh install
    rm -f ~/.my.cnf

    # allow symlinks in mariadb service
    sed -i 's/symbolic-links=0/#symbolic-links=0/' /etc/my.cnf

    # add in the original aliases (from debian repo) to mariadb.service
    perl -0777 -i -pe 's|(\[Install\]\s+WantedBy.*?\n+)|\1Alias=mysql.service\nAlias=mysqld.service\n\n|gms' /lib/systemd/system/mariadb.service

    # alias mariadb.service to mysql.service and mysqld.service as in debian repo
    # allowing us to use same service name (mysql, mysqld, or mariadb) across platforms
    (cat << 'EOF'
# Add mysql Aliases by including distro script as recommended in /lib/systemd/system/mariadb.service
.include /lib/systemd/system/mariadb.service

[Install]
Alias=
Alias=mysqld.service
Alias=mariadb.service
EOF
    ) > /lib/systemd/system/mysql.service
    chmod 0644 /lib/systemd/system/mysql.service
    (cat << 'EOF'
# Add mysql Aliases by including distro script as recommended in /lib/systemd/system/mariadb.service
.include /lib/systemd/system/mariadb.service

[Install]
Alias=
Alias=mysql.service
Alias=mariadb.service
EOF
    ) > /lib/systemd/system/mysqld.service
    chmod 0644 /lib/systemd/system/mysqld.service
    systemctl daemon-reload

    # if db is remote don't run local service
    reconfigureMysqlSystemdService

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
        kamailio-unixodbc kamailio-utils kamailio-tls kamailio-presence kamailio-outbound kamailio-gzcompress \
        kamailio-http_async_client kamailio-dmq_userloc

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
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc.$(date +%Y%m%d_%H%M%S)
    if [[ -z "${MYSQL_ROOT_PASSWORD-unset}" ]]; then
        local ROOTPW_SETTING="DBROOTPWSKIP=yes"
    else
        local ROOTPW_SETTING="DBROOTPW=\"${MYSQL_ROOT_PASSWORD}\""
    fi

    # TODO: we should set STORE_PLAINTEXT_PW to 0, this is not default but would need tested
    (cat << EOF
DBENGINE=MYSQL
DBHOST=${KAM_DB_HOST}
DBPORT=${KAM_DB_PORT}
DBNAME=${KAM_DB_NAME}
DBRWUSER="${KAM_DB_USER}"
DBRWPW="${KAM_DB_PASS}"
DBROOTUSER="${MYSQL_ROOT_USERNAME}"
${ROOTPW_SETTING}
CHARSET=utf8
INSTALL_EXTRA_TABLES=yes
INSTALL_PRESENCE_TABLES=yes
INSTALL_DBUID_TABLES=yes
# STORE_PLAINTEXT_PW=0
EOF
    ) > ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamctlrc

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
    firewall-cmd --zone=public --add-port=${KAM_SIPS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_WSS_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=${KAM_DMQ_PORT}/udp --permanent
    firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp
    firewall-cmd --reload

    # Make sure MariaDB and Local DNS start before Kamailio
    if grep -v 'mysql.service dnsmasq.service' /lib/systemd/system/kamailio.service; then
        sed -i -r -e 's/(After=.*)/\1 mysql.service dnsmasq.service/' /lib/systemd/system/kamailio.service
    fi
    if grep -v "${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig" /lib/systemd/system/kamailio.service; then
        sed -i -r -e "0,\|^ExecStart.*|{s||ExecStartPre=-${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig\n&|}" /lib/systemd/system/kamailio.service
    fi
    systemctl daemon-reload

    # Enable Kamailio for system startup
    systemctl enable kamailio

    # Configure rsyslog defaults
    if ! grep -q 'dSIPRouter rsyslog.conf' /etc/rsyslog.conf 2>/dev/null; then
        cp -f ${DSIP_PROJECT_DIR}/resources/syslog/rsyslog.conf /etc/rsyslog.conf
    fi

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
    systemctl disable kamailio
    systemctl disable mysql

    # Backup kamailio configuration directory
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR} ${SYSTEM_KAMAILIO_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)

    # Backup mysql / mariadb
    mv -f /var/lib/mysql /var/lib/mysql.bak.$(date +%Y%m%d_%H%M%S)

    # remove mysql unit files we created
    rm -f /lib/systemd/system/mysql.service /lib/systemd/system/mysqld.service

    # Uninstall Kamailio modules and mysql / Mariadb
    yum remove -y mysql\*
    yum remove -y mariadb\*
    yum remove -y kamailio\*
    rm -rf /etc/my.cnf*; rm -f /etc/my.cnf*; rm -f ~/*my.cnf

    # Remove firewall rules that was created by us:
    firewall-cmd --zone=public --remove-port=${KAM_SIP_PORT}/udp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_SIP_PORT}/tcp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_SIPS_PORT}/tcp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_WSS_PORT}/tcp --permanent
    firewall-cmd --zone=public --remove-port=${KAM_DMQ_PORT}/udp --permanent
    firewall-cmd --zone=public --remove-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp
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
