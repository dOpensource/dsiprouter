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
    local TABLES=(dsip_multidomain_mapping dsip_domain_mapping)

    printwarn "Adding/Replacing the tables needed for Domain Mapping within dSIPRouter..."

    # Check to see if table exists
    withRootDBConn --db="$KAM_DB_NAME" mysql -sN -e "select count(*) from ${TABLES[0]} limit 1" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        printwarn "The dSIPRouter tables ${TABLES[@]} already exists. Merging table data"
        (
            cat ${DSIP_PROJECT_DIR}/gui/modules/domain/domain_mapping.sql;
            withRootDBConn --db="$KAM_DB_NAME" mysqldump --single-transaction --skip-triggers --skip-add-drop-table --no-create-info \
            --insert-ignore ${TABLES[@]};
        ) | withRootDBConn --db="$KAM_DB_NAME" mysql
    else
        echo -e "Installing schema for Domain Mapping"
        withRootDBConn --db="$KAM_DB_NAME" mysql <${DSIP_PROJECT_DIR}/gui/modules/domain/domain_mapping.sql
    fi
}

function install {
    installSQL
    printdbg "Domain module installed"
}

function uninstall {
    printdbg "Domain module uninstalled"
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
