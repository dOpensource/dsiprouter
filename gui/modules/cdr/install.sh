#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# ENABLED=1 --> install, ENABLED=0 --> do nothing, ENABLED=-1 uninstall
ENABLED=1

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function installSQL {
    # Check to see if the acc table or cdr tables are in use
    MERGE_DATA=0
    acc_row_count=$(mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        -e "select count(*) from acc limit 10" 2> /dev/null)
    if [ ${acc_row_count:-0} -gt 0 ]; then
        MERGE_DATA=1
    fi

    if [ ${MERGE_DATA} -eq 1 ]; then
        printwarn "The accounting table (acc) in Kamailio already exists. Merging table data"
        (cat ${DSIP_PROJECT_DIR}/gui/modules/cdr/cdrs.sql;
            mysqldump --single-transaction --skip-triggers --skip-add-drop-table --no-create-info --insert-ignore \
                --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" ${KAM_DB_NAME} dsip_lcr
        ) | mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME
    else
        # Replace the CDR tables and add some Kamailio stored procedures
        printwarn "Adding/Replacing the tables needed for CDR's within dSIPRouter..."
        mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME < ${DSIP_PROJECT_DIR}/gui/modules/cdr/cdrs.sql
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
