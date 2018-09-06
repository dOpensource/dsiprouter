#!/bin/bash

set -x
DEB_REL=`basename -s .sh $0`

function centos_7_prereq() {

 #Check if mariadb is installed
 #
 #if [ $? -eq 0 ]; then
 # echo "Mariadb server is already installed"
 #else
 
  yum install -y mariadb-server 

 #fi 
 
 return

}


function centos_7_config() {

 touch /etc/tmpfiles.d/kamailio.conf
        echo "d /run/kamailio 0750 kamailio kamailio" > /etc/tmpfiles.d/kamailio.conf 

 sed -i 's/# DBENGINE=MYSQL/DBENGINE=MYSQL/' /etc/kamailio/kamctlrc
 if [ $? -eq 0 ]; then
  echo "Updated the Kamailio control file to support the configuration coming from a MySQL database"
 fi 

 #Execute 'kamdbctl create' to create the Kamailio database schema 
 echo -e "You are about to create the database schema for Kamailio within MySQL.\nYou will need the MySQL root password that you used to create the database\n"
 kamdbctl create
 
 echo -e "\n\nIf kamdbctl create was successful you are now ready to setup the standard proxy configuration by running the ./setup script"

 return
}


function centos_install_kamailio() {

# Install Dependencies
yum -y update
yum -y groupinstall 'core'
yum -y groupinstall 'base'
yum -y groupinstall 'Developer Tools'
yum -y install yum-utils psmisc wget sed gawk vim epel-release mariadb-server mariadb


# Start MySql
systemctl start mariadb
systemctl enable mariadb
alias mysql="mariadb"

# Disable SELinux
sed -i 's/(^SELINUX=).*/SELINUX=disabled/' /etc/selinux/config

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

yum -y update
yum -y install kamailio kamailio-ldap kamailio-mysql kamailio-postgres kamailio-debuginfo kamailio-xmpp \
    kamailio-unixodbc kamailio-utils kamailio-tls kamailio-presence kamailio-outbound kamailio-gzcompress

 Configure Kamailio and Required Database Modules
sed -i 's,# DBENGINE=MYSQL/DBENGINE=MYSQL/' /etc/kamailio/kamctlrc


# Execute 'kamdbctl create' to create the Kamailio database schema 
kamdbctl create

# Configure kamailio
cp -f kamailio.cfg /etc/kamailio.cfg
sed -i '/#!KAMAILIO/r ./kam-flags.txt' /etc/kamailio/kamailio.cfg

chown kamailio:kamailio /etc/default/kamailio
chown -R kamailio:kamailio /etc/kamailio/
chown -R kamailio:kamailio /var/run/kamailio

# Setup firewall rules
firewall-cmd --zone=public --add-port=5060/udp --permanent
firewall-cmd --zone=public --add-port=10000-30000/udp --permanent
firewall-cmd --reload

}


function install {

	centos_7_prereq
	centos_install_kamailio
	centos_7_config

}

function uninstall {

#Stop servers
systemctl stop kamailio
systemctl stop mysql

#Backup kamailio configuration directory
mv /etc/kamailio /etc/kamailio.bak.`(date +%Y%m%d_%H%M%S)`

#Uninstall Kamailio modules and Mariadb
apt-get -y remove --purge mysql\*
apt-get -y remove --purge mariadb\*
apt-get -y remove --purge kamailio\*

#Backup Kamailio database just in 
#mv /var/lib/mysql /var/lib/mysql.kamailio

#Potentially remove the repo's

#Remove firewall rules that was created by us:
firewall-cmd --zone=public --remove-port=5060/udp --permanent

if [ -n "$DSIP_PORT" ]; then
	firewall-cmd --zone=public --remove-port=${DSIP_PORT}/tcp --permanent
fi

firewall-cmd --reload

#Remove logrotate settings
rm /etc/logrotate.d/kamailio
rm /etc/logrotate.d/rtpengine

}

case "$1" in 

uninstall|remove)
#Remove Kamailio
	DSIP_PORT=$3
	KAM_VERSION=$2
	$1
	;;
install)
#Install Kamailio
	DSIP_PORT=$3
	KAM_VERSION=$2
        $1
	;;
*)
        echo "usage $0 [install <kamailio version> <dsip_port> | uninstall <kamailio version> <dsip_port>]"   
	;;
esac
