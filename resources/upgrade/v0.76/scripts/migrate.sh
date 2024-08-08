#!/usr/bin/env bash

(( ${DEBUG:-0} == 1 )) && set -x

# where the new project files were downloaded
NEW_PROJECT_DIR=${NEW_PROJECT_DIR:-/tmp/dsiprouter}
# project dir where previous repo was located
OLD_PROJECT_DIR=${DSIP_PROJECT_DIR:-/opt/dsiprouter}
# the backup directory set by dsiprouter.sh
CURR_BACKUP_DIR=${CURR_BACKUP_DIR:-"/var/backups/dsiprouter/$(date '+%s')"}
# system config files for dsiprouter
DSIP_SYSTEM_CONFIG_DIR='/etc/dsiprouter'

# import dsip_lib utility / shared functions (no changes to func definitions in this revision)
. ${OLD_PROJECT_DIR}/dsiprouter/dsip_lib.sh

# make sure the updates are downloaded and in the correct location
[[ ! -e "$NEW_PROJECT_DIR" ]] && {
    printerr 'could not find repo to upgrade from'
    echo "expected updated repo to be here: $NEW_PROJECT_DIR"
    exit 1
}

printdbg 'preparing new repo migration'
cp -af ${OLD_PROJECT_DIR}/venv/. ${NEW_PROJECT_DIR}/venv/


printdbg 'validating system configuration'
if ! env DSIP_PROJECT_DIR="$NEW_PROJECT_DIR" \
DSIP_SYSTEM_CONFIG_DIR="$DSIP_SYSTEM_CONFIG_DIR" \
${NEW_PROJECT_DIR}/dsiprouter.sh licensemanager -check tag=DSIP_CORE; then
    printerr 'A DSIP_CORE license is required to use the auto upgrade feature'
    echo 'Consider supporting the hard working engineers maintaining this software if you would like to use this feature'
    exit 1
fi

printdbg 'backing up configs just in case the upgrade fails'
mkdir -p "$CURR_BACKUP_DIR"
# TODO: make the destination paths use our static variables as well
mkdir -p ${CURR_BACKUP_DIR}/{opt/dsiprouter,etc/dsiprouter,etc/kamailio}
cp -af ${OLD_PROJECT_DIR}/. ${CURR_BACKUP_DIR}/opt/dsiprouter/
cp -af ${SYSTEM_KAMAILIO_CONFIG_DIR}/. ${CURR_BACKUP_DIR}/etc/kamailio/
cp -af ${DSIP_SYSTEM_CONFIG_DIR}/. ${CURR_BACKUP_DIR}/etc/dsiprouter/
printdbg "files were backed up here: ${CURR_BACKUP_DIR}/"

updateDsiprouterCli() {
    FROM_PROJECT_DIR="$1"
    cp -f ${FROM_PROJECT_DIR}/dsiprouter/dsip_completion.sh /etc/bash_completion.d/dsiprouter
    cp -f ${FROM_PROJECT_DIR}/resources/man/dsiprouter.1 /usr/share/man/man1/ &&
    gzip -f /usr/share/man/man1/dsiprouter.1 &&
    mandb
}

# if the state files for the services to upgrade were there before
# and we fail, put them back so the system can recover
resetConfigsHandler() {
    printwarn 'upgrade failed, resetting system to previous state'

    cp -af ${CURR_BACKUP_DIR}/etc/. /etc/
    cp -af ${CURR_BACKUP_DIR}/opt/. /opt/

    updateDsiprouterCli "$OLD_PROJECT_DIR"

    dsiprouter configurekam

    trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM
    exit 1
}
trap 'resetConfigsHandler $?' EXIT SIGHUP SIGINT SIGQUIT SIGTERM

printdbg 'migrating dSIPRouter project files'
cp -rf ${NEW_PROJECT_DIR}/. ${OLD_PROJECT_DIR}/
updateDsiprouterCli "$NEW_PROJECT_DIR"
dsiprouter configurekam

if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
    printwarn 'kamailio service requires restarting'
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
    printwarn 'dsiprouter service requires restarting'
fi

# make sure the resetConfigsHandler() is nerfed now that we are successful
trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM

pprint 'upgrade completed successfully'

exit 0
