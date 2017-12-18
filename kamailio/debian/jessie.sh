#!/bin/bash

function install {
echo "# install kamailio
deb http://deb.kamailio.org/kamailio jessie main
deb-src http://deb.kamailio.org/kamailio jessie main" >> /etc/apt/sources.list

apt-get update

apt-get install kamailio,kamailio-mysql-modules, mariadb-server

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

#Stop Kamailio server
systemctl stop kamailio

#Backup kamailio configuration directory
mv /etc/kamailio /etc/kamailio.bak

#Uninstall Kamailio modules - leave Mariadb
apt-get uninstall kamailio,kamailio-mysql-modules

#Potentially remove the repo's
}

 if [ $# -eq 1 ]; then
        $1
 else
        echo "usage $0 [install|uninstall]"   
 fi
