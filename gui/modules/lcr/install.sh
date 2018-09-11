#!/usr/bin/env bash
#set -x
ENABLED=1 # ENABLED=1 --> install, ENABLED=0 --> do nothing, ENABLED=-1 uninstall

function installSQL {
    # Check to see if the acc table or cdr tables are in use
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE -e "select count(*) from dsip_lcr limit 10" > /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        echo -e "The dSIPRouter LCR Support (dsip_lcr)  table already exists.  Please backup this table before moving forward if you want the data."
        echo -e "Would you like to install the FusionPBX LCR module now [y/n]:\c"
        read ANSWER
        if [ "$ANSWER" == "n" ]; then
            return
        fi
    fi

    # Replace the dSIPRouter LCR tables and add some optional Kamailio stored procedures
    echo "Adding/Replacing the tables needed for LCR  within dSIPRouter..."
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE < ./gui/modules/lcr/lcr.sql
}

function install {
    installSQL
}

function uninstall {
    echo ""
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
