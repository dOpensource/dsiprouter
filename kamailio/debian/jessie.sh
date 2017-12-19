#!/bin/bash
#set +x
function install {
grep 'deb.kamailio.org/kamailio jessie' /etc/apt/sources.list > /dev/null
# If repo is not installed
if [ $? -eq 1 ]; then
	echo -e "\n# kamailio repo's
	deb http://deb.kamailio.org/kamailio${KAM_VERSION} jessie main
	deb-src http://deb.kamailio.org/kamailio${KAM_VERSION} jessie main" >> /etc/apt/sources.list
fi
#Add Key for Kamailio Repo
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xfb40d3e6508ea4c8

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
if [ $# -gt 1 ]; then
	KAM_VERSION=$2
        $1 
 else
        echo "usage $0 [install <kamailio version>|uninstall]"   
 fi
