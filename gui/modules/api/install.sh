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
    count=$(withRootDBConn --db="$KAM_DB_NAME" mysql -sN -e "select count(*) from dsip_endpoint_lease limit 10" 2> /dev/null)
    if [ ${count:-0} -gt 0 ]; then
        MERGE_DATA=1
    fi

    if [ ${MERGE_DATA} -eq 1 ]; then
	    printwarn "The endpoint lease table (dsip_endpoint_lease) in Kamailio already exists. Merging table data"
	    (
	        cat ${DSIP_PROJECT_DIR}/gui/modules/api/api.sql;
            withRootDBConn --db="$KAM_DB_NAME" mysqldump --single-transaction --skip-triggers --skip-add-drop-table \
                --no-create-info --insert-ignore dsip_endpoint_lease
        ) | withRootDBConn --db="$KAM_DB_NAME" mysql
    else
        # Replace the api tables
        printwarn "Adding/Replacing the tables needed for API module within dSIPRouter..."
        withRootDBConn --db="$KAM_DB_NAME" mysql -sN <${DSIP_PROJECT_DIR}/gui/modules/api/api.sql
    fi
}

function install {
    installSQL
    cronAppend "*/1 * * * * ${PYTHON_CMD} ${DSIP_PROJECT_DIR}/gui/dsiprouter_cron.py api cleanleases"
    printdbg "API module installed"
}

function uninstall {
    printdbg "API module uninstalled"
}

function main {
    if [[ ${ENABLED} -eq 1 ]]; then
        install && exit 0 || exit 1
    elif [[ ${ENABLED} -eq -1 ]]; then
        uninstall && exit 0 || exit 1
    else
        exit 0
    fi
}

main
