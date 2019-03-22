#!/usr/bin/env bash

#=============== dSIPRouter Management Script ==============#
#
# install, configure, and manage dsiprouter
#
#========================== NOTES ==========================#
#
# Supported OS:
# Debian 9 (stretch)
# Debian 8 (jessie)
# Debian 7 (wheezy)
# CentOS 7
#
# Notes:
# In general exported variables & functions
# are used in externally called scripts / programs
#
# TODO:
# move reusable vars/funcs to a util/library script
# allow remote db configuration on install
# allow user to move carriers freely between carrier groups
# allow a carrier to be in more than one carrier group
# add colored error output when installing / uninstalling
# add ncurses selection menu for enabling / disabling modules
# create templating schema for changing kam config values on install
#
#===========================================================#

# Set project dir (where src and install files go)
DSIP_PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(dirname $(readlink -f "$0"))}
# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

#================== USER_CONFIG_SETTINGS ===================#

# Uncomment if you want to debug this script.
#set -x

# Define some global variables
FLT_CARRIER=8
FLT_PBX=9
FLT_OUTBOUND=8000
FLT_INBOUND=9000
WITH_SSL=0
DEBUG=0     # By default debugging is turned off
export SERVERNAT=0
export REQ_PYTHON_MAJOR_VER=3
export DSIP_SYSTEM_CONFIG_DIR="/etc/dsiprouter"
export DSIP_KAMAILIO_CONFIG_DIR="${DSIP_PROJECT_DIR}/kamailio"
export DSIP_KAMAILIO_CONFIG_FILE="${DSIP_KAMAILIO_CONFIG_DIR}/kamailio51_dsiprouter.cfg"
export DSIP_DEFAULTS_DIR="${DSIP_KAMAILIO_CONFIG_DIR}/defaults"
export DSIP_CONFIG_FILE="${DSIP_PROJECT_DIR}/gui/settings.py"
export SYSTEM_KAMAILIO_CONFIG_DIR="/etc/kamailio"
export SYSTEM_KAMAILIO_CONFIG_FILE="${SYSTEM_KAMAILIO_CONFIG_DIR}/kamailio.cfg" # will be symlinked
export SYSTEM_RTPENGINE_CONFIG_DIR="/etc/rtpengine"
export SYSTEM_RTPENGINE_CONFIG_FILE="${SYSTEM_RTPENGINE_CONFIG_DIR}/rtpengine.conf"
export PATH_UPDATE_FILE="/etc/profile.d/dsip_paths.sh" # updates paths required
export RTPENGINE_VER="mr6.1.1.1"
export SRC_DIR="/usr/local/src"
export BACKUPS_DIR="/var/backups"

# Default MYSQL db root user values
MYSQL_ROOT_DEF_USERNAME="root"
MYSQL_ROOT_DEF_PASSWORD=""
MYSQL_ROOT_DEF_DATABASE="mysql"

# Default MYSQL db kamailio user values
MYSQL_KAM_DEF_USERNAME="kamailio"
MYSQL_KAM_DEF_PASSWORD="kamailiorw"
MYSQL_KAM_DEF_DATABASE="kamailio"

# Default SSL options
# If you created your own certs prior to installing set this to match your certs
if [ ${WITH_SSL} -eq 1 ]; then
    DSIP_SSL_CERT_DIR="/etc/ssl/certs"                                      # certs general location
    DSIP_DSIP_SSL_CERT_DIR="${DSIP_SSL_CERT_DIR}/$(hostname -f)"            # domain specific cert dir
    DSIP_SSL_KEY="${DSIP_DSIP_SSL_CERT_DIR}/key.pem"                        # private key
    DSIP_SSL_CHAIN="${DSIP_DSIP_SSL_CERT_DIR}/chain.pem"                    # full chain cert
    DSIP_SSL_CERT="${DSIP_DSIP_SSL_CERT_DIR}/cert.pem"                      # full chain + csr cert
    DSIP_SSL_EMAIL="admin@$(hostname -f)"                                   # email in certs (for renewal)
    DSIP_GUI_PROTOCOL="https"     
else
    DSIP_GUI_PROTOCOL="http"
fi


# Force the installation of a Kamailio version by uncommenting
#KAM_VERSION=44 # Version 4.4.x
#KAM_VERSION=51 # Version 5.1.x

# Uncomment and set this variable to an explicit Python executable file name
# If set, the script will not try and find a Python version with 3.5 as the major release number
#export PYTHON_CMD=/usr/bin/python3.4

# Network configuration values
export RTP_PORT_MIN=10000
export RTP_PORT_MAX=20000
export KAM_SIP_PORT=5060

#===========================================================#

#================= DYNAMIC_CONFIG_SETTINGS =================#
# updated dynamically!

export DSIP_PORT=$(getConfigAttrib 'DSIP_PORT' ${DSIP_CONFIG_FILE})
export EXTERNAL_IP=$(curl -s https://api.ipify.org)
export INTERNAL_IP=$(ip route get 8.8.8.8 | awk 'NR == 1 {print $7}')
export INTERNAL_NET=$(awk -F"." '{print $1"."$2"."$3".*"}' <<<$INTERNAL_IP)

#===========================================================#
DSIP_SERVER_DOMAIN="$(hostname -f)"    # DNS domain we are using

# Get Linux Distro
if [ -f /etc/redhat-release ]; then
 	export DISTRO="centos"
 	export DISTRO_VER=$(cat /etc/redhat-release | cut -d ' ' -f 4 | cut -d '.' -f 1)
elif [ -f /etc/debian_version ]; then
	export DISTRO="debian"
	export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
elif [[ "$(cat /etc/os-release | grep '^ID=' 2>/dev/null | cut -d '=' -f 2 | cut -d '"' -f 2)" == "amzn" ]]; then
	export DISTRO="amazon"
	export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
fi
# Check if we are on AWS Instance
export AWS_ENABLED=0
# Will try to access the AWS metadata URL and will return an exit code of 22 if it fails
# The -f flag enables this feature
curl -s -f --connect-timeout 2 http://169.254.169.254
ret=$?
if (( $ret != 22 )) && (( $ret != 28 )); then
    export AWS_ENABLED=1
fi

function displayLogo {
echo "CiAgICAgXyAgX19fX18gX19fX18gX19fX18gIF9fX19fICAgICAgICAgICAgIF8gCiAgICB8IHwv
IF9fX198XyAgIF98ICBfXyBcfCAgX18gXCAgICAgICAgICAgfCB8ICAgICAgICAgICAKICBfX3wg
fCAoX19fICAgfCB8IHwgfF9fKSB8IHxfXykgfF9fXyAgXyAgIF98IHxfIF9fXyBfIF9fIAogLyBf
YCB8XF9fXyBcICB8IHwgfCAgX19fL3wgIF8gIC8vIF8gXHwgfCB8IHwgX18vIF8gXCAnX198Cnwg
KF98IHxfX19fKSB8X3wgfF98IHwgICAgfCB8IFwgXCAoXykgfCB8X3wgfCB8fCAgX18vIHwgICAK
IFxfXyxffF9fX19fL3xfX19fX3xffCAgICB8X3wgIFxfXF9fXy8gXF9fLF98XF9fXF9fX3xffCAg
IAoKQnVpbHQgaW4gRGV0cm9pdCwgVVNBIC0gUG93ZXJlZCBieSBLYW1haWxpbyAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgClN1cHBv
cnQgY2FuIGJlIHB1cmNoYXNlZCBmcm9tIGh0dHBzOi8vZE9wZW5Tb3VyY2UuY29tL2RzaXByb3V0
ZXIKClRoYW5rcyB0byBvdXIgc3BvbnNvcjogU2t5ZXRlbCAoc2t5ZXRlbC5jb20pCg==" \
| base64 -d \
| { echo -e "\e[1;49;31m"; cat; echo -e "\e[39;49;00m"; }
}

# Cleanup exported variables on exit
function cleanupAndExit {
    unset DSIP_PROJECT_DIR DSIP_INSTALL_DIR DSIP_KAMAILIO_CONFIG_DIR DSIP_KAMAILIO_CONFIG DSIP_DEFAULTS_DIR SYSTEM_KAMAILIO_CONFIG_DIR DSIP_CONFIG_FILE
    unset REQ_PYTHON_MAJOR_VER DISTRO DISTRO_VER PYTHON_CMD AWS_ENABLED PATH_UPDATE_FILE SYSTEM_RTPENGINE_CONFIG_DIR SYSTEM_RTPENGINE_CONFIG_FILE SERVERNAT
    unset RTPENGINE_VER SRC_DIR DSIP_SYSTEM_CONFIG_DIR BACKUPS_DIR
    unset MYSQL_ROOT_PASSWORD MYSQL_ROOT_USERNAME MYSQL_ROOT_DATABASE MYSQL_KAM_PASSWORD MYSQL_KAM_USERNAME MYSQL_KAM_DATABASE
    unset RTP_PORT_MIN RTP_PORT_MAX DSIP_PORT EXTERNAL_IP INTERNAL_IP INTERNAL_NET
    unset -f setPythonCmd
    exit $1
}

# Validate OS and get supported Kamailio versions
function validateOSInfo {
    if [[ "$DISTRO" == "debian" ]]; then
        case "$DISTRO_VER" in
            8|9)
                if [[ -z "$KAM_VERSION" ]]; then
                   KAM_VERSION=51
                fi
                ;;
            7)
                if [[ -z "$KAM_VERSION" ]]; then
                    KAM_VERSION=44
                fi
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                cleanupAndExit 1
                ;;
        esac
    elif [[ "$DISTRO" == "centos" ]]; then
        case "$DISTRO_VER" in
            7)
                if [[ -z "$KAM_VERSION" ]]; then
                    KAM_VERSION=51
                fi
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                cleanupAndExit 1
            ;;
        esac
    elif [[ "$DISTRO" == "amazon" ]]; then
        case "$DISTRO_VER" in
            2)
                if [[ -z "$KAM_VERSION" ]]; then
                    KAM_VERSION=51
                fi
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                cleanupAndExit 1
                ;;
        esac
    else
        printerr "Your Operating System is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
        cleanupAndExit 1
    fi
}

# run prior to any cmd being processed
function initialChecks {
    validateOSInfo

    # make sure dirs exist (ones that may not yet exist)
    mkdir -p ${DSIP_KAMAILIO_CONFIG_DIR} ${SRC_DIR} ${BACKUPS_DIR}

    if [[ "$DISTRO" == "debian" ]]; then
        # comment out cdrom in sources as it can halt install
        sed -i -E 's/(^\w.*cdrom.*)/#\1/g' /etc/apt/sources.list
        # make sure we run package installs unattended
        export DEBIAN_FRONTEND="noninteractive"
    fi

    # make sure root db settings set
    if [[ "$MYSQL_ROOT_PASSWORD" == "" ]]; then
        export MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_DEF_PASSWORD"
    else
        export MYSQL_ROOT_PASSWORD
    fi
    if [[ "$MYSQL_ROOT_USERNAME" == "" ]]; then
        export MYSQL_ROOT_USERNAME="$MYSQL_ROOT_DEF_USERNAME"
    else
        export MYSQL_ROOT_USERNAME
    fi
    if [[ "$MYSQL_ROOT_DATABASE" == "" ]]; then
        export MYSQL_ROOT_DATABASE="$MYSQL_ROOT_DEF_DATABASE"
    else
        export MYSQL_ROOT_DATABASE
    fi

    # make sure kamailio db settings set
    if [[ "$MYSQL_KAM_PASSWORD" == "" ]]; then
        export MYSQL_KAM_PASSWORD="$MYSQL_KAM_DEF_PASSWORD"
    else
        export MYSQL_KAM_PASSWORD
    fi
    if [[ "$MYSQL_KAM_USERNAME" == "" ]]; then
        export MYSQL_KAM_USERNAME="$MYSQL_KAM_DEF_USERNAME"
    else
        export MYSQL_KAM_USERNAME
    fi
    if [[ "$MYSQL_KAM_DATABASE" == "" ]]; then
        export MYSQL_KAM_DATABASE="$MYSQL_KAM_DEF_DATABASE"
    else
        export MYSQL_KAM_DATABASE
    fi

    # SSL config checks if enabled
    if [ ${WITH_SSL} -eq 1 ]; then
        # check that hostname or fqdn  is set & not empty (must be set for SSL cert renewal to work)
        if [ -z "$(hostname -f)" ]; then
            printerr "You must configure a host name or DNS domain name to enable SSL.. Either configure your server domain or disable SSL."
            exit 1
        fi

        # make sure SSL options are set & not empty
        if [ -z "$DSIP_SSL_KEY" ] || [ -z "$DSIP_SSL_CERT" ] || [ -z "$DSIP_SSL_EMAIL" ]; then
            printerr "SSL configs are invalid. Configure SSL options or disable SSL."
            exit 1
        fi
    fi

    # fix PATH if needed
    # we are using the default install paths but these may change in the future
    mkdir -p $(dirname ${PATH_UPDATE_FILE}) && touch ${PATH_UPDATE_FILE}
    # - sipsak, and future use
    pathCheck /usr/local/bin || echo 'export PATH="/usr/local/bin${PATH:+:$PATH}"' >> ${PATH_UPDATE_FILE}
    # - rtpengine
    pathCheck /usr/sbin || echo 'export PATH="${PATH:+$PATH:}/usr/sbin"' >> ${PATH_UPDATE_FILE}
    # - kamailio
    pathCheck /sbin || echo 'export PATH="${PATH:+$PATH:}/sbin"' >> ${PATH_UPDATE_FILE}
    # import new path definition
    . ${PATH_UPDATE_FILE}
}

# exported because its used throughout called scripts as well
function setPythonCmd {
    # if local var is set just export
    if [[ ! -z "$PYTHON_CMD" ]]; then
        export PYTHON_CMD="$PYTHON_CMD"
        return 0
    fi

    possible_python_versions=$(find /usr/bin /usr/local/bin -name "python$REQ_PYTHON_MAJOR_VER*" -type f -executable  2>/dev/null)
    for i in $possible_python_versions; do
        ver=$($i -V 2>&1)
        # validate command produces viable python version
        if [ $? -eq 0 ]; then
            echo $ver | grep $REQ_PYTHON_MAJOR_VER >/dev/null
            if [ $? -eq 0 ]; then
                export PYTHON_CMD="$i"
                return 0
            fi
        fi
    done
}
export -f setPythonCmd

# set dynamic python config settings
function configurePythonSettings {
    setConfigAttrib -q 'KAM_KAMCMD_PATH' "$(type -p kamcmd)" ${DSIP_CONFIG_FILE}
    setConfigAttrib -q 'KAM_CFG_PATH' "$SYSTEM_KAMAILIO_CONFIG_FILE" ${DSIP_CONFIG_FILE}
    setConfigAttrib -q 'RTP_CFG_PATH' "$SYSTEM_KAMAILIO_CONFIG_FILE" ${DSIP_CONFIG_FILE}
    sed -i -r "s|(DSIP_SSL_KEY[[:space:]]?=.*)|DSIP_SSL_KEY = '${DSIP_SSL_KEY}'|g" ${DSIP_CONFIG_FILE}
    sed -i -r "s|(DSIP_SSL_KEY[[:space:]]?=.*)|DSIP_SSL_CERT = '${DSIP_SSL_CERT}'|g" ${DSIP_CONFIG_FILE}
    sed -i -r "s|(DSIP_SSL_KEY[[:space:]]?=.*)|DSIP_SSL_EMAIL = '${DSIP_SSL_EMAIL}'|g" ${DSIP_CONFIG_FILE}
#    sed -i -r "s|(DOMAIN[[:space:]]?=.*)|DOMAIN = '${DSIP_SERVER_DOMAIN}'|g" ${DSIP_CONFIG_FILE}
}

# update settings file based on cmdline args
# should be used prior to app execution
function updatePythonRuntimeSettings {
    if (( ${DEBUG} == 1 )); then
        setConfigAttrib 'DEBUG' 'True'
    else
        setConfigAttrib 'DEBUG' 'False'
    fi
}

function configureSSL {
    ## Configure self signed certificate
    CERT_DIR="/etc/ssl/certs/"
  
    mkdir -p ${DSIP_DSIP_SSL_CERT_DIR} 
    openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out ${DSIP_SSL_CERT} -keyout ${DSIP_SSL_KEY} -subj "/C=US/ST=MI/L=Detroit/O=dSIPRouter/CN=`hostname`" 
    sed -i -r "s|(SSL_KEY[[:space:]]?=.*)|SSL_KEY = '${DSIP_SSL_KEY}'|g" ${DSIP_CONFIG_FILE}
    sed -i -r "s|(SSL_CERT[[:space:]]?=.*)|SSL_CERT = '${DSIP_SSL_CERT}'|g" ${DSIP_CONFIG_FILE}
}

# updates and settings in kam config that may change
# should be run after reboot or change in network configurations
# TODO: we should support templating for the config instead
function updateKamailioConfig {
    setKamailioConfigIP 'INTERNAL_IP_ADDR' "${INTERNAL_IP}" ${SYSTEM_KAMAILIO_CONFIG_FILE}
    setKamailioConfigIP 'INTERNAL_IP_NET' "${INTERNAL_NET}" ${SYSTEM_KAMAILIO_CONFIG_FILE}
    setKamailioConfigIP 'EXTERNAL_IP_ADDR' "${EXTERNAL_IP}" ${SYSTEM_KAMAILIO_CONFIG_FILE}
}

# updates and settings in rtpengine config that may change
# should be run after reboot or change in network configurations
function updateRtpengineConfig {
    if (( ${SERVERNAT:-0} == 0 )); then
        INTERFACE="${EXTERNAL_IP}"
    else
        INTERFACE="${INTERNAL_IP}!${EXTERNAL_IP}"
    fi
    setRtpengineConfigAttrib 'interface' "$INTERFACE" ${SYSTEM_RTPENGINE_CONFIG_FILE}
}

function configureKamailio {
    cd ${DSIP_PROJECT_DIR}

    # copy template of kamailio configuration to a working copy
    cp -f ${DSIP_KAMAILIO_CONFIG_DIR}/kamailio51_dsiprouter.tpl ${DSIP_KAMAILIO_CONFIG_FILE}
    # set kamailio version in kam config
    sed -i -e "s/KAMAILIO_VERSION/${KAM_VERSION}/" ${DSIP_KAMAILIO_CONFIG_FILE}

    # get kam db connection settings
    local KAM_DB_HOST=$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})
    local KAM_DB_TYPE=$(getConfigAttrib 'KAM_DB_TYPE' ${DSIP_CONFIG_FILE})
    local KAM_DB_PORT=$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})
    local KAM_DB_NAME=$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})
    local KAM_DB_USER=$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})
    local KAM_DB_PASS=$(getConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})

    # check for cluster db connection and set kam config settings appropriately
    if printf "$KAM_DB_HOST" | grep -q -oP '.*\[.*\]'; then
        # db connection is clustered
        enableKamailioConfigAttrib 'WITH_DBCLUSTER' ${DSIP_KAMAILIO_CONFIG_FILE}

        # TODO: support different type/user/pass/port/name per connection
        # TODO: support multiple clusters
        local KAM_DB_CLUSTER_CONNS=""
        local KAM_DB_CLUSTER_MODES=""
        KAM_DB_HOST=$(printf "$KAM_DB_HOST" | tr -d '[]'"'"'"' | tr ',' ' ')

        local i=1
        for HOST in $KAM_DB_HOST; do
            KAM_DB_CLUSTER_CONNS+="modparam('db_cluster', 'connection', 'c${i}=>${KAM_DB_TYPE}://${KAM_DB_USER}:${KAM_DB_PASS}@${HOST}:${KAM_DB_PORT}/${KAM_DB_NAME}')\n"
            KAM_DB_CLUSTER_MODES+="c${i}=9r9r;"
            i=$((i+1))
        done
        KAM_DB_CLUSTER_MODES="modparam('db_cluster', 'cluster', 'dbcluster=>${KAM_DB_CLUSTER_MODES}')"
        sed -i -e "s~DB_CLUSTER_PARAMS~${KAM_DB_CLUSTER_CONNS}${KAM_DB_CLUSTER_MODES}~" ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        sed -i -e "s~DB_CONNECTION_URI~${KAM_DB_TYPE}://${KAM_DB_USER}:${KAM_DB_PASS}@${KAM_DB_HOST}:${KAM_DB_PORT}/${KAM_DB_NAME}~" ${DSIP_KAMAILIO_CONFIG_FILE}
    fi

    # make sure kamailio user exists
    mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_ROOT_DATABASE \
        -e "GRANT ALL PRIVILEGES ON $MYSQL_KAM_DATABASE.* TO '$MYSQL_KAM_USERNAME'@'localhost' IDENTIFIED BY '$MYSQL_KAM_PASSWORD';"

    # Install schema for drouting module
    mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE \
        -e "delete from version where table_name in ('dr_gateways','dr_groups','dr_gw_lists','dr_custom_rules','dr_rules')"
    mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE \
        -e "drop table if exists dr_gateways,dr_groups,dr_gw_lists,dr_custom_rules,dr_rules"
    if [ -e  /usr/share/kamailio/mysql/drouting-create.sql ]; then
        mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE < /usr/share/kamailio/mysql/drouting-create.sql
    else
        sqlscript=`find / -name 'drouting-create.sql' | grep mysql | grep 4. | sed -n 1p`
        mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE < $sqlscript
    fi

    # TODO: we need to test and re-implement this.
#    # required if tables exist and we are updating
#    function resetIncrementers {
#        SQL_TABLES=$(
#            (for t in "$@"; do printf ",'$t'"; done) | cut -d ',' -f '2-'
#        )
#
#        # reset auto increment for related tables to max btwn the related tables
#        INCREMENT=$(
#            mysql --skip-column-names --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_ROOT_DATABASE \ -e "\
#                SELECT MAX(AUTO_INCREMENT) FROM INFORMATION_SCHEMA.TABLES \
#                WHERE TABLE_SCHEMA = '$MYSQL_KAM_DATABASE' \
#                AND TABLE_NAME IN($SQL_TABLES);"
#        )
#        for t in "$@"; do
#            mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE \
#                -e "ALTER TABLE $t AUTO_INCREMENT=$INCREMENT"
#        done
#    }
#
#    # reset auto incrementers for related tables
#    resetIncrementers "dr_gw_lists"
#    resetIncrementers "uacreg"

    # Import Default Carriers
    if [ -e $(type -P mysqlimport) ]; then
        mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE -e "delete from address where grp=$FLT_CARRIER"

        # use a tmp dir so we don't have to change repo
        mkdir -p /tmp/defaults

	# copy over default gateway lists
	cp ${DSIP_DEFAULTS_DIR}/dr_gw_lists.csv  /tmp/defaults/dr_gw_lists.csv
        
	# sub in dynamic values
        sed "s/FLT_CARRIER/$FLT_CARRIER/g" \
            ${DSIP_DEFAULTS_DIR}/address.csv > /tmp/defaults/address.csv
        sed "s/FLT_CARRIER/$FLT_CARRIER/g" \
            ${DSIP_DEFAULTS_DIR}/dr_gateways.csv > /tmp/defaults/dr_gateways.csv
        sed "s/FLT_OUTBOUND/$FLT_OUTBOUND/g; s/FLT_INBOUND/$FLT_INBOUND/g" \
            ${DSIP_DEFAULTS_DIR}/dr_rules.csv > /tmp/defaults/dr_rules.csv
        sed "s/EXTERNAL_IP/$EXTERNAL_IP/g" \
            ${DSIP_DEFAULTS_DIR}/uacreg.csv > /tmp/defaults/uacreg.csv

        # import default carriers
        mysqlimport --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $MYSQL_KAM_DATABASE /tmp/defaults/address.csv
        mysqlimport --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $MYSQL_KAM_DATABASE /tmp/defaults/dr_gw_lists.csv
        mysqlimport --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" --fields-terminated-by=',' --ignore-lines=0  \
            -L $MYSQL_KAM_DATABASE /tmp/defaults/uacreg.csv
        mysqlimport --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $MYSQL_KAM_DATABASE /tmp/defaults/dr_gateways.csv
        mysqlimport --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $MYSQL_KAM_DATABASE /tmp/defaults/dr_rules.csv

        rm -rf /tmp/defaults
    fi

    # Backup kamcfg and link the dsiprouter kamcfg
    cp -f ${SYSTEM_KAMAILIO_CONFIG_FILE} ${SYSTEM_KAMAILIO_CONFIG_FILE}.$(date +%Y%m%d_%H%M%S)
    rm -f ${SYSTEM_KAMAILIO_CONFIG_FILE}
    ln -s ${DSIP_KAMAILIO_CONFIG_FILE} ${SYSTEM_KAMAILIO_CONFIG_FILE}

    # Fix the mpath
    fixMPATH

    # Enable SERVERNAT
    if [ "$SERVERNAT" == "1" ]; then
        enableSERVERNAT
    fi
}

function enableSERVERNAT {
	sed -i 's/##!define WITH_SERVERNAT/#!define WITH_SERVERNAT/' ${DSIP_KAMAILIO_CONFIG_FILE}
	sed -i 's/!INTERNAL_IP_ADDR!.*!g/!INTERNAL_IP_ADDR!'$INTERNAL_IP'!g/' ${DSIP_KAMAILIO_CONFIG_FILE}
	sed -i 's/!INTERNAL_IP_NET!.*!g/!INTERNAL_IP_NET!'$INTERNAL_NET'!g/' ${DSIP_KAMAILIO_CONFIG_FILE}
	sed -i 's/!EXTERNAL_IP_ADDR!.*!g/!EXTERNAL_IP_ADDR!'$EXTERNAL_IP'!g/' ${DSIP_KAMAILIO_CONFIG_FILE}

	printwarn "SERVERNAT is enabled - Restarting Kamailio is required"
	printdbg "You can restart it by executing: systemctl restart kamailio"
}

function disableSERVERNAT {
	sed -i 's/#!define WITH_SERVERNAT/##!define WITH_SERVERNAT/' ${DSIP_KAMAILIO_CONFIG_FILE}

	printwarn "SERVERNAT is disabled - Restarting Kamailio is required"
	printdbg "You can restart it by executing: systemctl restart kamailio"
}

# Try to locate the Kamailio modules directory.  It will use the last modules directory found
function fixMPATH {
    for i in `find /usr -name drouting.so`; do
        mpath=`dirname $i| grep 'modules$'`
        if [ "$mpath" != '' ]; then
            mpath=$mpath/
            break #found a mpath
        fi
    done

    printdbg "The Kamailio mpath has been updated to:$mpath"
    if [ "$mpath" != '' ]; then
        sed -i 's#mpath=.*#mpath=\"'$mpath'\"#g' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        printerr "Can't find the module path for Kamailio.  Please ensure Kamailio is installed and try again!"
        cleanupAndExit 1
    fi
}


# Start RTPEngine
function startRTPEngine {
    if [ $DISTRO == "debian" ]; then
        systemctl start ngcp-rtpengine-daemon
    fi

    if [ $DISTRO == "centos" ]; then
        systemctl start rtpengine
    fi
}

# Stop RTPEngine
function stopRTPEngine {
    if [ $DISTRO == "debian" ]; then
        systemctl stop ngcp-rtpengine-daemon
    fi

    if [ $DISTRO == "centos" ]; then
        systemctl stop rtpengine
    fi
}

# Install the RTPEngine from sipwise
function installRTPEngine {
    cd ${DSIP_PROJECT_DIR}

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]; then
        printerr "RTPEngine is already installed"
        cleanupAndExit 1
    fi

    echo "Attempting to install Kamailio..."
    ./rtpengine/${DISTRO}/install.sh install
    if [ $? -eq 0 ]; then
        printdbg "RTPEngine was installed!"
    else
        printerr "RTPEngine install failed"
        cleanupAndExit 1
    fi

    # update rtpengine configs on reboot
    cronAppend "@reboot ${DSIP_PROJECT_DIR}/dsiprouter.sh updatertpconfig"

    # Restart Kamailio with the new configurations
    systemctl restart kamailio
    if [ $? -eq 0 ]; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled
        echo -e "\e[32m------------------------------------\e[0m"
        echo -e "\e[32mRTPEngine Installation is complete! \e[0m"
        echo -e "\e[32m------------------------------------\e[0m\n"
    else
        printerr "RTPEngine install failed"
        cleanupAndExit 1
    fi
}

# Remove RTPEngine
function uninstallRTPEngine {
    cd ${DSIP_PROJECT_DIR}

    if [ ! -f ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled ]; then
        printwarn -e "RTPEngine is not installed! - uninstalling anyway to be safe"
    fi

    printdbg "Attempting to uninstall RTPEngine..."
    ./rtpengine/$DISTRO/install.sh uninstall

    if [ $? -ne 0 ]; then
        printerr "RTPEngine uninstall failed"
        cleanupAndExit 1
    fi

    # remove rtpengine update crontab entry
    cronRemove 'updatertpconfig'

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled

    printdbg "RTPEngine was uninstalled"
}

# Enable RTP within the Kamailio configuration so that it uses the RTPEngine
function enableRTP {
    sed -i 's/#!define WITH_NAT/##!define WITH_NAT/' ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamailio.cfg
} #end of enableRTP

# Disable RTP within the Kamailio configuration so that it doesn't use the RTPEngine
function disableRTP {
    sed -i 's/##!define WITH_NAT/#!define WITH_NAT/' ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamailio.cfg
} #end of disableRTP

function installDsiprouter {
    cd ${DSIP_PROJECT_DIR}

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]; then
        printerr "dSIPRouter is already installed"
        cleanupAndExit 1
    fi

	printdbg "Attempting to install dSIPRouter..."
    ./dsiprouter/${DISTRO}/${DISTRO_VER}.sh install ${DSIP_PORT} ${PYTHON_CMD}

	if [ $? -ne 0 ]; then
	    printerr "dSIPRouter install failed"
	    cleanupAndExit 1
	fi

 	setPythonCmd
    if [ $? -eq 0 ]; then
        # configure dsiprouter modules
	    installModules
        # set some defaults in settings.py
        configurePythonSettings
    fi

    # Install Sipsak for troubleshooting and smoketest
	installSipsak

	# configure SSL
    if [ ${WITH_SSL} -eq 1 ]; then
        configureSSL
    fi

    # for AMI images the instance-id may change (could be a clone)
    # add to startup process a password reset to ensure its set correctly
    if (( $AWS_ENABLED == 1 )); then
        # add password reset to boot process (using cron)
        cronAppend "@reboot ${DSIP_PROJECT_DIR}/dsiprouter.sh resetpassword"
        # Required changes for Debian AMI's
        if [[ $DISTRO == "debian" ]]; then
            # Remove debian-sys-maint password for initial AMI scan
            sed -i "s/password =.*/password = /g" /etc/mysql/debian.cnf

            # Change default password for debian-sys-maint to instance-id at next boot
            # we must also change the corresponding password in /etc/mysql/debian.cnf
            # to comply with AWS AMI image standards
            # this must run at startup as well so create temp script & add to cron
            (cat << EOF
#!/usr/bin/env bash

# declare imported functions from library
$(declare -f getInstanceID)
$(declare -f cronRemove)

INSTANCE_ID=\$(getInstanceID)
mysql -e "CREATE USER IF NOT EXISTS 'debian-sys-maint'@'localhost' IDENTIFIED BY '\${INSTANCE_ID}'"
mysql -e "GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '\${INSTANCE_ID}'"
sed -i "s|password =.*|password = \${INSTANCE_ID}|g" /etc/mysql/debian.cnf
cronRemove '.reset_debiansys_user.sh'
rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.reset_debiansys_user.sh

exit 0
EOF
            ) > ${DSIP_SYSTEM_CONFIG_DIR}/.reset_debiansys_user.sh
            # note that the script will remove itself after execution
            chmod +x ${DSIP_SYSTEM_CONFIG_DIR}/.reset_debiansys_user.sh
            cronAppend "@reboot ${DSIP_SYSTEM_CONFIG_DIR}/.reset_debiansys_user.sh"
        fi
    fi

    # Start dSIPRouter
    start
    if [ $? -eq 0 ]; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled
        echo -e "\e[32m-------------------------------------\e[0m"
        echo -e "\e[32mdSIPRouter Installation is complete! \e[0m"
        echo -e "\e[32m-------------------------------------\e[0m\n"
        echo -e "\n\nThe username and dynamically generated password are below:\n"

        # Generate a unique admin password
        generatePassword

        # Tell them how to access the URL
        pprint "You can access the dSIPRouter web gui by going to:\n"
        pprint "External IP:  ${DSIP_GUI_PROTOCOL}://$EXTERNAL_IP:$DSIP_PORT\n"

        if [ "$EXTERNAL_IP" != "$INTERNAL_IP" ];then
            pprint "Internal IP: ${DSIP_GUI_PROTOCOL}://$INTERNAL_IP:$DSIP_PORT"
        fi
    else
        printerr "dSIPRouter install failed" && cleanupAndExit 1
    fi
}

function uninstallDsiprouter {
    cd ${DSIP_PROJECT_DIR}

    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]; then
        printwarn "dSIPRouter is not installed or failed during install - uninstalling anyway to be safe"
    fi

    # Uninstall Sipsak for troubleshooting and smoketest
    uninstallSipsak

    # Stop dSIPRouter, remove .installed file, close firewall
    stop

    printdbg "Attempting to uninstall dSIPRouter UI..."
    ./dsiprouter/$DISTRO/$DISTRO_VER.sh uninstall ${DSIP_PORT} ${PYTHON_CMD}

    if [ $? -ne 0 ]; then
        echo "dsiprouter uninstall failed"
        cleanupAndExit 1
    fi

    # Remove crontab entry
    echo "Removing crontab entry"
    cronRemove 'dsiprouter_cron.py'

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled

    printdbg "dSIPRouter was uninstalled"
}

function installKamailio {
    cd ${DSIP_PROJECT_DIR}

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
        printerr "kamailio is already installed"
        cleanupAndExit 1
    fi
    
    printdbg "Attempting to install Kamailio..."
    ./kamailio/${DISTRO}/${DISTRO_VER}.sh install ${KAM_VERSION} ${DSIP_PORT}
    if [ $? -eq 0 ]; then
        # configure kamailio settings
        configureKamailio
        echo "Kamailio was installed!"
    else
        printerr "kamailio install failed"
        cleanupAndExit 1
    fi

    # update kam configs on reboot
    cronAppend "@reboot ${DSIP_PROJECT_DIR}/dsiprouter.sh updatekamconfig"

    # Restart Kamailio with the new configurations
    systemctl restart kamailio
    if [ $? -eq 0 ]; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled
        echo -e "\e[32m-----------------------------------\e[0m"
        echo -e "\e[32mKamailio Installation is complete! \e[0m"
        echo -e "\e[32m-----------------------------------\e[0m\n"
    else
        printerr "Kamailio install failed"
        cleanupAndExit 1
    fi
}

function uninstallKamailio {
    cd ${DSIP_PROJECT_DIR}

    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
        printwarn "kamailio is not installed or failed during install - uninstalling anyway to be safe"
    fi

    # Uninstall Sipsak for troubleshooting and smoketest
    uninstallSipsak

    # Stop dSIPRouter, remove .installed file, close firewall
    stop

    printdbg "Attempting to uninstall Kamailio..."
    ./kamailio/$DISTRO/$DISTRO_VER.sh uninstall ${KAM_VERSION} ${DSIP_PORT} ${PYTHON_CMD}

    if [ $? -ne 0 ]; then
        printerr "kamailio uninstall failed"
        cleanupAndExit 1
    fi

    # remove kam update crontab entry
    cronRemove 'updatekamconfig'

    # Remove the hidden installed file, which denotes if it's installed or not
	rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled

    printdbg "kamailio was uninstalled"
}


function installModules {
    cd ${DSIP_PROJECT_DIR}

    # Install / Uninstall dSIPModules
    for dir in ./gui/modules/*; do
        if [[ -e ${dir}/install.sh ]]; then
            ./${dir}/install.sh $MYSQL_ROOT_USERNAME $MYSQL_ROOT_PASSWORD $MYSQL_ROOT_DATABASE $PYTHON_CMD
        fi
    done

    # Setup dSIPRouter Cron scheduler
    cronRemove 'dsiprouter_cron.py'
    cronAppend "*/1 * * * *  ${PYTHON_CMD} ${DSIP_PROJECT_DIR}/gui/dsiprouter_cron.py"
}

# Install Sipsak
# Used for testing and troubleshooting
installSipsak() {
    local START_DIR="$(pwd)"

	git clone https://github.com/nils-ohlmeier/sipsak.git ${SRC_DIR}/sipsak

	cd ${SRC_DIR}/sipsak
	autoreconf --install
	./configure
	make
	make install
	ret=$?

	if [ $ret -eq 0 ]; then
		printdbg "SipSak was installed"
	else
		printerr "SipSak install failed.. continuing without it"
	fi

	cd ${START_DIR}
}

# Remove Sipsak from the machine completely
uninstallSipsak() {
    local START_DIR="$(pwd)"

	if [ -d ${SRC_DIR}/sipsak ]; then
		cd ${SRC_DIR}/sipsak
		make uninstall
		rm -rf ${SRC_DIR}/sipsak
	fi

	cd ${START_DIR}
}


function start {
    # propagate settings to the app config
    updatePythonRuntimeSettings
    
    cd ${DSIP_PROJECT_DIR}

    # Check if the dSIPRouter process is already running
    if [ -e /var/run/dsiprouter/dsiprouter.pid ]; then
        PID=$(cat /var/run/dsiprouter/dsiprouter.pid)
        if ps -p ${PID} &>/dev/null; then
            printerr "dSIPRouter is already running under process id $PID"
            cleanupAndExit 1
        fi
    fi

    # Start RTPEngine if it was installed
    if [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled ]; then
        startRTPEngine
    fi

    # Start the process
    if [ $DEBUG -eq 1 ]; then
        # keep it in the foreground, only used for debugging issues
        ${PYTHON_CMD} ./gui/dsiprouter.py runserver
    else
        # normal startup, background process
        ${PYTHON_CMD} ./gui/dsiprouter.py runserver &>/dev/null &
    fi

    PID=$!
    # Make sure process is still running
    if ! ps -p ${PID} &>/dev/null; then
        printerr "Unable to start dSIPRouter"
        cleanupAndExit 1
    fi

    # Store the PID of the process
    if [ $PID -gt 0 ]; then
        if [ ! -e /var/run/dsiprouter ]; then
            mkdir -p /var/run/dsiprouter/
        fi

        echo $PID > /var/run/dsiprouter/dsiprouter.pid
        pprint "dSIPRouter was started under process id $PID"
    fi
} #end of start



function stop {
    # propagate settings to the app config
    updatePythonRuntimeSettings

    cd ${DSIP_PROJECT_DIR}

	if [ -e /var/run/dsiprouter/dsiprouter.pid ]; then
		#kill -9 `cat /var/run/dsiprouter/dsiprouter.pid`
        kill -9 $(pgrep -f runserver) &>/dev/null
		rm -rf /var/run/dsiprouter/dsiprouter.pid
		pprint "dSIPRouter was stopped"
	else
		printwarn "dSIPRouter is not running"
	fi

	if [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled ]; then
		stopRTPEngine
	 	if [ $? -eq 0 ]; then
			pprint "RTPEngine was stopped"
		fi
	else
		printwarn "RTPEngine was not installed"
	fi
}

function resetPassword {
    printdbg "The admin account has been reset to the following:"

    #Call the bash function that generates the password
    generatePassword

    #dSIPRouter will be restarted to make the new password active
    printwarn "Restart dSIPRouter to make the password active!\n"
}

# Generate password and set it in the ${DSIP_CONFIG_FILE} PASSWORD field
function generatePassword {
    if (( $AWS_ENABLED == 1)); then
        password=$(getInstanceID)
    else
        password=$(date +%s | sha256sum | base64 | head -c 16)
    fi

    # Add single quotes
    password1="'$password'"
    sed -i 's/PASSWORD[[:space:]]\?=[[:space:]]\?.*/PASSWORD = '$password1'/g' ${DSIP_CONFIG_FILE}

    echo -e "username: admin\npassword: $password\n"
}

function upgrade {
    # TODO: set / handle parsed args
    UPGRADE_RELEASE="v0.51"

    BACKUP_DIR="/var/backups"
    CURR_BACKUP_DIR="${BACKUP_DIR}/$(date '+%Y-%m-%d')"
    mkdir -p ${BACKUP_DIR} ${CURR_BACKUP_DIR}
    mkdir -p ${CURR_BACKUP_DIR}/{etc,var/lib,${HOME},$(dirname "$DSIP_PROJECT_DIR")}

    mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges \
        --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" > ${CURR_BACKUP_DIR}/mysql_full.sql
    mysqldump --single-transaction --skip-triggers --skip-add-drop-table --insert-ignore \
        --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" ${MYSQL_KAM_DATABASE} \
        | perl -0777 -pi -e 's/CREATE TABLE (`(.+?)`.+?;)/CREATE TABLE IF NOT EXISTS \1\n\nTRUNCATE TABLE `\2`;\n/gs' \
        > ${CURR_BACKUP_DIR}/kamdb_merge.sql

    systemctl stop rtpengine
    systemctl stop kamailio
    systemctl stop dsiprouter
    systemctl stop mysql

    mv -f ${DSIP_PROJECT_DIR} ${CURR_BACKUP_DIR}/${DSIP_PROJECT_DIR}
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR} ${CURR_BACKUP_DIR}/${SYSTEM_KAMAILIO_CONFIG_DIR}
    # in case mysqldumps failed silently, backup mysql binary data
    mv -f /var/lib/mysql ${CURR_BACKUP_DIR}/var/lib/
    cp -f /etc/my.cnf* ${CURR_BACKUP_DIR}/etc/
    cp -rf /etc/my.cnf* ${CURR_BACKUP_DIR}/etc/
    cp -rf /etc/mysql ${CURR_BACKUP_DIR}/etc/
    cp -f ${HOME}/.my.cnf* ${CURR_BACKUP_DIR}/${HOME}/

    iptables-save > ${CURR_BACKUP_DIR}/iptables.dump
    ip6tables-save > ${CURR_BACKUP_DIR}/ip6tables.dump

    git clone https://github.com/dOpensource/dsiprouter.git --branch="$UPGRADE_RELEASE" ${DSIP_PROJECT_DIR}
    cd ${DSIP_PROJECT_DIR}

    # TODO: figure out what settings they installed with previously
    # or we can simply store them in a text file (./installed)
    # after a succesfull install completes
    ./dsiprouter.sh uninstall
    ./dsiprouter.sh install

    mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" ${MYSQL_KAM_DATABASE} < ${CURR_BACKUP_DIR}/kamdb_merge.sql

    # TODO: fix any conflicts that would arise from our new modules / tables in KAMDB

    # TODO: print backup location info to user

    # TODO: transfer / merge backup configs to new configs
    # kam configs
    # dsip configs
    # iptables configs
    # mysql configs

    # TODO: restart services, check for good startup
}

function usageOptions {
    linebreak() {
        printf '_%.0s' $(seq 1 ${COLUMNS:-100}) && echo ''
    }

    linebreak
    printf '\n%s\n%s\n' \
        "USAGE:" \
        "$0 <command> [options]"

    linebreak
    printf "\n%-30s %s\n" \
        "COMMAND" "OPTIONS"
    printf "%-30s %s\n" \
        "install" "-debug|-exip <ip>|--external-ip=<ip>|-servernat|-rtpengine|-ui"
    printf "%-30s %s\n" \
        "uninstall" "-debug|-rtpengine|-ui"
    printf "%-30s %s\n" \
        "start" "-debug"
    printf "%-30s %s\n" \
        "stop" "-debug"
    printf "%-30s %s\n" \
        "restart" "-debug"
    printf "%-30s %s\n" \
        "rtpengineonly" "-debug|-servernat"
    printf "%-30s %s\n" \
        "configurekam" "-debug"
    printf "%-30s %s\n" \
        "sslenable" "-debug"
    printf "%-30s %s\n" \
        "installmodules" "-debug"
    printf "%-30s %s\n" \
        "fixmpath" "-debug"
    printf "%-30s %s\n" \
        "enableservernat" "-debug"
    printf "%-30s %s\n" \
        "disableservernat" "-debug"
    printf "%-30s %s\n" \
        "resetpassword" "-debug"
    printf "%-30s %s\n" \
        "help|-h|--help"

    linebreak
    printf '\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
        "SUMMARY:" \
        "dSIPRouter is a Web Management GUI for Kamailio based on use case design, with a focus on ITSP and Carrier use cases." \
        "This means that we aren’t a general purpose GUI for Kamailio." \
        "If that's required then use Siremis, which is located at http://siremis.asipto.com/" \
        "This script is used for installing, uninstalling, managing, and configuring dSIPRouter." \
        "That includes installing the Web GUI portion, Kamailio Configuration file and optionally for installing the RTPEngine by SIPwise" \
        "This script can also be used to start, stop and restart dSIPRouter.  It will not restart Kamailio."

    linebreak
    printf '\n%s\n%s\n%s\n\n' \
        "MORE INFO:" \
        "Full documentation is available online: https://dsiprouter.readthedocs.io" \
        "Support is available from dOpenSource.  Visit us at https://dopensource.com/dsiprouter or call us at 888-907-2085"

    linebreak
    printf '\n%s\n%s\n%s\n\n' \
        "PROVIDED BY:" \
        "dOpenSource | A Flyball Company" \
        "Made in Detroit, MI USA"

    linebreak
}


# TODO: make dsip, rtpengine, kamailio installs independent functions
# we should also make the ,installed file seperate for each service
# TODO: uninstall_dsiprouter_ui() and install_dsiprouter_ui() are blocking functions
# meaning that they block processing of cmdline options and execute
# this means that some cmdline options may not be processed yet
# we can't fix this until the install functions are all independent of each other
# until then use this option with extreme caution
# TODO: add help options for each command w/ subsection usage info for that command
function processCMD {
    # prep before processing commands
    initialChecks
    setPythonCmd # may be overridden in distro install script

    # Display usage options if no options are specified
    if (( $# == 0 )); then
   	    usageOptions
    	cleanupAndExit 1
    fi

    # process all options before running commands
    declare -a RUN_COMMANDS
    ARG="$1"
    case $ARG in
        install)
            # install kamailio and dsiprouter
            RUN_COMMANDS+=(installKamailio installDsiprouter)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    -exip)
                        shift
                        export EXTERNAL_IP="$1"
                        shift
                        ;;
                    --external-ip=*)
                        export EXTERNAL_IP=$(echo "$1" | cut -d '=' -f 2)
                        shift
                        ;;
                    -servernat)
                        export SERVERNAT=1
                        shift
                        ;;
                    -ui) # install only dsiprouter gui (blocking)
                        installDsiprouter
                        displayLogo
                        cleanupAndExit 0
                        ;;
                    -rtpengine)
                        RUN_COMMANDS+=(installRTPEngine)
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done

            # display logo after install / uninstall commands
            RUN_COMMANDS+=(displayLogo)
            ;;
        uninstall)
            # uninstall kamailio and dsiprouter
            RUN_COMMANDS+=(uninstallKamailio uninstallDsiprouter)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    -ui) # uninstall only dsiprouter gui (blocking)
                        uninstallDsiprouter
                        displayLogo
                        cleanupAndExit 0
                        ;;
                    -rtpengine)
                        RUN_COMMANDS+=(uninstallRTPEngine)
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done

            # display logo after install / uninstall commands
            RUN_COMMANDS+=(displayLogo)
            ;;
        start)
            # start all the installed services
            RUN_COMMANDS+=(start)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        stop)
            # stop all the installed services
            RUN_COMMANDS+=(stop)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        restart)
            # restart all the installed services
            RUN_COMMANDS+=(stop start)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        rtpengineonly)
            # install rtpengine only
            RUN_COMMANDS+=(installRTPEngine)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    -servernat)
                        export SERVERNAT=1
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        configurekam)
            # reconfigure kamailio configs
            RUN_COMMANDS+=(configureKamailio)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        sslenable)
            # reconfigure ssl configs
            RUN_COMMANDS+=(configureSSL)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        installmodules)
            # reconfigure dsiprouter modules
            RUN_COMMANDS+=(installModules)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        fixmpath)
            # reconfigure kamailio modules
            RUN_COMMANDS+=(fixMPATH)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        enableservernat)
            # enable serverside nat settings for kamailio
            RUN_COMMANDS+=(enableSERVERNAT)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        disableservernat)
            # disable serverside nat settings for kamailio
            RUN_COMMANDS+=(disableSERVERNAT)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        resetpassword)
            # reset dsiprouter gui password
            RUN_COMMANDS+=(resetPassword)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        updatekamconfig)
            # reset dynamic
            RUN_COMMANDS+=(updateKamailioConfig)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        updatertpconfig)
            # reset dsiprouter gui password
            RUN_COMMANDS+=(updateRtpengineConfig)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
                        set -x
                        shift
                        ;;
                    -servernat)
                        export SERVERNAT=1
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done
            ;;
        -h|--help|help)
            usageOptions
            cleanupAndExit 1
            ;;
        *)
            printerr "Invalid command [$ARG]"
            usageOptions
            cleanupAndExit 1
            ;;
    esac

    # Options are processed... run commands. Processing Notes below.
    # default priority of install (with rtpengine):
    # 1. kamailio
    # 2. dsiprouter
    # 3. rtpengine
    # default order of install (without rtpengine):
    # 1. kamailio
    # 2. dsiprouter
    # default order of install (without dsiprouter):
    # 1. kamailio
    # 2. rtpengine
    for RUN_COMMAND in ${RUN_COMMANDS[@]}; do
        $RUN_COMMAND
    done
    cleanupAndExit 0
} #end of processCMD

processCMD "$@"
