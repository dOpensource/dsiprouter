#!/usr/bin/env bash
#set -x
ENABLED=1 # ENABLED=1 --> install, ENABLED=0 --> do nothing, ENABLED=-1 uninstall

# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

function installSQL {
    # Check to see if the acc table or cdr tables are in use
    MERGE_DATA=0
    acc_row_count=$(mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE -e "select count(*) from acc limit 10")
    if [ ${acc_row_count:-0} -gt 0 ]; then
        MERGE_DATA=1
    fi

    # Replace the CDR tables and add some Kamailio stored procedures
    printwarn "Adding/Replacing the tables needed for CDR's within dSIPRouter..."
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE < ./gui/modules/cdr/cdrs.sql

    if [ ${MERGE_DATA} -eq 0 ]; then
        printwarn "The accounting table (acc) in Kamailio already exists. Merging table data"
        mysqldump --single-transaction --skip-triggers --skip-add-drop-table --no-create-info --insert-ignore \
            --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" ${MYSQL_KAM_DATABASE} dsip_lcr \
            | mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE
    fi
}

function install {
    installSQL
    printdbg "CDR module installed"
}

function uninstall {
    printdbg "CDR module uninstalled"
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
