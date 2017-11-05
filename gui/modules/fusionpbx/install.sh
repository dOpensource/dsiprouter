#!/bin/bash


function installSQL {

#Check to see if the acc table or cdr tables are in use

row_count=`mysql -s -N $MYSQL_ROOT_USERNAME $MYSQL_ROOT_PASSWORD $MYSQL_KAM_DBNAME -e "select count(*) from dsip_fusionpbx_db limit 10"`
if [ "$row_count" -gt 0 ]; then
	echo -e "The FusionPBX Domain Support (dsip_fusionpbx_db) table in Kamailio has $row_count existing rows.  Please backup this table before moving forward if you want the data."  	
	echo -e "Would you like to install the FusionPBX Domain Support module now [y/n]:\c"
	read ANSWER
	if [ "$ANSWER" == "n" ]; then
		return
	fi
fi

# Replace the FusionPBX Domain Support tables and add some Kamailio stored procedures
echo "Adding/Replacing the tables needed for FusionPBX Domain Support tables  within dSIPRouter..."
mysql -s -N $MYSQL_ROOT_USERNAME $MYSQL_ROOT_PASSWORD $MYSQL_KAM_DBNAME < ./fusionpbx.sql

}

function install {

echo ""

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


installSQL
