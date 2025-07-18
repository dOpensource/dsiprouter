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

printdbg 'validating system configuration'
if ! dsiprouter licensemanager -check tag=DSIP_CORE; then
    printerr 'A DSIP_CORE license is required to use the auto upgrade feature'
    echo 'Consider supporting the hard working engineers maintaining this software if you would like to use this feature'
    exit 1
fi

printdbg 'retrieving current system settings'
export PYTHON_CMD=${OLD_PROJECT_DIR}/venv/bin/python
DSIP_SYSTEM_CONFIG_DIR='/etc/dsiprouter'
DSIP_CONFIG_FILE=${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
SYSTEM_KAMAILIO_CONFIG_DIR='/etc/kamailio'
export ROOT_DB_USER=$(getConfigAttrib 'ROOT_DB_USER' ${DSIP_CONFIG_FILE})
export ROOT_DB_PASS=$(decryptConfigAttrib 'ROOT_DB_PASS' ${DSIP_CONFIG_FILE})
export ROOT_DB_HOST=$(getConfigAttrib 'ROOT_DB_HOST' ${DSIP_CONFIG_FILE})
export ROOT_DB_PORT=$(getConfigAttrib 'ROOT_DB_PORT' ${DSIP_CONFIG_FILE})
export KAM_DB_NAME=$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})

printdbg 'preparing for migration'
export DSIP_PROJECT_DIR=${OLD_PROJECT_DIR}
UPDATE_KAMAILIO=0
UPDATE_DSIPROUTER=0
REQUIRED_RELOADS=()
RELOAD_CMD=(dsiprouter restart)
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
    UPDATE_KAMAILIO=1
    REQUIRED_RELOADS+=(kamailio)
    RELOAD_CMD+=(-kam)
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
    UPDATE_DSIPROUTER=1
    REQUIRED_RELOADS+=(dsiprouter)
    RELOAD_CMD+=(-dsip)
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.nginxinstalled" ]]; then
    UPDATE_NGINX=1
fi

printdbg 'backing up configs just in case the upgrade fails'
mkdir -p "$CURR_BACKUP_DIR"
mkdir -p ${CURR_BACKUP_DIR}/{opt/dsiprouter,etc/dsiprouter,etc/kamailio,etc/nginx}
cp -afP ${OLD_PROJECT_DIR}/. ${CURR_BACKUP_DIR}/opt/dsiprouter/
cp -afP ${SYSTEM_KAMAILIO_CONFIG_DIR}/. ${CURR_BACKUP_DIR}/etc/kamailio/
cp -afP /etc/nginx/. ${CURR_BACKUP_DIR}/etc/nginx/
printdbg "files were backed up here: ${CURR_BACKUP_DIR}/"

# revert the changes we made on failure
resetConfigsHandler() {
    printwarn 'upgrade failed, resetting system to previous state'

    cp -afP ${CURR_BACKUP_DIR}/etc/. /etc/
    cp -afP ${CURR_BACKUP_DIR}/opt/. /opt/

    if (( $UPDATE_KAMAILIO == 1 )); then
        # DSIP_PROJECT_DIR may be the old or new project based on when this fails
        [[ -e "${DSIP_PROJECT_DIR}/resources/upgrade/v0.78/dsip-fwd-old.sql" ]] && {
            withRootDBConn --db="$KAM_DB_NAME" mysql <${DSIP_PROJECT_DIR}/resources/upgrade/v0.78/dsip-fwd-old.sql
            kamcmd htable.reload prefix_to_route
        }
    fi

    trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM
    exit 1
}
trap 'resetConfigsHandler $?' EXIT SIGHUP SIGINT SIGQUIT SIGTERM

# we want the project files updated first
if (( $UPDATE_DSIPROUTER == 1 )); then
    printdbg 'migrating dSIPRouter project files'
    cp -rf ${NEW_PROJECT_DIR}/. ${OLD_PROJECT_DIR}/
    export DSIP_PROJECT_DIR=${NEW_PROJECT_DIR}

    printdbg 'migrating dSIPRouter settings'
    setConfigAttrib 'VERSION' '0.78' ${DSIP_CONFIG_FILE} -q || {
        printerr 'Failed migrating dSIPRouter settings'
        exit 1
    }

    printdbg 'regenerating dSIPRouter documentation'
    (
        cd ${DSIP_PROJECT_DIR}/docs &&
        make -j $(nproc) html
    ) || {
        printerr 'Failed generating documentation'
        exit 1
    }

    printdbg 'syncing fusionpbx domains'
    sudo -u dsiprouter ${PYTHON_CMD} ${DSIP_PROJECT_DIR}/gui/dsiprouter_cron.py fusionpbx sync || {
        printerr 'Failed syncing fusionpbx domains'
        exit 1
    }
fi

# NOTE: no change in dsip_lib.sh so we do not need to source the new one

if (( $UPDATE_KAMAILIO == 1 )); then
    printdbg 'updating kamailio configuration'
    dsiprouter configurekam
    kamailio -c >/dev/null || {
        printerr 'Failed migrating kamailio configuration to newer version'
        exit 1
    }
    withRootDBConn --db="$KAM_DB_NAME" mysql <${DSIP_PROJECT_DIR}/resources/upgrade/v0.78/dsip-fwd-new.sql || {
        printerr 'Failed migrating kamailio database'
        exit 1
    }
fi

if (( $UPDATE_NGINX == 1 )); then
    printdbg 'updating nginx configuration'
    dsiprouter chown -nginx
fi

if (( $UPDATE_KAMAILIO == 1 || $UPDATE_DSIPROUTER == 1 )); then
    printwarn 'The following services require restarting:'
    for SVC in ${REQUIRED_RELOADS[@]}; do
        echo "- $SVC"
    done
    echo ''
    echo "To reload these services do $(printwarn -n ONE) of the following:"
    echo '- press the "Reload" button in the GUI and then click "Reload dSIPRouter"'
    echo '- run this command in the CLI "'${RELOAD_CMD[@]}'"'
    echo ''
fi

# make sure the resetConfigsHandler() is nerfed now that we are successful
trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM

pprint 'upgrade completed successfully'

exit 0
