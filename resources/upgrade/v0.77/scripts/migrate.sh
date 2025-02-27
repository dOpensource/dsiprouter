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

DISTRO=$(getDistroName)
DISTRO_VER=$(getDistroVer)
DISTRO_MAJOR_VER=$(cut -d '.' -f 1 <<<"$DISTRO_VER")
DISTRO_MINOR_VER=$(cut -s -d '.' -f 2 <<<"$DISTRO_VER")
case "$DISTRO" in
debian)
    case "$DISTRO_VER" in
    12|11|10)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    9)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.5.7"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr9.5.5.1"}
        ;;
    esac
    ;;
centos)
    case "$DISTRO_VER" in
    8|9)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    7)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.7.6"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    esac
    ;;
amzn)
    case "$DISTRO_VER" in
    2)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.7.6"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr9.5.5.1"}
        ;;
    esac
    ;;
ubuntu)
    case "$DISTRO_VER" in
    24.04)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.4"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    22.04)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    20.04)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr9.5.5.1"}
        ;;
    esac
    ;;
rhel)
    case "$DISTRO_MAJOR_VER" in
    9)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    8)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr9.5.5.1"}
        ;;
    esac
    ;;
almalinux)
    case "$DISTRO_MAJOR_VER" in
    9)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    8)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    esac
    ;;
rocky)
    case "$DISTRO_MAJOR_VER" in
    9)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    8)
        NEW_KAM_VERSION=${NEW_KAM_VERSION:-"5.8.3"}
        NEW_RTPENGINE_VER=${NEW_RTPENGINE_VER:-"mr11.5.1.11"}
        ;;
    esac
    ;;
esac
if [[ -z "${NEW_KAM_VERSION}${NEW_RTPENGINE_VER}" ]]; then
    printerr 'unsupported OS version'
    exit 1
fi

printdbg 'retrieving current system settings'
# NOTE: some magic is being done here to reset specific settings next install
export PYTHON_CMD=${OLD_PROJECT_DIR}/venv/bin/python
DSIP_SYSTEM_CONFIG_DIR='/etc/dsiprouter'
DSIP_LIB_DIR='/var/lib/dsiprouter'
DSIP_CONFIG_FILE=${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
DSIP_KAMAILIO_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/kamailio/kamailio.cfg"
SYSTEM_KAMAILIO_CONFIG_DIR='/etc/kamailio'
SYSTEM_RTPENGINE_CONFIG_DIR='/etc/rtpengine'
export SET_ROOT_DB_USER=$(getConfigAttrib 'ROOT_DB_USER' ${DSIP_CONFIG_FILE})
export ROOT_DB_USER="$SET_ROOT_DB_USER"
export SET_ROOT_DB_PASS=$(decryptConfigAttrib 'ROOT_DB_PASS' ${DSIP_CONFIG_FILE})
export ROOT_DB_PASS="$SET_ROOT_DB_PASS"
export ROOT_DB_HOST=$(getConfigAttrib 'ROOT_DB_HOST' ${DSIP_CONFIG_FILE})
export ROOT_DB_PORT=$(getConfigAttrib 'ROOT_DB_PORT' ${DSIP_CONFIG_FILE})
export ROOT_DB_NAME=$(getConfigAttrib 'ROOT_DB_NAME' ${DSIP_CONFIG_FILE})
export KAM_DB_NAME=$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})
export SET_KAM_DB_HOST=$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})
export KAM_DB_HOST="$SET_KAM_DB_HOST"
export SET_KAM_DB_USER=$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})
export KAM_DB_USER="$SET_KAM_DB_USER"
export SET_KAM_DB_PASS=$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})
export KAM_DB_PASS="$SET_KAM_DB_PASS"
export SET_DSIP_API_TOKEN=$(decryptConfigAttrib 'DSIP_API_TOKEN' ${DSIP_CONFIG_FILE})
export DSIP_API_TOKEN="$SET_DSIP_API_TOKEN"
export SET_DSIP_MAIL_PASS=$(decryptConfigAttrib 'MAIL_PASSWORD' ${DSIP_CONFIG_FILE})
export MAIL_PASSWORD="$DSIP_MAIL_PASS"
export SET_DSIP_IPC_TOKEN=$(decryptConfigAttrib 'DSIP_IPC_PASS' ${DSIP_CONFIG_FILE})
export DSIP_IPC_PASS="$SET_DSIP_IPC_TOKEN"
export DSIP_LICENSE_STORE=$(getConfigAttrib 'DSIP_LICENSE_STORE' ${DSIP_CONFIG_FILE})


printdbg 'preparing for migration'
REINSTALL_KAMAILIO=0
REINSTALL_DSIPROUTER=0
REINSTALL_RTPENGINE=0
INSTALL_OPTS=()
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
    REINSTALL_KAMAILIO=1
    INSTALL_OPTS+=(-kam)
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
    REINSTALL_DSIPROUTER=1
    INSTALL_OPTS+=(-dsip)
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
    OLD_RTPENGINE_VER=$(rtpengine -v 2>&1 | awk '{print $2}' | cut -d '~' -f 2)
    if [[ "$OLD_RTPENGINE_VER" != "$NEW_RTPENGINE_VER" ]]; then
        REINSTALL_RTPENGINE=1
        INSTALL_OPTS+=(-rtp)
    fi
fi

printdbg 'backing up configs just in case the upgrade fails'
mkdir -p "$CURR_BACKUP_DIR"
mkdir -p ${CURR_BACKUP_DIR}/{opt/dsiprouter,var/lib/dsiprouter,etc/dsiprouter,etc/kamailio,etc/rtpengine,etc/systemd/system,lib/systemd/system,etc/default}
cp -afP ${OLD_PROJECT_DIR}/. ${CURR_BACKUP_DIR}/opt/dsiprouter/
cp -afP ${DSIP_LIB_DIR}/. ${CURR_BACKUP_DIR}/var/lib/dsiprouter/
cp -afP ${SYSTEM_KAMAILIO_CONFIG_DIR}/. ${CURR_BACKUP_DIR}/etc/kamailio/
cp -afP ${DSIP_SYSTEM_CONFIG_DIR}/. ${CURR_BACKUP_DIR}/etc/dsiprouter/
cp -afP ${SYSTEM_RTPENGINE_CONFIG_DIR}/. ${CURR_BACKUP_DIR}/etc/rtpengine/
cp -afP /etc/systemd/system/{dsiprouter,kamailio,rtpengine,dsip-init,mariadb}.service ${CURR_BACKUP_DIR}/etc/systemd/system/ 2>/dev/null
cp -afP /lib/systemd/system/{dsiprouter,kamailio,rtpengine,dsip-init,mariadb}.service ${CURR_BACKUP_DIR}/lib/systemd/system/ 2>/dev/null
cp -afP /etc/default/{kamailio,rtpengine}* ${CURR_BACKUP_DIR}/etc/default/
printdbg "files were backed up here: ${CURR_BACKUP_DIR}/"

# if the state files for the services to upgrade were there before
# and we fail, put them back so the system can recover
resetConfigsHandler() {
    printwarn 'upgrade failed, resetting system to previous state'

    if (( $REINSTALL_KAMAILIO == 1 )); then
        systemctl unmask kamailio.service
    fi
    if (( $REINSTALL_DSIPROUTER == 1 )); then
        systemctl unmask dsiprouter.service
    fi
    if (( $REINSTALL_RTPENGINE == 1 )); then
        systemctl unmask rtpengine.service
    fi

    cp -afP ${CURR_BACKUP_DIR}/etc/. /etc/
    cp -afP ${CURR_BACKUP_DIR}/lib/. /lib/
    cp -afP ${CURR_BACKUP_DIR}/opt/. /opt/
    cp -afP ${CURR_BACKUP_DIR}/var/. /var/
    systemctl daemon-reload

    if (( $REINSTALL_KAMAILIO == 1 )); then
        # automatically created in dsiprouter.sh when installKamailio() runs
        [[ -e ${CURR_BACKUP_DIR}/db.sql ]] && withRootDBConn mysql <${CURR_BACKUP_DIR}/db.sql
        [[ -e ${CURR_BACKUP_DIR}/user.sql ]] && withRootDBConn mysql <${CURR_BACKUP_DIR}/user.sql
    fi

    trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM
    exit 1
}
trap 'resetConfigsHandler $?' EXIT SIGHUP SIGINT SIGQUIT SIGTERM

# conditionally reinstalled
printdbg 'preparing service updates'
if (( $REINSTALL_KAMAILIO == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled
    rm -rf ${SRC_DIR}/kamailio
    rm -f "$DSIP_KAMAILIO_CONFIG_FILE"

    systemctl mask kamailio.service
fi
if (( $REINSTALL_DSIPROUTER == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dsiproutercliinstalled

    systemctl mask dsiprouter.service
fi
if (( $REINSTALL_RTPENGINE == 1 )); then
    rm -rf ${SRC_DIR}/rtpengine
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled

    systemctl mask rtpengine.service
fi

printdbg 'storing kamailio database data'
(
    withRootDBConn mysqldump --single-transaction --skip-opt --skip-triggers --no-create-db --no-create-info \
        --replace --complete-insert --hex-blob --skip-comments --databases "$KAM_DB_NAME"
) >${CURR_BACKUP_DIR}/data.sql

if (( $REINSTALL_DSIPROUTER == 1 )); then
    printdbg 'migrating dSIPRouter project files'
    cp -rf ${NEW_PROJECT_DIR}/. ${OLD_PROJECT_DIR}/
    export DSIP_PROJECT_DIR=${OLD_PROJECT_DIR}

    printdbg 'migrating dSIPRouter settings'
    (
        # magic bash hacking
        function exit() { :; }
        export -f exit
        source ${DSIP_PROJECT_DIR}/dsiprouter.sh &>/dev/null
        unset -f exit
        setStaticScriptSettings
        setDynamicScriptSettings
        # more magic environment munging
        dsiprouter configuredsip
        # the rest of the settings are configured during reinstall
    ) || {
        printerr 'Failed migrating dSIPRouter settings'
        exit 1
    }

    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.reposconfigured
    rm -f /lib/systemd/system/dsip-init.service
fi

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
    withRootDBConn --db="$KAM_DB_NAME" mysql <${DSIP_PROJECT_DIR}/resources/upgrade/v0.77/clear_defaults.sql &&
    withRootDBConn --db="$KAM_DB_NAME" mysql <${CURR_BACKUP_DIR}/data.sql || {
        printerr 'failed migrating kamailio database'
        exit 1
    }
fi

printdbg 'unmasking services'
if (( $REINSTALL_KAMAILIO == 1 )); then
    systemctl unmask kamailio.service
fi
if (( $REINSTALL_DSIPROUTER == 1 )); then
    systemctl unmask dsiprouter.service
fi
if (( $REINSTALL_RTPENGINE == 1 )); then
    systemctl unmask rtpengine.service
fi

if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
    printwarn 'kamailio service requires restarting'
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
    printwarn 'dsiprouter service requires restarting'
fi
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
    printwarn 'rtpengine service requires restarting'
fi

# make sure the resetConfigsHandler() is nerfed now that we are successful
trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM

pprint 'upgrade completed successfully'

exit 0
