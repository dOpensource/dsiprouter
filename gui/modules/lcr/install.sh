#!/usr/bin/env bash
#set -x
ENABLED=0 # ENABLED=1 --> install, ENABLED=0 --> do nothing, ENABLED=-1 uninstall

#############################################################################
# This is now deprecated because it's now part of the core dSIPRouter install
# It will be removed in upcoming releases
#############################################################################


# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

function installSQL {
    # Check to see if the acc table or cdr tables are in use
    MERGE_DATA=0
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE -e "select count(*) from dsip_lcr limit 10" > /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        MERGE_DATA=1
    fi

    # Replace the dSIPRouter LCR tables and add some optional Kamailio stored procedures
    printwarn "Adding/Replacing the tables needed for LCR  within dSIPRouter..."
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE < ./gui/modules/lcr/lcr.sql

    if [ ${MERGE_DATA} -eq 0 ]; then
        printwarn "The dSIPRouter LCR Support (dsip_lcr) table already exists. Dumping table data"
        mysqldump --single-transaction --skip-triggers --skip-add-drop-table --no-create-info --insert-ignore \
            --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" ${MYSQL_KAM_DATABASE} dsip_lcr \
            | mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE
    fi
}

function install {
    installSQL
    # enable LCR routing in kamcfg
    enableKamailioConfigAttrib 'WITH_LCR' ${SYSTEM_KAMAILIO_CONFIG_FILE}
    printdbg "LCR module installed" ${SYSTEM_KAMAILIO_CONFIG_FILE}
}

function uninstall {
    # disable LCR routing in kamcfg
    disableKamailioConfigAttrib 'WITH_LCR'
    printdbg "LCR module uninstalled"
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
