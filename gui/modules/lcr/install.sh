#!/usr/bin/env bash
#set -x
ENABLED=1 # ENABLED=1 --> install, ENABLED=0 --> do nothing, ENABLED=-1 uninstall

function installSQL {
    # Check to see if the acc table or cdr tables are in use
    MERGE_DATA=0
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE -e "select count(*) from dsip_lcr limit 10" > /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        MERGE_DATA=1
    fi

    # Replace the dSIPRouter LCR tables and add some optional Kamailio stored procedures
    echo "Adding/Replacing the tables needed for LCR  within dSIPRouter..."
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE < ./gui/modules/lcr/lcr.sql

    if [ ${MERGE_DATA} -eq 0 ]; then
        echo -e "The dSIPRouter LCR Support (dsip_lcr) table already exists. Dumping table data"
        mysqldump --single-transaction --skip-triggers --skip-add-drop-table --no-create-info --insert-ignore \
            --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" ${MYSQL_KAM_DATABASE} dsip_lcr \
            | mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE
    fi
}

function install {
    installSQL
    echo "LCR module installed"
}

function uninstall {
    echo "LCR module uninstalled"
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
