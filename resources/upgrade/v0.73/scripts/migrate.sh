#!/usr/bin/env bash

# where the new project files were downloaded
NEW_PROJECT_DIR=${NEW_PROJECT_DIR:-/tmp/dsiprouter}
# whether or not this was called from the GUI
RUN_FROM_GUI=${RUN_FROM_GUI:-0}

# set project dir where previous repo was located
export DSIP_PROJECT_DIR='/opt/dsiprouter'
# import dsip_lib utility / shared functions (we are using old functions on purpose here)
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

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
DSIP_CONFIG_FILE=${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
export ROOT_DB_PASS=$(decryptConfigAttrib 'ROOT_DB_PASS' ${DSIP_CONFIG_FILE})
export ROOT_DB_HOST=$(getConfigAttrib 'ROOT_DB_HOST' ${DSIP_CONFIG_FILE})
export ROOT_DB_PORT=$(getConfigAttrib 'ROOT_DB_PORT' ${DSIP_CONFIG_FILE})
export ROOT_DB_NAME=$(getConfigAttrib 'ROOT_DB_NAME' ${DSIP_CONFIG_FILE})
export SET_KAM_DB_HOST=$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})
export KAM_DB_TYPE=$(getConfigAttrib 'KAM_DB_TYPE' ${DSIP_CONFIG_FILE})
export SET_KAM_DB_PORT=$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})
export SET_KAM_DB_NAME=$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})
export KAM_DB_USER=$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})
export KAM_DB_PASS=$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})
export SET_DSIP_GUI_USER=$(getConfigAttrib 'DSIP_USERNAME' ${DSIP_CONFIG_FILE})
export SET_DSIP_GUI_PASS=$(decryptConfigAttrib 'DSIP_PASSWORD' ${DSIP_CONFIG_FILE})
export SET_DSIP_API_TOKEN=$(decryptConfigAttrib 'DSIP_API_TOKEN' ${DSIP_CONFIG_FILE})
export SET_DSIP_MAIL_USER=$(getConfigAttrib 'MAIL_USERNAME' ${DSIP_CONFIG_FILE})
export SET_DSIP_MAIL_PASS=$(decryptConfigAttrib 'MAIL_PASSWORD' ${DSIP_CONFIG_FILE})
export SET_DSIP_IPC_TOKEN=$(decryptConfigAttrib 'DSIP_IPC_PASS' ${DSIP_CONFIG_FILE})

# determine whether we keep the port (mariadb 10.6 changed the default client behavior)
if [[ "$KAM_DB_HOST" == "localhost" ]]; then
    SQL_OPTS=( "--user=$ROOT_DB_USER" "--password=$ROOT_DB_PASS" "--host=$KAM_DB_HOST" )
else
    SQL_OPTS=( "--user=$ROOT_DB_USER" "--password=$ROOT_DB_PASS" "--host=$KAM_DB_HOST" "--port=$KAM_DB_PORT" )
fi

printdbg 'preparing for migration'
REINSTALL_DNSMASQ=0
REINSTALL_KAMAILIO=0
REINSTALL_DSIPROUTER=0
REINSTALL_RTPENGINE=0
REINSTALL_DNSMASQ_COMPLETE=0
REINSTALL_KAMAILIO_COMPLETE=0
REINSTALL_DSIPROUTER_COMPLETE=0
REINSTALL_RTPENGINE_COMPLETE=0
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

# if the state files for the services to upgrade were there before
# and we fail, put them back so the system can recover
cleanupHandler() {
    if (( $REINSTALL_DNSMASQ == 1 && $REINSTALL_DNSMASQ_COMPLETE == 0 )); then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled
    fi
    if (( $REINSTALL_KAMAILIO == 1 && $REINSTALL_KAMAILIO_COMPLETE == 0 )); then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled
    fi
    if (( $REINSTALL_DSIPROUTER == 1 && $REINSTALL_DSIPROUTER_COMPLETE == 0 )); then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled
    fi
    if (( $REINSTALL_RTPENGINE == 1 && $REINSTALL_RTPENGINE_COMPLETE == 0 )); then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled
    fi
    trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM
}
trap 'cleanupHandler $?' EXIT SIGHUP SIGINT SIGQUIT SIGTERM

# always reinstalled
rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiproutercliinstalled" 2>/dev/null
rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.requirementsinstalled" 2>/dev/null
rm -rf ${SRC_DIR}/kamailio ${SRC_DIR}/rtpengine

#printdbg 'stopping effected services'
#systemctl stop dsiprouter
#systemctl stop kamailio
#systemctl stop rtpengine

printdbg 'migrating dSIPRouter project files'
# fresh repo coming up
cp -rf ${NEW_PROJECT_DIR}/. ${DSIP_PROJECT_DIR}/
rm -rf ${NEW_PROJECT_DIR}

printdbg 'dropping kamailio database'
mysql ${SQL_OPTS[@]} -e "DROP DATABASE IF EXISTS $KAM_DB_NAME;"

if (( $? != 0 )); then
    printerr 'Failed dropping DB'
    exit 1
fi

printdbg 'upgrading services'
${DSIP_PROJECT_DIR}/dsiprouter.sh install ${INSTALL_OPTS[@]}

if (( $? != 0 )); then
    printerr 'failed upgrading services'
    exit 1
fi

printdbg 'updating new dSIPRouter settings'
cd ${DSIP_PROJECT_DIR}/gui && (
python3 <<'EOF'
import os
import settings as default_settings
from importlib.util import module_from_spec, spec_from_file_location
from shared import objToDict, updateConfig
from util.security import AES_CTR
default_settings_dict = objToDict(default_settings)
spec = spec_from_file_location('current_settings', '/etc/dsiprouter/gui/settings.py')
current_settings = module_from_spec(spec)
spec.loader.exec_module(current_settings)
current_settings_dict = objToDict(current_settings)
default_settings_dict.update(current_settings_dict)
default_settings_dict['DSIP_SESSION_KEY'] = AES_CTR.encrypt(os.urandom(32))
os.system(f'cp -f {default_settings.__file__} {current_settings.__file__}')
updateConfig(current_settings, default_settings_dict)
EOF
) &&
setConfigAttrib 'VERSION' '0.73' /etc/dsiprouter/gui/settings.py || {
    printerr 'failed updating dSIPRouter settings'
    exit 1
}

if (( $RUN_FROM_GUI == 0 )); then
    printdbg 'restarting services'
    systemctl restart rtpengine
    systemctl restart kamailio
    systemctl restart dsiprouter
fi

pprint 'upgrade completed successfully'

exit 0
