#!/usr/bin/env bash

(( ${DEBUG:-0} == 1 )) && set -x

# where the new project files were downloaded
NEW_PROJECT_DIR=${NEW_PROJECT_DIR:-/tmp/dsiprouter}
# whether or not this was called from the GUI
RUN_FROM_GUI=${RUN_FROM_GUI:-0}
# the backup directory set by dsiprouter.sh
CURR_BACKUP_DIR=${CURR_BACKUP_DIR:-"/var/backups/dsiprouter/$(date '+%s')"}

# set project dir where previous repo was located
export DSIP_PROJECT_DIR='/opt/dsiprouter'
# import dsip_lib utility / shared functions (we are using old functions on purpose here)
# WARNING: from here on we are explicitly using the OLD definitions of the dsip_lib funcs
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

# make sure the updates are downloaded and in the correct location
[[ ! -e "$NEW_PROJECT_DIR" ]] && {
    printerr 'could not find repo to upgrade from'
    echo "expected updated repo to be here: $NEW_PROJECT_DIR"
    exit 1
}

printdbg 'retrieving system info'
export DISTRO=$(getDistroName)
export DISTRO_VER=$(getDistroVer)
export DISTRO_MAJOR_VER=$(cut -d '.' -f 1 <<<"$DISTRO_VER")
export DISTRO_MINOR_VER=$(cut -s -d '.' -f 2 <<<"$DISTRO_VER")

printdbg 'validating OS support'
if [[ "$(getDistroName)" == 'debian' && "$(getDistroVer)" == "9" ]]; then
    printerr 'debian stretch is not supported in this version of dSIPRouter'
    echo 'upgrade your system to a supported version of debian first'
    echo 'for more information see: https://dsiprouter.readthedocs.io/en/latest/upgrading.html'
    exit 1
fi

printdbg 'retrieving current system settings'
# NOTE: some magic is being done here to reset specific settings next install
export PYTHON_CMD=python3
DSIP_SYSTEM_CONFIG_DIR='/etc/dsiprouter'
DSIP_LIB_DIR='/var/lib/dsiprouter'
DSIP_CONFIG_FILE=${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
DSIP_KAMAILIO_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/kamailio/kamailio.cfg"
SYSTEM_KAMAILIO_CONFIG_DIR='/etc/kamailio'
SYSTEM_RTPENGINE_CONFIG_DIR='/etc/rtpengine'
export ROOT_DB_PASS=$(decryptConfigAttrib 'ROOT_DB_PASS' ${DSIP_CONFIG_FILE})
export ROOT_DB_HOST=$(getConfigAttrib 'ROOT_DB_HOST' ${DSIP_CONFIG_FILE})
export ROOT_DB_PORT=$(getConfigAttrib 'ROOT_DB_PORT' ${DSIP_CONFIG_FILE})
export ROOT_DB_NAME=$(getConfigAttrib 'ROOT_DB_NAME' ${DSIP_CONFIG_FILE})
export KAM_DB_NAME=$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})
export SET_KAM_DB_HOST=$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})
export KAM_DB_HOST="$SET_KAM_DB_HOST"
export KAM_DB_USER=$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})
export SET_KAM_DB_PASS=$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})
export KAM_DB_PASS="$SET_KAM_DB_PASS"
export SET_DSIP_API_TOKEN=$(decryptConfigAttrib 'DSIP_API_TOKEN' ${DSIP_CONFIG_FILE})
export DSIP_API_TOKEN="$SET_DSIP_API_TOKEN"
export SET_DSIP_MAIL_PASS=$(decryptConfigAttrib 'MAIL_PASSWORD' ${DSIP_CONFIG_FILE})
export MAIL_PASSWORD="$DSIP_MAIL_PASS"
export SET_DSIP_IPC_TOKEN=$(decryptConfigAttrib 'DSIP_IPC_PASS' ${DSIP_CONFIG_FILE})
export DSIP_IPC_PASS="$SET_DSIP_IPC_TOKEN"
DSIP_CORE_LICENSE=$(decryptConfigAttrib 'DSIP_CORE_LICENSE' ${DSIP_CONFIG_FILE} | dd if=/dev/stdin of=/dev/stdout bs=1 count=32 2>/dev/null)
DSIP_STIRSHAKEN_LICENSE=$(decryptConfigAttrib 'DSIP_STIRSHAKEN_LICENSE' ${DSIP_CONFIG_FILE} | dd if=/dev/stdin of=/dev/stdout bs=1 count=32 2>/dev/null)
DSIP_TRANSNEXUS_LICENSE=$(decryptConfigAttrib 'DSIP_TRANSNEXUS_LICENSE' ${DSIP_CONFIG_FILE} | dd if=/dev/stdin of=/dev/stdout bs=1 count=32 2>/dev/null)
DSIP_MSTEAMS_LICENSE=$(decryptConfigAttrib 'DSIP_MSTEAMS_LICENSE' ${DSIP_CONFIG_FILE} | dd if=/dev/stdin of=/dev/stdout bs=1 count=32 2>/dev/null)

printdbg 'validating system system configuration'
if [[ -z "$DSIP_CORE_LICENSE" ]]; then
    printerr 'A DSIP_CORE license is required to use the auto upgrade feature'
    echo 'Consider supporting the hard working engineers maintaining this software if you would like to use this feature'
    exit 1
fi


printdbg 'preparing for migration'
REINSTALL_DNSMASQ=0
REINSTALL_NGINX=0
REINSTALL_KAMAILIO=0
REINSTALL_DSIPROUTER=0
REINSTALL_RTPENGINE=0
INSTALL_OPTS=()
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled" ]]; then
    REINSTALL_DNSMASQ=1
    INSTALL_OPTS+=(-dns)
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.nginxinstalled" ]]; then
    REINSTALL_NGINX=1
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
    REINSTALL_KAMAILIO=1
    INSTALL_OPTS+=(-kam)
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
    REINSTALL_DSIPROUTER=1
    INSTALL_OPTS+=(-dsip)
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
    REINSTALL_RTPENGINE=1
    INSTALL_OPTS+=(-rtp)
fi

printdbg 'backing up configs just in case the upgrade fails'
mkdir -p $CURR_BACKUP_DIR
# TODO: make the destination paths use our static variables as well
mkdir -p ${CURR_BACKUP_DIR}/{opt/dsiprouter,var/lib/dsiprouter,etc/dsiprouter,etc/kamailio,etc/rtpengine,etc/systemd/system,lib/systemd/system,etc/default}
#    mkdir -p ${CURR_BACKUP_DIR}/{var/lib/mysql,${HOME}}
cp -af ${DSIP_PROJECT_DIR}/. ${CURR_BACKUP_DIR}/opt/dsiprouter/
cp -af ${DSIP_LIB_DIR}/. ${CURR_BACKUP_DIR}/var/lib/dsiprouter/
cp -af ${SYSTEM_KAMAILIO_CONFIG_DIR}/. ${CURR_BACKUP_DIR}/etc/kamailio/
cp -af ${DSIP_SYSTEM_CONFIG_DIR}/. ${CURR_BACKUP_DIR}/etc/dsiprouter/
cp -af ${SYSTEM_RTPENGINE_CONFIG_DIR}/. ${CURR_BACKUP_DIR}/etc/rtpengine/
#    cp -af /var/lib/mysql/. ${CURR_BACKUP_DIR}/var/lib/mysql/
#    cp -af /etc/my.cnf ${CURR_BACKUP_DIR}/etc/ 2>/dev/null
#    cp -af /etc/mysql/. ${CURR_BACKUP_DIR}/etc/mysql/
#    cp -af ${HOME}/.my.cnf ${CURR_BACKUP_DIR}/${HOME}/ 2>/dev/null
cp -af /etc/dnsmasq.conf ${CURR_BACKUP_DIR}/etc/
cp -af /etc/systemd/system/{nginx,dsiprouter,dnsmasq,kamailio,rtpengine,dsip-init,mariadb}.service ${CURR_BACKUP_DIR}/etc/systemd/system/ 2>/dev/null
cp -af /lib/systemd/system/{nginx,dsiprouter,dnsmasq,kamailio,rtpengine,dsip-init,mariadb}.service ${CURR_BACKUP_DIR}/lib/systemd/system/ 2>/dev/null
cp -af /etc/default/{kamailio,rtpengine}* ${CURR_BACKUP_DIR}/etc/default/
printdbg "files were backed up here: ${CURR_BACKUP_DIR}/"

# shim any functions that would be missing from older versions
declare -F withRootDBConn >/dev/null || {
    function withRootDBConn() {
        local TMP CMD
        local CONN_OPTS=()

        case "$1" in
            --db=*)
                TMP=$(cut -d '=' -f 2- <<<"$1")
                [[ -n "$TMP" ]] && CONN_OPTS+=( "--database=${TMP}" )
                shift
                CMD="$1"
                shift
                ;;
            *)
                CMD="$1"
                shift
                if [[ "$CMD" == "mysql" ]]; then
                    [[ -n "$ROOT_DB_NAME" ]] && CONN_OPTS+=( "--database=${ROOT_DB_NAME}" )
                fi
                ;;
        esac

        [[ -n "$ROOT_DB_HOST" ]] && CONN_OPTS+=( "--host=${ROOT_DB_HOST}" )
        [[ -n "$ROOT_DB_PORT" ]] && CONN_OPTS+=( "--port=${ROOT_DB_PORT}" )
        [[ -n "$ROOT_DB_USER" ]] && CONN_OPTS+=( "--user=${ROOT_DB_USER}" )
        [[ -n "$ROOT_DB_PASS" ]] && CONN_OPTS+=( "--password=${ROOT_DB_PASS}" )

        if [[ -p /dev/stdin ]]; then
            ${CMD} "${CONN_OPTS[@]}" "$@" </dev/stdin
        else
            ${CMD} "${CONN_OPTS[@]}" "$@"
        fi
        return $?
    }
}

# removes the old licenses from the database dump so we can re-add them in the new format
filterLicenseFromDataDump() {
    perl -pe 's%(INSERT .*?INTO `dsip_settings` VALUES \()(.*?)[^,]*?,[^,]*?,[^,]*?,[^,]*?(\)\;)%\1\2'"'BQAAAAA='"'\3%g' </dev/stdin
}

# if the state files for the services to upgrade were there before
# and we fail, put them back so the system can recover
resetConfigsHandler() {
    printwarn 'upgrade failed, resetting system to previous state'

    if (( $REINSTALL_NGINX == 1 )); then
        systemctl unmask nginx.service
    fi
    if (( $REINSTALL_KAMAILIO == 1 )); then
        systemctl unmask kamailio.service
    fi
    if (( $REINSTALL_DSIPROUTER == 1 )); then
        systemctl unmask dsiprouter.service
    fi
    if (( $REINSTALL_RTPENGINE == 1 )); then
        systemctl unmask rtpengine.service
    fi

    cp -af ${CURR_BACKUP_DIR}/etc/. /etc/
    cp -af ${CURR_BACKUP_DIR}/lib/. /lib/
    cp -af ${CURR_BACKUP_DIR}/opt/. /opt/
    cp -af ${CURR_BACKUP_DIR}/var/. /var/
    systemctl daemon-reload

    if (( $REINSTALL_KAMAILIO == 1 )); then
        # automatically created in dsiprouter.sh when installKamailio() runs
        [[ -e ${CURR_BACKUP_DIR}/db.sql ]] && withRootDBConn mysql <${CURR_BACKUP_DIR}/db.sql
        [[ -e ${CURR_BACKUP_DIR}/user.sql ]] && withRootDBConn mysql <${CURR_BACKUP_DIR}/user.sql
    fi

    # not included in the restart() function from dsiprouter.sh
    # so we always restart to get config changes
    if (( $REINSTALL_DNSMASQ == 1 )); then
        systemctl restart dnsmasq
    fi

    if (( $RUN_FROM_GUI == 0 )); then
        if (( $REINSTALL_NGINX == 1 )); then
            systemctl restart nginx
        fi
        if (( $REINSTALL_KAMAILIO == 1 )); then
            systemctl restart kamailio
        fi
        if (( $REINSTALL_DSIPROUTER == 1 )); then
            systemctl restart dsiprouter
        fi
        if (( $REINSTALL_RTPENGINE == 1 )); then
            systemctl restart rtpengine
        fi
    fi

    trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM
    exit 1
}
trap 'resetConfigsHandler $?' EXIT SIGHUP SIGINT SIGQUIT SIGTERM

# conditionally reinstalled
printdbg 'masking services'
if (( $REINSTALL_DNSMASQ == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled

    # dnsmasq is not masked, we want it to restart during the install process
fi
if (( $REINSTALL_NGINX == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.nginxinstalled

    if [[ -f /etc/systemd/system/nginx.service ]]; then
        rm -f /etc/systemd/system/nginx.service
    fi

    systemctl mask nginx.service
fi
if (( $REINSTALL_KAMAILIO == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled
    rm -rf ${SRC_DIR}/kamailio
    rm -f "$DSIP_KAMAILIO_CONFIG_FILE"

    if [[ -f /etc/systemd/system/kamailio.service ]]; then
        rm -f /etc/systemd/system/kamailio.service
    fi

    systemctl mask kamailio.service
fi
if (( $REINSTALL_DSIPROUTER == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled

    systemctl mask dsiprouter.service
fi
if (( $REINSTALL_RTPENGINE == 1 )); then
    rm -rf ${SRC_DIR}/rtpengine
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled

    if [[ -f /etc/systemd/system/rtpengine.service ]]; then
        rm -f /etc/systemd/system/rtpengine.service
    fi

    systemctl mask rtpengine.service
fi

printdbg 'storing kamailio database data'
(
    withRootDBConn mysqldump --single-transaction --skip-opt --skip-triggers --no-create-db --no-create-info \
        --insert-ignore --hex-blob --skip-comments --databases "$KAM_DB_NAME"
) >${CURR_BACKUP_DIR}/data.sql

printdbg 'migrating dSIPRouter project files'
cp -rf ${NEW_PROJECT_DIR}/. ${DSIP_PROJECT_DIR}/
cd ${DSIP_PROJECT_DIR}/

# source the new dsip_lib functions
# WARNING: from here on we are explicitly using the NEW definitions of the dsip_lib funcs
# NOTE: resetConfigsHandler() above will still use the new definitions (lazy loading)
export PYTHON_CMD="${DSIP_PROJECT_DIR}/venv/bin/python"
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

printdbg 'upgrading services'
# we clear environment here to make sure we get new static settings on install
env -i CURR_BACKUP_DIR="$CURR_BACKUP_DIR" HOME="$HOME" LANG="$LANG" LANGUAGE="$LANGUAGE" LC_ALL="$LC_ALL" PATH="$PATH" PWD="$PWD" \
    ${DSIP_PROJECT_DIR}/dsiprouter.sh install ${INSTALL_OPTS[@]}

if (( $? != 0 )); then
    printerr 'failed upgrading services'
    exit 1
fi

if (( $REINSTALL_KAMAILIO == 1 )); then
    printdbg 'migrating kamailio database'
    withRootDBConn --db="$KAM_DB_NAME" mysql <${CURR_BACKUP_DIR}/user.sql &&
    withRootDBConn --db="$KAM_DB_NAME" mysql <${DSIP_PROJECT_DIR}/resources/upgrade/v0.75/clear_defaults.sql &&
    withRootDBConn --db="$KAM_DB_NAME" mysql <${DSIP_PROJECT_DIR}/resources/upgrade/v0.75/pre_import_data.sql &&
    filterLicenseFromDataDump <${CURR_BACKUP_DIR}/data.sql | withRootDBConn --db="$KAM_DB_NAME" mysql &&
    withRootDBConn --db="$KAM_DB_NAME" mysql <${DSIP_PROJECT_DIR}/resources/upgrade/v0.75/migrate_data.sql || {
        printerr 'failed migrating kamailio database'
        exit 1
    }
fi

if (( $REINSTALL_DSIPROUTER == 1 )); then
    printdbg 'migrating dSIPRouter settings'
    (
        # magic bash hacking
        function exit() { :; }
        export -f exit
        source ${CURR_BACKUP_DIR}/opt/dsiprouter/dsiprouter.sh
        unset -f exit
        setStaticScriptSettings
        setDynamicScriptSettings
        # more magic environment munging
        dsiprouter configuredsip
    ) &&
    setConfigAttrib 'VERSION' '0.75' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py -q &&
    ${PYTHON_CMD} <<EOPY || { printerr 'Failed migrating dSIPRouter settings'; exit 1; }
import sys
sys.path = [*['${DSIP_SYSTEM_CONFIG_DIR}/gui', '${DSIP_PROJECT_DIR}/gui'], *sys.path[1:]]
from database import updateDsipSettingsTable
from shared import updateConfig
from modules.api.licensemanager.classes import WoocommerceLicense
import settings

keys = [
    "$DSIP_CORE_LICENSE",
    "$DSIP_STIRSHAKEN_LICENSE",
    "$DSIP_TRANSNEXUS_LICENSE",
    "$DSIP_MSTEAMS_LICENSE"
]
for k in keys:
    if len(k) == 0:
        continue

    lc = WoocommerceLicense(license_key=lc_key)
    settings.DSIP_LICENSE_STORE[str(lc.id)] = lc.encrypt()
else:
    if keys[0] == '':
        sys.exit(1)
    if not keys[0].active:
        sys.exit(1)
if settings.LOAD_SETTINGS_FROM == 'db':
    updateDsipSettingsTable({'DSIP_LICENSE_STORE': settings.DSIP_LICENSE_STORE})
updateConfig(settings, {'DSIP_LICENSE_STORE': settings.DSIP_LICENSE_STORE}, hot_reload=True)
EOPY

printdbg 'unmasking services'
if (( $REINSTALL_NGINX == 1 )); then
    systemctl unmask nginx.service
fi
if (( $REINSTALL_KAMAILIO == 1 )); then
    systemctl unmask kamailio.service
fi
if (( $REINSTALL_DSIPROUTER == 1 )); then
    systemctl unmask dsiprouter.service
fi
if (( $REINSTALL_RTPENGINE == 1 )); then
    systemctl unmask rtpengine.service
fi

if (( $RUN_FROM_GUI == 0 )); then
    printdbg 'restarting services'
    if (( $REINSTALL_NGINX == 1 )); then
        systemctl restart nginx
        if ! systemctl is-active -q nginx; then
            printerr 'could not start nginx service'
            exit 1
        fi
    fi
    if (( $REINSTALL_KAMAILIO == 1 )); then
        systemctl restart kamailio
        if ! systemctl is-active -q kamailio; then
            printerr 'could not start kamailio service'
            exit 1
        fi
    fi
    if (( $REINSTALL_DSIPROUTER == 1 )); then
        systemctl restart dsiprouter
        if ! systemctl is-active -q dsiprouter; then
            printerr 'could not start dsiprouter service'
            exit 1
        fi
    fi
    if (( $REINSTALL_RTPENGINE == 1 )); then
        systemctl restart rtpengine
        if ! systemctl is-active -q rtpengine; then
            printerr 'could not start rtpengine service'
            exit 1
        fi
    fi
else
    printwarn 'running from the GUI, some services require restarting'
fi

# make sure the resetConfigsHandler() is nerfed now that we are successful
trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM

pprint 'upgrade completed successfully'

exit 0
