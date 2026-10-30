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
    local CDR_DUMP_FILE

    # Check to see if the acc table or cdr tables are in use
    MERGE_DATA=0
    acc_row_count=$(withRootDBConn --db="$KAM_DB_NAME" mysql -sN -e "select count(*) from acc limit 10" 2> /dev/null)
    cdrs_row_count=$(withRootDBConn --db="$KAM_DB_NAME" mysql -sN -e "select count(*) from cdrs limit 10" 2> /dev/null)
    if [ ${acc_row_count:-0} -gt 0 ] || [ ${cdrs_row_count:-0} -gt 0 ]; then
        MERGE_DATA=1
    fi

    if [ ${MERGE_DATA} -eq 1 ]; then
        printwarn "The accounting table (acc) in Kamailio already exists. Merging table data"
        # the CDR data is dumped before cdrs.sql drops and recreates the tables, then restored into them
        # kept out of /tmp, which is often a small tmpfs and the CDR tables can be large
        mkdir -p /var/backups/dsiprouter &&
            CDR_DUMP_FILE=$(mktemp -p /var/backups/dsiprouter cdrs-merge.XXXXXXXX.sql) || return 1
        # the DB name is passed positionally, --db= would become mysqldump's --databases and treat acc / cdrs as DB names
        withRootDBConn mysqldump --single-transaction --skip-triggers --skip-add-drop-table --no-create-info \
            --complete-insert --insert-ignore "$KAM_DB_NAME" acc cdrs >"$CDR_DUMP_FILE" || {
            printerr "Could not back up the CDR tables, the CDR tables were not changed"
            rm -f "$CDR_DUMP_FILE"
            return 1
        }
        withRootDBConn --db="$KAM_DB_NAME" mysql <${DSIP_PROJECT_DIR}/gui/modules/cdr/cdrs.sql || {
            printerr "Could not update the CDR tables, the CDR data is backed up in ${CDR_DUMP_FILE}"
            return 1
        }
        withRootDBConn --db="$KAM_DB_NAME" mysql <"$CDR_DUMP_FILE" || {
            printerr "Could not restore the CDR data, it is backed up in ${CDR_DUMP_FILE}"
            return 1
        }
        rm -f "$CDR_DUMP_FILE"
    else
        # Replace the CDR tables and add some Kamailio stored procedures
        printwarn "Adding/Replacing the tables needed for CDR's within dSIPRouter..."
        withRootDBConn --db="$KAM_DB_NAME" mysql -sN <${DSIP_PROJECT_DIR}/gui/modules/cdr/cdrs.sql
    fi
}

function install {
    installSQL || return 1
    enableKamailioConfigAttrib 'WITH_CDRS' ${DSIP_KAMAILIO_CONFIG_FILE}
    # daily CDR retention / S3 archive job, it does nothing until a retention period is set
    cronRemove -u dsiprouter 'dsiprouter_cron.py cdr purge'
    cronAppend -u dsiprouter "30 2 * * * ${PYTHON_CMD} ${DSIP_PROJECT_DIR}/gui/dsiprouter_cron.py cdr purge"
    printdbg "CDR module installed"
}

function uninstall {
    disableKamailioConfigAttrib 'WITH_CDRS' ${DSIP_KAMAILIO_CONFIG_FILE}
    cronRemove -u dsiprouter 'dsiprouter_cron.py cdr purge'
    printdbg "CDR module uninstalled"
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
