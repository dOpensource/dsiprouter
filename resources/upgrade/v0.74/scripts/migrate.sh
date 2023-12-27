#!/usr/bin/env bash

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
DSIP_CONFIG_FILE=${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
DSIP_KAMAILIO_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/kamailio/kamailio.cfg"
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
export DSIP_IPC_PASS="$SET_DSIP_API_TOKEN"
export SET_DSIP_MAIL_PASS=$(decryptConfigAttrib 'MAIL_PASSWORD' ${DSIP_CONFIG_FILE})
export MAIL_PASSWORD="$DSIP_MAIL_PASS"
export SET_DSIP_IPC_TOKEN=$(decryptConfigAttrib 'DSIP_IPC_PASS' ${DSIP_CONFIG_FILE})
export DSIP_IPC_PASS="$SET_DSIP_IPC_TOKEN"

printdbg 'preparing for migration'
REINSTALL_DNSMASQ=0
REINSTALL_NGINX=0
REINSTALL_KAMAILIO=0
REINSTALL_DSIPROUTER=0
REINSTALL_RTPENGINE=0
INSTALL_OPTS=()
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled" ]]; then
    REINSTALL_DNSMASQ=1
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
mkdir -p $CURR_BACKUP_DIR

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

    cp -af ${CURR_BACKUP_DIR}/opt/. /etc/
    cp -af ${CURR_BACKUP_DIR}/opt/. /lib/
    cp -af ${CURR_BACKUP_DIR}/opt/. /opt/
    cp -af ${CURR_BACKUP_DIR}/opt/. /var/
    systemctl daemon-reload

    if (( $REINSTALL_KAMAILIO == 1 )); then
        # automatically created in dsiprouter.sh when installKamailio() runs
        [[ -e ${CURR_BACKUP_DIR}/db.sql ]] &&
        withRootDBConn mysql <${CURR_BACKUP_DIR}/db.sql &&
        withRootDBConn mysql <${CURR_BACKUP_DIR}/user.sql
    fi

    # not included in the restrt() function from dsiprouter.sh
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
        mv -f /etc/systemd/system/nginx.service /lib/systemd/system/nginx.service
        systemctl daemon-reload
    fi

    systemctl mask nginx.service
fi
if (( $REINSTALL_KAMAILIO == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled
    rm -rf ${SRC_DIR}/kamailio
    rm -f "$DSIP_KAMAILIO_CONFIG_FILE"

    systemctl mask kamailio.service
fi
if (( $REINSTALL_DSIPROUTER == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled

    systemctl mask dsiprouter.service
fi
if (( $REINSTALL_RTPENGINE == 1 )); then
    rm -rf ${SRC_DIR}/rtpengine
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled

    systemctl mask rtpengine.service
fi

printdbg 'migrating dSIPRouter project files'
cp -rf ${NEW_PROJECT_DIR}/. ${DSIP_PROJECT_DIR}/
rm -rf ${NEW_PROJECT_DIR}
cd ${DSIP_PROJECT_DIR}/

# source the new dsip_lib functions
# WARNING: from here on we are explicitly using the NEW definitions of the dsip_lib funcs
# NOTE: resetConfigsHandler() above will still use the new definitions (lazy loading)
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

printdbg 'upgrading services'
${DSIP_PROJECT_DIR}/dsiprouter.sh install ${INSTALL_OPTS[@]}

if (( $? != 0 )); then
    printerr 'failed upgrading services'
    exit 1
fi

if (( $REINSTALL_KAMAILIO == 1 )); then
    printdbg 'restoring kamailio database'
    withRootDBConn mysql <${CURR_BACKUP_DIR}/db.sql &&
    withRootDBConn mysql <${CURR_BACKUP_DIR}/user.sql || {
        printerr 'failed restoring kamailio database'
        exit 1
    }
fi

if (( $REINSTALL_DSIPROUTER == 1 )); then
    printdbg 'updating dSIPRouter version'
    setConfigAttrib 'VERSION' '0.74' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py -q || {
        printerr 'failed updating dSIPRouter version'
        exit 1
    }
fi

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
