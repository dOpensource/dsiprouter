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
    count=$(withRootDBConn --db="$KAM_DB_NAME" mysql -sN -e "select count(*) from dsip_dnid_enrich_lnp limit 1" 2> /dev/null)
    if [ ${count:-0} -gt 0 ]; then
        MERGE_DATA=1
    fi

    if [ ${MERGE_DATA} -eq 1 ]; then
	    printwarn "The table already exists. Merging table data"
	    (
	        cat ${DSIP_PROJECT_DIR}/gui/modules/dnid_enrichment/dnid_enrichment.sql;
            withRootDBConn --db="$KAM_DB_NAME" mysqldump --single-transaction --skip-triggers --skip-add-drop-table --no-create-info \
            --insert-ignore dsip_dnid_enrich_lnp
        ) | withRootDBConn --db="$KAM_DB_NAME" mysql
    else
        # Replace the api tables
        printwarn "Adding/Replacing the tables needed for DNID LNP Enrichment module within dSIPRouter..."
        withRootDBConn --db="$KAM_DB_NAME" mysql <${DSIP_PROJECT_DIR}/gui/modules/dnid_enrichment/dnid_enrichment.sql
    fi
}

function install {
    installSQL
    enableKamailioConfigAttrib 'WITH_DNID_LNP_ENRICHMENT' ${DSIP_KAMAILIO_CONFIG_FILE}

    systemctl restart kamailio
    if systemctl is-active --quiet kamailio; then
        printdbg "DNID LNP Enrichment module installed"
        return 0
    else
        printerr "Could not restart kamailio after module configuration"
        return 1
    fi
}

function uninstall {
    disableKamailioConfigAttrib 'WITH_DNID_LNP_ENRICHMENT' ${DSIP_KAMAILIO_CONFIG_FILE}

    systemctl restart kamailio
    if systemctl is-active --quiet kamailio; then
        printdbg "DNID LNP Enrichment module uninstalled"
        return 0
    else
        printerr "Could not restart kamailio after module configuration"
        return 1
    fi
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
