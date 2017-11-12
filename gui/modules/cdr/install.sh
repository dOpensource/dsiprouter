#!/bin/bash
ENABLED=0

function installSQL {

#Check to see if the acc table or cdr tables are in use

acc_row_count=`mysql -s -N $MYSQL_ROOT_USERNAME $MYSQL_ROOT_PASSWORD $MYSQL_KAM_DBNAME -e "select count(*) from acc limit 10"`
if [ "$acc_row_count" -gt 0 ]; then
	echo -e "The accounting table (acc) in Kamailio has $acc_row_count existing rows.  Please backup this table before moving forward if you want the data.\nIt will be deleted and recreated with additionals fields needed to support CDR's within dSIPRouter."  	
	echo -e "Would you like to install the CDR module now [y/n]:\c"
	read ANSWER
	if [ "$ANSWER" == "n" ]; then
		return
	fi
fi

# Replace the CDR tables and add some Kamailio stored procedures
echo "Adding/Replacing the tables needed for CDR's within dSIPRouter..."
mysql -s -N $MYSQL_ROOT_USERNAME $MYSQL_ROOT_PASSWORD $MYSQL_KAM_DBNAME < ./cdrs.sql

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
