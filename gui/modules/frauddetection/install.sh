#!/bin/bash
ENABLED=0

function installSQL {

    echo ""

}


function install {

if [ $ENABLED == "0" ];then
    exit
fi
installSQL

}



function uninstall {

echo ""

}

# This installer will be kicked off by the main dSIPRouter installer by passing the MySQL DB root username, database name, and/or the root password
# This is needed since we are installing stored procedures which require SUPER privileges on MySQL

if [ $# -gt 2 ]; then

	MYSQL_ROOT_USERNAME="-u$1"
	MYSQL_ROOT_PASSWORD="-p$2"
	MYSQL_KAM_DBNAME=$3
else

	MYSQL_ROOT_USERNAME="-u$1"
        MYSQL_ROOT_PASSWORD=
        MYSQL_KAM_DBNAME=$2
fi


install
