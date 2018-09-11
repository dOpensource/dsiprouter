#!/usr/bin/env bash
#set -x
ENABLED=1 # ENABLED=1 --> install, ENABLED=0 --> do nothing, ENABLED=-1 uninstall

function installSQL {
    # Check to see if the acc table or cdr tables are in use
    acc_row_count=$(mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE -e "select count(*) from acc limit 10")
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
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE < ./cdrs.sql

}

function install {
    installSQL
}

function main {
    if [[ ${ENABLED} -eq 1 ]]; then
        install
    elif [[ ${ENABLED} -eq -1 ]]; then
        uninstall
    else
        exit 0
    fi
}

main
