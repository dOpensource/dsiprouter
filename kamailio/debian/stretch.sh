#!/bin/bash
set -x
DEB_REL=`basename -s .sh $0`

function install {
grep deb.kamailio.org/kamailio${KAM_VERSION} /etc/apt/sources.list 
# If repo is not installed
if [ $? -eq 1 ]; then
	echo -e "\n# kamailio repo's
	deb http://deb.kamailio.org/kamailio${KAM_VERSION} ${DEB_REL} main
	deb-src http://deb.kamailio.org/kamailio${KAM_VERSION} ${DEB_REL} main" >> /etc/apt/sources.list
fi
#Add Key for Kamailio Repo
wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | apt-key add -

#Update the repo
apt-get update

#Install Kamailio packages
apt-get install -y --allow-unauthenticated firewalld kamailio kamailio-mysql-modules kamailio-utils-modules kamailio-json-modules mysql-server

#Enable MySQL and Kamailio for system startup
systemctl enable mysql

#Make sure mysql starts before Kamailio
sed -i s/After=.*/After=mysqld.service/g /lib/systemd/system/kamailio.service
systemctl daemon-reload
systemctl enable kamailio

#Start MySQL
systemctl start mysql

# Configure Kamailio and Required Database Modules
#sed -i 's/# DBENGINE=MYSQL/DBENGINE=MYSQL/' /etc/kamailio/kamctlrc

mkdir /etc/kamailio
echo "DBENGINE=MYSQL" >> /etc/kamailio/kamctlrc
echo "INSTALL_EXTRA_TABLES=yes" >> /etc/kamailio/kamctlrc
echo "INSTALL_PRESENCE_TABLES=yes" >> /etc/kamailio/kamctlrc
echo "INSTALL_DBUID_TABLES=yes" >> /etc/kamailio/kamctlrc
echo "DBROOTPW=' ' " >> /etc/kamailio/kamctlrc

#Will hardcode lation1 as the database character set used to create the Kamailio schema due to
#a potential bug in how Kamailio additional tables are created
echo "CHARSET=latin1" >> /etc/kamailio/kamctlrc

# Execute 'kamdbctl create' to create the Kamailio database schema 
kamdbctl create

# Firewall settings
firewall-cmd --zone=public --add-port=5060/udp --permanent

if [ -n "$DSIP_PORT" ]; then
	firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
fi

firewall-cmd --reload

#Setup logrotate
cp ./dsiprouter/debian/logrotate/* /etc/logrotate.d

#Start Kamailio
#systemctl start kamailio
#return #?
return 0
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
