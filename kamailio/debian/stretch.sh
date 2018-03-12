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
wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | sudo apt-key add -

#Update the repo
apt-get update

#Install Kamailio packages
apt-get install -y kamailio kamailio-mysql-modules mysql-server

#Enable MySQL and Kamailio for system startup
systemctl enable mysql
systemctl enable kamailio

#Start MySQL
systemctl start mysql

# Configure Kamailio and Required Database Modules
sed -i 's/# DBENGINE=MYSQL/DBENGINE=MYSQL/' /etc/kamailio/kamctlrc

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

#Start Kamailio
systemctl start kamailio
return #?

}

function uninstall {

#Stop servers
systemctl stop kamailio
systemctl stop mysql

#Backup kamailio configuration directory
mv /etc/kamailio /etc/kamailio.bak.`(date +%Y%m%d_%H%M%S)`

#Uninstall Kamailio modules and Mariadb
sudo apt-get -y remove --purge mysql\*
sudo apt-get -y remove --purge mariadb\*
sudo apt-get -y remove --purge kamailio\*

#Backup Kamailio database just in 
#mv /var/lib/mysql /var/lib/mysql.kamailio

#Potentially remove the repo's

#Remove firewall rules that was created by us:
firewall-cmd --zone=public --remove-port=5060/udp

if [ -n "$DSIP_PORT" ]; then
	firewall-cmd --zone=public --remove-port=${DSIP_PORT}/tcp
fi

firewall-cmd --reload

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
