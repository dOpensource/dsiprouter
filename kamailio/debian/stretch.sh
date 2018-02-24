#!/bin/bash
#set +x
DEB_REL=`basename -s .sh $0`

function install {
grep 'deb.kamailio.org/kamailio ${DEB_REL}' /etc/apt/sources.list 
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

#echo "INSTALL_EXTRA_TABLES=yes" >> /etc/kamailio/kamctlrc
#echo "INSTALL_PRESENCE_TABLES=yes" >> /etc/kamailio/kamctlrc
#echo "INSTALL_DBUID_TABLES=yes" >> /etc/kamailio/kamctlrc

# Execute 'kamdbctl create' to create the Kamailio database schema 
kamdbctl create

#Start Kamailio
systemctl start kamailio
return #?

}

function uninstall {

#Stop servers
systemctl stop kamailio
systemctl stop mysql

#Backup kamailio configuration directory
mv /etc/kamailio /etc/kamailio.bak

#Uninstall Kamailio modules - leave Mariadb
apt-get remove -y  kamailio kamailio-mysql-modules mysql-server

#Potentially remove the repo's
}

#Remove Kamailio
if [ $# -eq 1 ]; then
	$1
	exit
fi
#Install Kamailio
if [ $# -gt 1 ]; then
	KAM_VERSION=$2
        $1 
 else
        echo "usage $0 [install <kamailio version>|uninstall]"   
 fi
