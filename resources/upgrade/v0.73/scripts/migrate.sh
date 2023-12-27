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
REINSTALL_KAMAILIO=0
REINSTALL_DSIPROUTER=0
REINSTALL_RTPENGINE=0
INSTALL_OPTS=()
if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled" ]]; then
    REINSTALL_DNSMASQ=1
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

    if (( ${KAM_DB_DROPPED:-0} == 1 )); then
        withRootDBConn mysql <${CURR_BACKUP_DIR}/db.sql
        withRootDBConn mysql <${CURR_BACKUP_DIR}/user.sql
    fi

    if (( $RUN_FROM_GUI == 0 )); then
        if (( $REINSTALL_DNSMASQ == 1 )); then
            systemctl restart dnsmasq
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

# always reinstalled
rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiproutercliinstalled" 2>/dev/null
rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.requirementsinstalled" 2>/dev/null
rm -rf ${SRC_DIR}/kamailio ${SRC_DIR}/rtpengine

# conditionally reinstalled
printdbg 'masking services'
if (( $REINSTALL_DNSMASQ == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled

    # dnsmasq is not masked, we want it to restart during the install process
    if [[ -f /etc/systemd/system/dnsmasq.service ]]; then
        mv -f /etc/systemd/system/dnsmasq.service /lib/systemd/system/dnsmasq.service
        systemctl daemon-reload
    fi
fi
if (( $REINSTALL_KAMAILIO == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled

    if [[ -f /etc/systemd/system/kamailio.service ]]; then
        mv -f /etc/systemd/system/kamailio.service /lib/systemd/system/kamailio.service
        systemctl daemon-reload
    fi

    rm -f "$DSIP_KAMAILIO_CONFIG_FILE"

    systemctl mask kamailio.service
fi
if (( $REINSTALL_DSIPROUTER == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled

    systemctl mask dsiprouter.service
fi
if (( $REINSTALL_RTPENGINE == 1 )); then
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled

    if [[ -f /etc/systemd/system/rtpengine.service ]]; then
        mv -f /etc/systemd/system/rtpengine.service /lib/systemd/system/rtpengine.service
        systemctl daemon-reload
    fi

    systemctl mask rtpengine.service
fi

printdbg 'migrating dSIPRouter project files'
cp -rf ${NEW_PROJECT_DIR}/. ${DSIP_PROJECT_DIR}/
rm -rf ${NEW_PROJECT_DIR}
cd ${DSIP_PROJECT_DIR}/

if (( $REINSTALL_DSIPROUTER == 1 )); then
    printdbg 'updating new dSIPRouter settings'
    cd ${DSIP_PROJECT_DIR}/gui && (
python3 <<'EOF'
import os
import settings as default_settings
from importlib.util import module_from_spec, spec_from_file_location
from shared import objToDict, updateConfig
default_settings_dict = objToDict(default_settings)
spec = spec_from_file_location('current_settings', '/etc/dsiprouter/gui/settings.py')
current_settings = module_from_spec(spec)
spec.loader.exec_module(current_settings)
current_settings_dict = objToDict(current_settings)
default_settings_dict.update(current_settings_dict)
os.system(f'cp -f {default_settings.__file__} {current_settings.__file__}')
updateConfig(current_settings, default_settings_dict)
EOF
    ) || {
        printerr 'failed updating dSIPRouter settings'
        exit 1
    }
fi

# source the new dsip_lib functions
# WARNING: from here on we are explicitly using the NEW definitions of the dsip_lib funcs
# NOTE: resetConfigsHandler() above will still use the new definitions (lazy loading)
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

if (( $REINSTALL_KAMAILIO == 1 )); then
    printdbg 'backing up kamailio database'
    dumpDB "$KAM_DB_NAME" >${CURR_BACKUP_DIR}/db.sql
    dumpDBUser "$KAM_DB_USER@$KAM_DB_NAME" >${CURR_BACKUP_DIR}/user.sql

    withRootDBConn mysql -e "USE $KAM_DB_NAME; DROP TABLE IF EXISTS dsip_settings;"
    withRootDBConn mysqldump --single-transaction --no-create-info --skip-triggers --replace "$KAM_DB_NAME" >${CURR_BACKUP_DIR}/data.sql
    if [[ ! -f ${CURR_BACKUP_DIR}/data.sql ]]; then
        printerr 'failed backing up kamailio database data'
        exit 1
    fi
    printdbg 'dropping kamailio database to install new schema'
    withRootDBConn mysql -e "DROP DATABASE IF EXISTS $KAM_DB_NAME;"
    withRootDBConn mysql -e "DROP USER IF EXISTS '$KAM_DB_USER'@'%'; DROP USER IF EXISTS '$KAM_DB_USER'@'localhost';"
    KAM_DB_DROPPED=1
fi

printdbg 'upgrading services'
${DSIP_PROJECT_DIR}/dsiprouter.sh install ${INSTALL_OPTS[@]}

if (( $? != 0 )); then
    printerr 'failed upgrading services'
    exit 1
fi

if (( $REINSTALL_KAMAILIO == 1 )); then
    printdbg 'restoring kamailio database data'
    withRootDBConn --db="$KAM_DB_NAME" mysql <${CURR_BACKUP_DIR}/data.sql || {
        printerr 'failed restoring kamailio database data'
        exit 1
    }
fi

if (( $REINSTALL_DSIPROUTER == 1 )); then
    printdbg 'updating dSIPRouter version'
    setConfigAttrib 'VERSION' '0.73' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py -q || {
        printerr 'failed updating dSIPRouter version'
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
