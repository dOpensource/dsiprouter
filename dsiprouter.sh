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
# CentOS 7
# Amazon Linux 2
# Ubuntu 16.04 (xenial)
#
# Notes:
# In general exported variables & functions
# are used in externally called scripts / programs
#
# TODO:
# allow remote db configuration on install
# allow user to move carriers freely between carrier groups
# allow a carrier to be in more than one carrier group
# add ncurses selection menu for enabling / disabling modules
# seperate kam config into smaller sections and import from main cfg
# seperate gui routes into smaller sections and import as blueprints
# allow loading python configs and kam configs from db
# track, organize, and better manage dependencies
# allow hot-reloading password from python configs while dsiprouter running
#
#===========================================================#

# Set project dir (where src and install files go)
DSIP_PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(dirname $(readlink -f "$0"))}
# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

# Uncomment for detailed debugging information
# - splits stdout, stderr, and trace streams into 3 files
# - output files are timestamped throughout process (cpu intensive)
# - useful for tracking down bugs, especially when a lot of output is produced
# - the gawk version seems to be more efficient but mawk is supported as well
#
#mkdir -p /tmp/debug && rm -f /tmp/debug/*.log 2>/dev/null
#
# - gawk version (alias awk='gawk')
#exec   > >(awk '{ print strftime("[%Y-%m-%d_%H:%M:%S] "), $0; fflush(); }' | tee -ia /tmp/debug/stdout.log)
#exec  2> >(awk '{ print strftime("[%Y-%m-%d_%H:%M:%S] "), $0; fflush(); }' | tee -ia /tmp/debug/stderr.log 1>&2)
#exec 19> >(awk '{ print strftime("[%Y-%m-%d_%H:%M:%S] "), $0; fflush(); }' > /tmp/debug/trace.log)
# - mawk version (alias awk='mawk')
#exec   > >(awk -v time=$(date +"[%Y-%m-%d_%H:%M:%S] ") '{ print time, $0; fflush(); }' | tee -ia /tmp/debug/stdout.log)
#exec  2> >(awk -v time=$(date +"[%Y-%m-%d_%H:%M:%S] ") '{ print time, $0; fflush(); }' | tee -ia /tmp/debug/stderr.log 1>&2)
#exec 19> >(awk -v time=$(date +"[%Y-%m-%d_%H:%M:%S] ") '{ print time, $0; fflush(); }' > /tmp/debug/trace.log)
#
#BASH_XTRACEFD="19"
#set -x
#

#================== USER_CONFIG_SETTINGS ===================#

# TODO: naming convention for system vs dsip config files is very confusing
# we should update this to be much more explicit

# Define some defaults and environment variables
FLT_CARRIER=8
FLT_PBX=9
FLT_OUTBOUND=8000
FLT_INBOUND=9000
FLT_LCR_MIN=10000
FLT_FWD_MIN=20000
WITH_SSL=0
WITH_LCR=1
export DEBUG=0
export SERVERNAT=0
export REQ_PYTHON_MAJOR_VER=3
export IPV6_ENABLED=0
export DSIP_SYSTEM_CONFIG_DIR="/etc/dsiprouter"
DSIP_PRIV_KEY="${DSIP_SYSTEM_CONFIG_DIR}/privkey"
export DSIP_KAMAILIO_CONFIG_DIR="${DSIP_PROJECT_DIR}/kamailio"
export DSIP_KAMAILIO_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/kamailio51_dsiprouter.cfg"
export DSIP_DEFAULTS_DIR="${DSIP_KAMAILIO_CONFIG_DIR}/defaults"
export DSIP_CONFIG_FILE="${DSIP_PROJECT_DIR}/gui/settings.py"
export DSIP_RUN_DIR="/var/run/dsiprouter"
export SYSTEM_KAMAILIO_CONFIG_DIR="/etc/kamailio"
export SYSTEM_KAMAILIO_CONFIG_FILE="${SYSTEM_KAMAILIO_CONFIG_DIR}/kamailio.cfg" # will be symlinked
export SYSTEM_RTPENGINE_CONFIG_DIR="/etc/rtpengine"
export SYSTEM_RTPENGINE_CONFIG_FILE="${SYSTEM_RTPENGINE_CONFIG_DIR}/rtpengine.conf"
export PATH_UPDATE_FILE="/etc/profile.d/dsip_paths.sh" # updates paths required
export RTPENGINE_VER="mr6.1.1.1"
export SRC_DIR="/usr/local/src"
export BACKUPS_DIR="/var/backups"
export CLOUD_INSTALL_LOG="/var/log/dsip-cloud-install.log"

# Default MYSQL db root user values
MYSQL_ROOT_DEF_USERNAME="root"
MYSQL_ROOT_DEF_PASSWORD=""
MYSQL_ROOT_DEF_DATABASE="mysql"

# Default SSL options
# If you created your own certs prior to installing set this to match your certs
if [ ${WITH_SSL} -eq 1 ]; then
    SYSTEM_SSL_CERT_DIR="/etc/ssl/certs"                                    # certs general location
    DSIP_SSL_CERT_DIR="${SYSTEM_SSL_CERT_DIR}/$(hostname -f)"               # domain specific cert dir
    DSIP_SSL_KEY="${DSIP_SSL_CERT_DIR}/key.pem"                             # private key
    DSIP_SSL_CHAIN="${DSIP_SSL_CERT_DIR}/chain.pem"                         # full chain cert
    DSIP_SSL_CERT="${DSIP_SSL_CERT_DIR}/cert.pem"                           # full chain + csr cert
    DSIP_SSL_EMAIL="admin@$(hostname -f)"                                   # email in certs (for renewal)
    DSIP_GUI_PROTOCOL="https"                                               # protocol GUI is served on
else
    DSIP_SSL_CERT_DIR=""                                                    # domain specific cert dir
    DSIP_SSL_KEY=""                                                         # private key
    DSIP_SSL_CHAIN=""                                                       # full chain cert
    DSIP_SSL_CERT=""                                                        # full chain + csr cert
    DSIP_SSL_EMAIL=""                                                       # email in certs (for renewal)
    DSIP_GUI_PROTOCOL="http"                                                # protocol GUI is served on
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
export EXTERNAL_IP=$(getExternalIP)
export INTERNAL_IP=$(ip route get 8.8.8.8 | awk 'NR == 1 {print $7}')
export INTERNAL_NET=$(awk -F"." '{print $1"."$2"."$3".*"}' <<<$INTERNAL_IP)

#===========================================================#
DSIP_SERVER_DOMAIN="$(hostname -f)"    # DNS domain we are using

# Get Linux Distro and Version, and normalize values for later use
DISTRO=$(getDisto)
# check downstream Distro's first, then check upstream Distro's if no match
if [[ "$DISTRO" == "amzn" ]]; then
	export DISTRO="amazon"
	export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
elif [[ "$DISTRO" == "ubuntu" ]]; then
	export DISTRO="ubuntu"
	export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
else
    if [ -f /etc/redhat-release ]; then
        export DISTRO="centos"
        export DISTRO_VER=$(cat /etc/redhat-release | cut -d ' ' -f 4 | cut -d '.' -f 1)
    elif [ -f /etc/debian_version ]; then
        export DISTRO="debian"
        export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
    fi
fi

# Check if we are on a VPS Cloud Instance
function setCloudPlatform {
    # 0 == not enabled, 1 == enabled
    export AWS_ENABLED=0
    export DO_ENABLED=0
    export GCE_ENABLED=0
    export AZURE_ENABLED=0
    # -- amazon web service check --
    if isInstanceAMI; then
        export AWS_ENABLED=1
        CLOUD_PLATFORM='AWS'
    else
        # -- digital ocean check --
        if isInstanceDO; then
            export DO_ENABLED=1
            CLOUD_PLATFORM='DO'
        else
            # -- google compute engine check --
            if isInstanceGCE; then
                export GCE_ENABLED=1
                CLOUD_PLATFORM='GCE'
            else
                # -- microsoft azure check --
                if isInstanceAZURE; then
                    export AZURE_ENABLED=1
                    CLOUD_PLATFORM='AZURE'
                else
                    CLOUD_PLATFORM=''
                fi
            fi
        fi
    fi
}

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
| { echo -e "\e[1;49;36m"; cat; echo -e "\e[39;49;00m"; }
}

# Cleanup exported variables on exit
function cleanupAndExit {
    unset DSIP_PROJECT_DIR DSIP_INSTALL_DIR DSIP_KAMAILIO_CONFIG_DIR DSIP_KAMAILIO_CONFIG DSIP_DEFAULTS_DIR SYSTEM_KAMAILIO_CONFIG_DIR DSIP_CONFIG_FILE
    unset REQ_PYTHON_MAJOR_VER DISTRO DISTRO_VER PYTHON_CMD PATH_UPDATE_FILE SYSTEM_RTPENGINE_CONFIG_DIR SYSTEM_RTPENGINE_CONFIG_FILE SERVERNAT
    unset RTPENGINE_VER SRC_DIR DSIP_SYSTEM_CONFIG_DIR BACKUPS_DIR DSIP_RUN_DIR KAM_VERSION CLOUD_INSTALL_LOG DEBUG IPV6_ENABLED
    unset MYSQL_ROOT_PASSWORD MYSQL_ROOT_USERNAME MYSQL_ROOT_DATABASE KAM_DB_HOST KAM_DB_TYPE KAM_DB_PORT KAM_DB_NAME KAM_DB_USER KAM_DB_PASS
    unset RTP_PORT_MIN RTP_PORT_MAX DSIP_PORT EXTERNAL_IP INTERNAL_IP INTERNAL_NET PERL_MM_USE_DEFAULT AWS_ENABLED DO_ENABLED GCE_ENABLED AZURE_ENABLED
    unset -f setPythonCmd
    rm -f /etc/apt/apt.conf.d/local 2>/dev/null
    set +x
    exit $1
}

# check if running as root
function validateRootPriv {
    if (( $(id -u 2>/dev/null) != 0 )); then
        printerr "$0 must be run as root user"
        cleanupAndExit 1
    fi
}

# Validate OS and get supported Kamailio versions
function validateOSInfo {
    if [[ "$DISTRO" == "debian" ]]; then
        case "$DISTRO_VER" in
            9|8)
                if [[ -z "$KAM_VERSION" ]]; then
                   KAM_VERSION=51
                fi
                ;;
            7)
                printerr "Your Operating System Version is DEPRECATED. To ask for support open an issue https://github.com/dOpensource/dsiprouter/"
                cleanupAndExit 1
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
    elif [[ "$DISTRO" == "ubuntu" ]]; then
        case "$DISTRO_VER" in
            16.04)
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

    # export it for external scripts
    export KAM_VERSION
}

# run prior to any cmd being processed
function initialChecks {
    validateRootPriv

    validateOSInfo

    # make sure dirs exist (ones that may not yet exist)
    mkdir -p ${DSIP_SYSTEM_CONFIG_DIR} ${SRC_DIR} ${BACKUPS_DIR} ${DSIP_RUN_DIR}

    if [[ "$DISTRO" == "debian" ]] || [[ "$DISTRO" == "ubuntu" ]]; then
        # comment out cdrom in sources as it can halt install
        sed -i -E 's/(^\w.*cdrom.*)/#\1/g' /etc/apt/sources.list
        # make sure we run package installs unattended
        export DEBIAN_FRONTEND="noninteractive"
        export DEBIAN_PRIORITY="critical"
        # default dpkg to noninteractive modes for install
        (cat << 'EOF'
Dpkg::Options {
"--force-confdef";
"--force-confnew";
}

APT::Get::Fix-Missing "1";
EOF
        ) > /etc/apt/apt.conf.d/local
    fi

    # make perl CPAN installs non interactive
    export PERL_MM_USE_DEFAULT=1

    # grab root db settings from env or set to defaults
    export MYSQL_ROOT_USERNAME=${MYSQL_ROOT_USERNAME:-$MYSQL_ROOT_DEF_USERNAME}
    export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$MYSQL_ROOT_DEF_PASSWORD}
    export MYSQL_ROOT_DATABASE=${MYSQL_ROOT_DATABASE:-$MYSQL_ROOT_DEF_DATABASE}

    # grab kam db settings from env or settings file
    export KAM_DB_HOST=${KAM_DB_HOST:-$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})}
    export KAM_DB_TYPE=${KAM_DB_TYPE:-$(getConfigAttrib 'KAM_DB_TYPE' ${DSIP_CONFIG_FILE})}
    export KAM_DB_PORT=${KAM_DB_PORT:-$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})}
    export KAM_DB_NAME=${KAM_DB_NAME:-$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})}
    export KAM_DB_USER=${KAM_DB_USER:-$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})}
    export KAM_DB_PASS=${KAM_DB_PASS:-$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})}

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
    mkdir -p $(dirname ${PATH_UPDATE_FILE})
    if [[ ! -e "$PATH_UPDATE_FILE" ]]; then
        (cat << 'EOF'
#export PATH="/usr/local/bin${PATH:+:$PATH}"
#export PATH="${PATH:+$PATH:}/usr/sbin"
#export PATH="${PATH:+$PATH:}/sbin"
EOF
        ) > ${PATH_UPDATE_FILE}
    fi

    # minimalistic approach avoids growing duplicates
    # enable (uncomment) and import only what we need
    local PATH_UPDATED=0

    # - sipsak, and future use
    if ! pathCheck /usr/local/bin; then
        sed -i -r 's|^#(export PATH="/usr/local/bin\$\{PATH:\+:\$PATH\}")$|\1|' ${PATH_UPDATE_FILE}
        PATH_UPDATED=1
    fi
    # - rtpengine
    if ! pathCheck /usr/sbin; then
        sed -i -r 's|^#(export PATH="\$\{PATH:\+\$PATH:\}/usr/sbin")$|\1|' ${PATH_UPDATE_FILE}
        PATH_UPDATED=1
    fi
    # - kamailio
    if ! pathCheck /sbin; then
        sed -i -r 's|^#(export PATH="\$\{PATH:\+\$PATH:\}/sbin")$|\1|' ${PATH_UPDATE_FILE}
        PATH_UPDATED=1
    fi

    # import new path definition if it was updated
    (( ${PATH_UPDATED} == 1 )) &&  . ${PATH_UPDATE_FILE}
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
    setConfigAttrib 'KAM_KAMCMD_PATH' "$(type -p kamcmd)" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'KAM_CFG_PATH' "$SYSTEM_KAMAILIO_CONFIG_FILE" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'RTP_CFG_PATH' "$SYSTEM_KAMAILIO_CONFIG_FILE" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_PRIV_KEY' "$DSIP_PRIV_KEY" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_SSL_KEY' "$DSIP_SSL_KEY" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_SSL_CERT' "$DSIP_SSL_CERT" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_SSL_EMAIL' "$DSIP_SSL_EMAIL" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_PROTO' "$DSIP_GUI_PROTOCOL" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'CLOUD_PLATFORM' "$CLOUD_PLATFORM" ${DSIP_CONFIG_FILE} -q
}

# update settings file based on cmdline args
# should be used prior to app execution
function updatePythonRuntimeSettings {
    if (( ${DEBUG} == 1 )); then
        setConfigAttrib 'DEBUG' 'True' ${DSIP_CONFIG_FILE}
    else
        setConfigAttrib 'DEBUG' 'False' ${DSIP_CONFIG_FILE}
    fi
}

function configureSSL {
    ## Configure self signed certificate
  
    mkdir -p ${DSIP_SSL_CERT_DIR}
    openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out ${DSIP_SSL_CERT} -keyout ${DSIP_SSL_KEY} -subj "/C=US/ST=MI/L=Detroit/O=dSIPRouter/CN=`hostname`"
}

# updates and settings in kam config that may change
# should be run after changing settings.py or change in network configurations
# TODO: add support for hot reloading of kam settings. i.e. using kamcmd cfg.sets <key> <val> / kamcmd cfg.seti <key> <val>
# TODO: support configuring separate asterisk realtime db conns / clusters (would need separate setting in settings.py)
function updateKamailioConfig {
    local DSIP_API_BASEURL="$(getConfigAttrib 'DSIP_API_PROTO' ${DSIP_CONFIG_FILE})://$(getConfigAttrib 'DSIP_API_HOST' ${DSIP_CONFIG_FILE}):$(getConfigAttrib 'DSIP_API_PORT' ${DSIP_CONFIG_FILE})"
    local DSIP_API_TOKEN=${DSIP_API_TOKEN:-$(decryptConfigAttrib 'DSIP_API_TOKEN')}
    local DEBUG=${DEBUG:-$(getConfigAttrib 'DEBUG' ${DSIP_CONFIG_FILE})}
    local ROLE=${ROLE:-$(getConfigAttrib 'ROLE' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_GW_ENABLED=${TELEBLOCK_GW_ENABLED:-$(getConfigAttrib 'TELEBLOCK_GW_ENABLED' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_GW_IP=${TELEBLOCK_GW_IP:-$(getConfigAttrib 'TELEBLOCK_GW_IP' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_GW_PORT=${TELEBLOCK_GW_PORT:-$(getConfigAttrib 'TELEBLOCK_GW_PORT' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_MEDIA_IP=${TELEBLOCK_MEDIA_IP:-$(getConfigAttrib 'TELEBLOCK_MEDIA_IP' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_MEDIA_PORT=${TELEBLOCK_MEDIA_PORT:-$(getConfigAttrib 'TELEBLOCK_MEDIA_PORT' ${DSIP_CONFIG_FILE})}

    setKamailioConfigIP 'INTERNAL_IP_ADDR' "${INTERNAL_IP}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigIP 'INTERNAL_IP_NET' "${INTERNAL_NET}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigIP 'EXTERNAL_IP_ADDR' "${EXTERNAL_IP}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'server.api_server' "${DSIP_API_BASEURL}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'server.api_token' "${DSIP_API_TOKEN}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'server.role' "${ROLE}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.gw_enabled' "${TELEBLOCK_GW_ENABLED}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.gw_ip' "${TELEBLOCK_GW_IP}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.gw_port' "${TELEBLOCK_GW_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.media_ip' "${TELEBLOCK_MEDIA_IP}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.media_port' "${TELEBLOCK_MEDIA_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    if [[ "$DEBUG" == "True" ]]; then
        enableKamailioConfigAttrib 'WITH_DEBUG' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_DEBUG' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi

    # check for cluster db connection and set kam db config settings appropriately
    # note: the '@' symbol must be escaped in perl regex
    if printf '%s' "$KAM_DB_HOST" | grep -q -oP '(\[.*\]|.*,.*)'; then
        # db connection is clustered
        enableKamailioConfigAttrib 'WITH_DBCLUSTER' ${DSIP_KAMAILIO_CONFIG_FILE}

        # TODO: support different type/user/pass/port/name per connection
        # TODO: support multiple clusters
        local KAM_DB_CLUSTER_CONNS=""
        local KAM_DB_CLUSTER_MODES=""
        local KAM_DB_CLUSTER_NODES=$(printf '%s' "$KAM_DB_HOST" | tr -d '[]'"'"'"' | tr ',' ' ')

        local i=1
        for NODE in $KAM_DB_CLUSTER_NODES; do
            KAM_DB_CLUSTER_CONNS+="modparam('db_cluster', 'connection', 'c${i}=>${KAM_DB_TYPE}://${KAM_DB_USER}:${KAM_DB_PASS}\\@${NODE}:${KAM_DB_PORT}/${KAM_DB_NAME}')\n"
            KAM_DB_CLUSTER_MODES+="c${i}=9r9r;"
            i=$((i+1))
        done
        KAM_DB_CLUSTER_MODES="modparam('db_cluster', 'cluster', 'dbcluster=>${KAM_DB_CLUSTER_MODES}')"

        perl -e "\$dbcluster='${KAM_DB_CLUSTER_CONNS}${KAM_DB_CLUSTER_MODES}';" \
            -0777 -i -pe 's~(modparam\("db_cluster", "connection".*\s)+(modparam\("db_cluster", "cluster".*)~${dbcluster}~gm' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        local DBURL="${KAM_DB_TYPE}://${KAM_DB_USER}:${KAM_DB_PASS}@${KAM_DB_HOST}:${KAM_DB_PORT}/${KAM_DB_NAME}"
        setKamailioConfigDburl "DBURL" "${DBURL}" ${DSIP_KAMAILIO_CONFIG_FILE}
        setKamailioConfigDburl "SQLCONN_KAM" "kam=>${DBURL}" ${DSIP_KAMAILIO_CONFIG_FILE}
        setKamailioConfigDburl "SQLCONN_AST" "asterisk=>${DBURL}" ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
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
    local DSIP_ID=${DSIP_ID:-$(getConfigAttrib 'DSIP_ID' ${DSIP_CONFIG_FILE})}

    # copy of template kamailio configuration to dsiprouter system config dir
    cp -f ${DSIP_KAMAILIO_CONFIG_DIR}/kamailio51_dsiprouter.cfg ${DSIP_KAMAILIO_CONFIG_FILE}
    # set kamailio version in kam config
    sed -i -e "s~KAMAILIO_VERSION~${KAM_VERSION}~" ${DSIP_KAMAILIO_CONFIG_FILE}

    # make sure kamailio user exists
    mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_ROOT_DATABASE \
        -e "GRANT ALL PRIVILEGES ON $KAM_DB_NAME.* TO '$KAM_DB_USER'@'localhost' IDENTIFIED BY '$KAM_DB_PASS';"

    # Install schema for drouting module
    mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME \
        -e "delete from version where table_name in ('dr_gateways','dr_groups','dr_gw_lists','dr_custom_rules','dr_rules')"
    mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME \
        -e "drop table if exists dr_gateways,dr_groups,dr_gw_lists,dr_custom_rules,dr_rules"
    if [ -e  /usr/share/kamailio/mysql/drouting-create.sql ]; then
        mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < /usr/share/kamailio/mysql/drouting-create.sql
    else
        sqlscript=$(find / -name '*drouting-create.sql' | grep 'mysql' | head -1)
        mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < $sqlscript
    fi

    # Install schema for custom LCR logic
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < ${DSIP_DEFAULTS_DIR}/lcr.sql
    
    # Install schema for custom MaintMode logic
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < ${DSIP_DEFAULTS_DIR}/dsip_maintmode.sql
    
    # Install schema for Call Limit 
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < ${DSIP_DEFAULTS_DIR}/dsip_calllimit.sql
    
    # Install schema for Notifications 
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < ${DSIP_DEFAULTS_DIR}/dsip_notification.sql
    
    # Install schema for gw2gwgroup
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < ${DSIP_DEFAULTS_DIR}/dsip_gw2gwgroup.sql

    # Install schema for dsip_settings
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < ${DSIP_DEFAULTS_DIR}/dsip_settings.sql

    # Install schema for dsip_hardfwd and dsip_failfwd and dsip_prefix_mapping
    sed -e "s|DSIP_ID_REPLACE|${DSIP_ID}|g" ${DSIP_DEFAULTS_DIR}/dsip_forwarding.sql |
        mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME

    # Install schema for custom dr_gateways logic
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < ${DSIP_DEFAULTS_DIR}/dr_gateways.sql

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
#                WHERE TABLE_SCHEMA = '$KAM_DB_NAME' \
#                AND TABLE_NAME IN($SQL_TABLES);"
#        )
#        for t in "$@"; do
#            mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME \
#                -e "ALTER TABLE $t AUTO_INCREMENT=$INCREMENT"
#        done
#    }
#
#    # reset auto incrementers for related tables
#    resetIncrementers "dr_gw_lists"
#    resetIncrementers "uacreg"

    # Import Default Carriers
    if [ -e $(type -P mysqlimport) ]; then
        mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME -e "delete from address where grp=$FLT_CARRIER"

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
        mysqlimport --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $KAM_DB_NAME /tmp/defaults/address.csv
        mysqlimport --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $KAM_DB_NAME ${DSIP_DEFAULTS_DIR}/dr_gw_lists.csv
        mysqlimport --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --fields-terminated-by=',' --ignore-lines=0  \
            -L $KAM_DB_NAME /tmp/defaults/uacreg.csv
        mysqlimport --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $KAM_DB_NAME /tmp/defaults/dr_gateways.csv
        mysqlimport --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $KAM_DB_NAME /tmp/defaults/dr_rules.csv

        rm -rf /tmp/defaults
    fi

    # Fix the mpath
    fixMPATH

    # Enable SERVERNAT
    if [ "$SERVERNAT" == "1" ]; then
        enableSERVERNAT
    fi

    if (( ${WITH_LCR} == 1 )); then
        enableKamailioConfigAttrib 'WITH_LCR' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_LCR' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi

    # Backup kamcfg and link the dsiprouter kamcfg
    cp -f ${SYSTEM_KAMAILIO_CONFIG_FILE} ${SYSTEM_KAMAILIO_CONFIG_FILE}.$(date +%Y%m%d_%H%M%S)
    rm -f ${SYSTEM_KAMAILIO_CONFIG_FILE}
    ln -sf ${DSIP_KAMAILIO_CONFIG_FILE} ${SYSTEM_KAMAILIO_CONFIG_FILE}

    # kamcfg will contain plaintext passwords / tokens
    # make sure we give it reasonable permissions
    chown root:kamailio ${DSIP_KAMAILIO_CONFIG_FILE}
    chmod 0640 ${DSIP_KAMAILIO_CONFIG_FILE}
}

function enableSERVERNAT {
    enableKamailioConfigAttrib 'WITH_SERVERNAT' ${DSIP_KAMAILIO_CONFIG_FILE}

    printwarn "SERVERNAT is enabled - Restarting Kamailio is required"
    printwarn "You can restart it by executing: systemctl restart kamailio"
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


# Install the RTPEngine from sipwise
function installRTPEngine {
    local RTP_UPDATE_OPTS=""

    cd ${DSIP_PROJECT_DIR}

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]; then
        printwarn "RTPEngine is already installed"
        return
    fi

    printdbg "Attempting to install RTPEngine..."
    ./rtpengine/${DISTRO}/install.sh install
    ret=$?
    if [ $ret -eq 0 ]; then
        printdbg "configuring RTPEngine service"
    elif [ $ret -eq 2 ]; then
        printwarn "RTPEngine install waiting on reboot"
        cleanupAndExit 0
    else
        printerr "RTPEngine install failed"
        cleanupAndExit 1
    fi

    # update rtpengine configs on reboot
    if (( ${SERVERNAT} == 1 )); then
        RTP_UPDATE_OPTS="-servernat"
    fi
    addInitCmd "${DSIP_PROJECT_DIR}/dsiprouter.sh updatertpconfig $RTP_UPDATE_OPTS"
    addDependsOnInit "rtpengine.service"

    # Restart RTPEngine with the new configurations
    systemctl restart rtpengine
    if systemctl is-active --quiet rtpengine; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled
        printdbg "------------------------------------"
        pprint "RTPEngine Installation is complete!"
        printdbg "------------------------------------"
    else
        printerr "RTPEngine install failed"
        cleanupAndExit 1
    fi
}

# Remove RTPEngine
function uninstallRTPEngine {
    cd ${DSIP_PROJECT_DIR}

    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]; then
        printwarn "RTPEngine is not installed! - uninstalling anyway to be safe"
    fi

    printdbg "Attempting to uninstall RTPEngine..."
    ./rtpengine/$DISTRO/install.sh uninstall

    if [ $? -ne 0 ]; then
        printerr "RTPEngine uninstall failed"
        cleanupAndExit 1
    fi

    # remove rtpengine service dependencies
    removeInitCmd "dsiprouter.sh updatertpconfig"
    removeDependsOnInit "rtpengine.service"

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled

    printdbg "RTPEngine was uninstalled"
}

# Enable RTP within the Kamailio configuration so that it uses the RTPEngine
function enableRTP {
    disableKamailioConfigAttrib 'WITH_NAT' ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamailio.cfg
}

# Disable RTP within the Kamailio configuration so that it doesn't use the RTPEngine
function disableRTP {
    enableKamailioConfigAttrib 'WITH_NAT' ${SYSTEM_KAMAILIO_CONFIG_DIR}/kamailio.cfg
}

# TODO: allow password changes on cloud instances (remove password reset after image creation)
# we should be starting the web server as root and dropping root privilege after
# this is standard practice, but we would have to consider file permissions
# it would be easier to manage if we moved dsiprouter configs to /etc/dsiprouter
function installDsiprouter {
    cd ${DSIP_PROJECT_DIR}

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]; then
        printwarn "dSIPRouter is already installed"
        return
    fi

	printdbg "Attempting to install dSIPRouter..."
    ./dsiprouter/${DISTRO}/${DISTRO_VER}.sh install

	if [ $? -ne 0 ]; then
	    printerr "dSIPRouter install failed"
	    cleanupAndExit 1
	else
	    printdbg "Configuring dSIPRouter settings"
	fi

 	setPythonCmd
    if [ $? -ne 0 ]; then
        printerr "dSIPRouter install failed"
        cleanupAndExit 1
    fi

    # add dsiprouter.sh to the path
    ln -s ${DSIP_PROJECT_DIR}/dsiprouter.sh /usr/local/bin/dsiprouter
    # make sure current python version is in the path
    # required in dsiprouter.py shebang (will fail startup without)
    ln -s ${PYTHON_CMD} "/usr/local/bin/python${REQ_PYTHON_MAJOR_VER}"
    # configure dsiprouter modules
    installModules
    # set some defaults in settings.py
    configurePythonSettings

	# configure SSL
    if [ ${WITH_SSL} -eq 1 ]; then
        configureSSL
    fi

    # for cloud images the instance-id may change (could be a clone)
    # add to startup process a password reset to ensure its set correctly
    if (( $AWS_ENABLED == 1 )); then
        addInitCmd "${DSIP_PROJECT_DIR}/dsiprouter.sh resetpassword"
        addDependsOnInit "dsiprouter.service"

        # Required changes for Debian-based AMI's
        if [[ $DISTRO == "debian" ]] || [[ $DISTRO == "ubuntu" ]]; then
            # Remove debian-sys-maint password for initial AMI scan
            sed -i "s/password =.*/password = /g" /etc/mysql/debian.cnf

            # Change default password for debian-sys-maint to instance-id at next boot
            # we must also change the corresponding password in /etc/mysql/debian.cnf
            # to comply with AWS AMI image standards
            # this must run at startup as well so create temp script and add to dsip-init
            (cat << EOF
#!/usr/bin/env bash

# declare any constants imported functions rely on
DSIP_INIT_FILE="$DSIP_INIT_FILE"

# declare imported functions from library
$(declare -f isInstanceAMI)
$(declare -f isInstanceDO)
$(declare -f isInstanceGCE)
$(declare -f isInstanceAZURE)
$(declare -f getInstanceID)
$(declare -f removeInitCmd)

# reset debian user password and remove dsip-init startup cmd
INSTANCE_ID=\$(getInstanceID)
mysql -e "DROP USER 'debian-sys-maint'@'localhost';
    CREATE USER 'debian-sys-maint'@'localhost' IDENTIFIED BY '\${INSTANCE_ID}';
    GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '\${INSTANCE_ID}';
    FLUSH PRIVILEGES;"

sed -i "s|password =.*|password = \${INSTANCE_ID}|g" /etc/mysql/debian.cnf
removeInitCmd '.reset_debiansys_user.sh'
rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.reset_debiansys_user.sh

exit 0
EOF
            ) > ${DSIP_SYSTEM_CONFIG_DIR}/.reset_debiansys_user.sh
            # note that the script will remove itself after execution
            chmod +x ${DSIP_SYSTEM_CONFIG_DIR}/.reset_debiansys_user.sh
            addInitCmd "$(type -P bash) -c '${DSIP_SYSTEM_CONFIG_DIR}/.reset_debiansys_user.sh >> ${CLOUD_INSTALL_LOG} 2>&1'"
        fi

    # rest of the cloud providers only need password reset to instance id
    #elif (( $DO_ENABLED == 1 )) || (( $GCE_ENABLED == 1 )) || (( $AZURE_ENABLED == 1 )); then
    #    addInitCmd "${DSIP_PROJECT_DIR}/dsiprouter.sh resetpassword"
    #    addDependsOnInit "dsiprouter.service"
    fi

    # Generate dsip private key (used for encryption across services)
    ${PYTHON_CMD} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); from util.security import AES_CTR; AES_CTR.genKey()"

    # Generate ipc access password
    ${PYTHON_CMD} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); from util.security import setCreds, get_random_bytes; setCreds(ipc_creds=get_random_bytes(64))"

    # TODO: merge these functions into setCredentials
    # Set kam db pass
    ${PYTHON_CMD} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); from util.security import setCreds; setCreds(kam_creds='${KAM_DB_PASS}')"

    # Generate the API token
    generateAPIToken
    
    # Generate a unique admin password
    generatePassword

    # Update db settings table
    ${PYTHON_CMD} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); from database import updateDsipSettingsTable; updateDsipSettingsTable()"

    # update kamailio config with new settings
    updateKamailioConfig
    systemctl restart kamailio

    # Restrict access to settings and private key
    chown root:root ${DSIP_PRIV_KEY}
    chmod 0400 ${DSIP_PRIV_KEY}
    chown root:root ${DSIP_CONFIG_FILE}
    chmod 0600 ${DSIP_CONFIG_FILE}

    # custom dsiprouter MOTD banner for ssh logins
    updateBanner

    # Restart dSIPRouter with new configurations
    systemctl restart dsiprouter
    if systemctl is-active --quiet dsiprouter; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled
        printdbg "-------------------------------------"
        pprint "dSIPRouter Installation is complete! "
        printdbg "-------------------------------------"
    else
        printerr "dSIPRouter install failed" && cleanupAndExit 1
    fi
}

function uninstallDsiprouter {
    cd ${DSIP_PROJECT_DIR}

    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]; then
        printwarn "dSIPRouter is not installed or failed during install - uninstalling anyway to be safe"
    fi

    # stop the process
    systemctl stop dsiprouter

    printdbg "Attempting to uninstall dSIPRouter UI..."
    ./dsiprouter/$DISTRO/$DISTRO_VER.sh uninstall

    if [ $? -ne 0 ]; then
        printerr "dsiprouter uninstall failed"
        cleanupAndExit 1
    fi

    # for AMI images remove dsip-init service dependency
    if (( $AWS_ENABLED == 1 )) || (( $DO_ENABLED == 1 )) || (( $GCE_ENABLED == 1 )) || (( $AZURE_ENABLED == 1 )); then
        removeInitCmd "dsiprouter.sh resetpassword"
        removeDependsOnInit "dsiprouter.service"
    fi

    # Remove crontab entry
    echo "Removing crontab entry"
    cronRemove 'dsiprouter_cron.py'

    # Remove dsip private key
    rm -f ${DSIP_PRIV_KEY}

    # revert to previous MOTD ssh login banner
    revertBanner

    # remove dsiprouter.sh from the path
    rm -f /usr/local/bin/dsiprouter

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled

    printdbg "dSIPRouter was uninstalled"
}

function installKamailio {
    cd ${DSIP_PROJECT_DIR}

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
        printwarn "kamailio is already installed"
        return
    fi

    printdbg "Attempting to install Kamailio..."
    ./kamailio/${DISTRO}/${DISTRO_VER}.sh install ${KAM_VERSION} ${DSIP_PORT}
    if [ $? -eq 0 ]; then
        configureKamailio
        updateKamailioConfig
    else
        printerr "kamailio install failed"
        cleanupAndExit 1
    fi

    # update kam configs on reboot
    addInitCmd "${DSIP_PROJECT_DIR}/dsiprouter.sh updatekamconfig"
    addDependsOnInit "kamailio.service"

    # Restart Kamailio with the new configurations
    systemctl restart kamailio
    if systemctl is-active --quiet kamailio; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled
        printdbg "-----------------------------------"
        pprint "Kamailio Installation is complete!"
        printdbg "-----------------------------------"
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

    # stop the process
    systemctl stop kamailio

    printdbg "Attempting to uninstall Kamailio..."
    ./kamailio/$DISTRO/$DISTRO_VER.sh uninstall ${KAM_VERSION} ${DSIP_PORT} ${PYTHON_CMD}

    if [ $? -ne 0 ]; then
        printerr "kamailio uninstall failed"
        cleanupAndExit 1
    fi

    # remove kam service dependencies
    removeInitCmd "dsiprouter.sh updatekamconfig"
    removeDependsOnInit "kamailio.service"

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

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.sipsakinstalled" ]; then
        printwarn "SipSak is already installed"
        return
    else
        printdbg "Attempting to install SipSak"
    fi

    # Install sipsak requirements
    if cmdExists 'apt'; then
        apt-get install -y make gcc g++ automake autoconf openssl check git dirmngr pkg-config dh-autoreconf
    elif cmdExists 'yum'; then
        yum install -y make gcc gcc-c++ automake autoconf openssl check git
    fi

    # Install testing requirements (will move this in the future)
    if cmdExists 'apt'; then
        apt-get install -y perl
    elif cmdExists 'yum'; then
        yum install -y perl
    fi
    curl -L http://cpanmin.us | perl - --self-upgrade
    cpanm URI::Escape

    # compile and install from src
    rm -rf ${SRC_DIR}/sipsak 2>/dev/null
    git clone https://github.com/nils-ohlmeier/sipsak.git ${SRC_DIR}/sipsak

    cd ${SRC_DIR}/sipsak
    autoreconf --install
    ./configure
    make
    make install
    ret=$?

    if [ $ret -eq 0 ]; then
        pprint "SipSak was installed"
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.sipsakinstalled
    else
        printerr "SipSak install failed.. continuing without it"
    fi

	cd ${START_DIR}
}

# Remove Sipsak from the machine completely
uninstallSipsak() {
    local START_DIR="$(pwd)"

    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.sipsakinstalled" ]; then
        printwarn "sipsak is not installed or failed during install - uninstalling anyway to be safe"
    fi

    if [ -d ${SRC_DIR}/sipsak ]; then
        cd ${SRC_DIR}/sipsak
        make uninstall
        rm -rf ${SRC_DIR}/sipsak
    fi

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.sipsakinstalled

    cd ${START_DIR}
}

function start {
    cd ${DSIP_PROJECT_DIR}

    # propagate settings to the app config
    updatePythonRuntimeSettings

    # Start Kamailio if it was installed
    if [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled ]; then
        systemctl start kamailio
        # Make sure process is still running
        if ! systemctl is-active --quiet kamailio; then
            printerr "Unable to start Kamailio"
            cleanupAndExit 1
        else
            pprint "Kamailio was started"
        fi
    fi

    # Start RTPEngine if it was installed
    if [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled ]; then
        systemctl start rtpengine
        # Make sure process is still running
        if ! systemctl is-active --quiet rtpengine; then
            printerr "Unable to start RTPEngine"
            cleanupAndExit 1
        else
            pprint "RTPEngine was started"
        fi
    fi

    # Start the dSIPRouter if it was installed
    if [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled ]; then
        if [ $DEBUG -eq 1 ]; then
            # keep it in the foreground, only used for debugging issues
            ${PYTHON_CMD} ./gui/dsiprouter.py runserver
            # Make sure process is still running
            PID=$!
            if ! ps -p ${PID} &>/dev/null; then
                printerr "Unable to start dSIPRouter"
                cleanupAndExit 1
            else
                pprint "dSIPRouter was started under pid ${PID}"
                echo "$PID" > ${DSIP_RUN_DIR}/dsiprouter.pid
            fi
        else
            # normal startup, fork as background process
            systemctl start dsiprouter
            # Make sure process is still running
            if ! systemctl is-active --quiet dsiprouter; then
                printerr "Unable to start dSIPRouter"
                cleanupAndExit 1
            else
                pprint "dSIPRouter was started"
            fi
        fi
    fi
}


function stop {
    cd ${DSIP_PROJECT_DIR}

    # propagate settings to the app config
    updatePythonRuntimeSettings


    # Stop Kamailio if it was installed
    if [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled ]; then
        systemctl stop kamailio
        # Make sure process is not running
        if systemctl is-active --quiet kamailio; then
            printerr "Unable to stop Kamailio"
            cleanupAndExit 1
        else
            pprint "Kamailio was stopped"
        fi
    fi

    # Stop RTPEngine if it was installed
    if [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled ]; then
        systemctl stop rtpengine
        # Make sure process is not running
        if systemctl is-active --quiet rtpengine; then
            printerr "Unable to stop RTPEngine"
            cleanupAndExit 1
        else
            pprint "RTPEngine was stopped"
        fi
    fi

    # Stop the dSIPRouter if it was installed
    if [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled ]; then
        # normal startup, fork as background process
        systemctl stop dsiprouter
        # Make sure process is not running
        if systemctl is-active --quiet dsiprouter; then
            printerr "Unable to stop dSIPRouter"
            cleanupAndExit 1
        else
            pprint "dSIPRouter was stopped"
        fi
    fi
}

function displayLoginInfo {
    local DSIP_USERNAME=${DSIP_USERNAME:-$(getConfigAttrib 'DSIP_USERNAME' ${DSIP_CONFIG_FILE})}
    local DSIP_PASSWORD=${DSIP_PASSWORD:-"<HASH CAN NOT BE UNDONE> (reset password if you forgot it)"}
    local DSIP_API_TOKEN=${DSIP_API_TOKEN:-$(decryptConfigAttrib 'DSIP_API_TOKEN')}
    local KAM_DB_USER=${KAM_DB_USER:-$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})}
    local KAM_DB_PASS=${KAM_DB_PASS:-$(decryptConfigAttrib 'KAM_DB_PASS')}

    printf '\n'
    printdbg "Your systems credentials are below (keep in a safe place):"

    pprint "dSIPRouter Username: ${DSIP_USERNAME}"
    pprint "dSIPRouter Password: ${DSIP_PASSWORD}"

    pprint "Kamailio DB Username: ${KAM_DB_USER}"
    pprint "Kamailio DB Password: ${KAM_DB_PASS}"

    pprint "dSIPRouter API Token: ${DSIP_API_TOKEN}"

    # Tell them how to access the URL
    printf '\n'
    printdbg "You can access the dSIPRouter web gui by going to:"
    pprint "External IP: ${DSIP_GUI_PROTOCOL}://${EXTERNAL_IP}:${DSIP_PORT}"

    if [ "$EXTERNAL_IP" != "$INTERNAL_IP" ];then
        pprint "Internal IP: ${DSIP_GUI_PROTOCOL}://${INTERNAL_IP}:${DSIP_PORT}"
    fi
    printf '\n'
}

function resetPassword {
    printwarn "The admin account password has been reset"

    # generate the new password and display login info
    generatePassword
    displayLoginInfo

    printwarn "Restart dSIPRouter to make the password active!"
}

# Generate password and set it in the ${DSIP_CONFIG_FILE} DSIP_PASSWORD field
function generatePassword {
    if (( $AWS_ENABLED == 1 )) || (( $DO_ENABLED == 1 )) || (( $GCE_ENABLED == 1 )) || (( $AZURE_ENABLED == 1 )); then
        DSIP_PASSWORD=$(getInstanceID)
    else
        DSIP_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)
    fi

    ${PYTHON_CMD} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); from util.security import setCreds; setCreds(dsip_creds='${DSIP_PASSWORD}')"
}

function generateAPIToken {
	DSIP_API_TOKEN=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 64 | head -n 1)
    ${PYTHON_CMD} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); from util.security import setCreds; setCreds(api_creds='${DSIP_API_TOKEN}')"
}

# updates credentials in dsip / kam config files / kam db
# also sets credentials to variables for latter commands
# TODO: should we update kamailio grants in mysql to match updates??
function setCredentials {
    printdbg "Setting credentials"

    local SET_DSIP_CREDS="${SET_DSIP_CREDS}"
    local SET_API_CREDS="${SET_API_CREDS}"
    local SET_KAM_CREDS="${SET_KAM_CREDS}"
    local SET_MAIL_CREDS="${SET_MAIL_CREDS}"
    local SET_DSIP_USER="${SET_DSIP_USER}"
    local SET_KAM_USER="${SET_KAM_USER}"
    local SET_MAIL_USER="${SET_MAIL_USER}"
    local LOAD_SETTINGS_FROM=${LOAD_SETTINGS_FROM:-$(getConfigAttrib 'LOAD_SETTINGS_FROM' ${DSIP_CONFIG_FILE})}
    local DSIP_ID=${DSIP_ID:-$(getConfigAttrib 'DSIP_ID' ${DSIP_CONFIG_FILE})}

    if [[ -n "${SET_DSIP_CREDS}" ]]; then
        DSIP_PASSWORD="$SET_DSIP_CREDS"
    fi
    if [[ -n "${SET_API_CREDS}" ]]; then
        DSIP_API_TOKEN="$SET_API_CREDS"
    fi
    if [[ -n "${SET_MAIL_CREDS}" ]]; then
        MAIL_PASSWORD="$SET_MAIL_CREDS"
    fi
    if [[ -n "${SET_KAM_CREDS}" ]]; then
        KAM_DB_PASS="$SET_KAM_CREDS"
    fi
    if [[ -n "${SET_DSIP_USER}" ]]; then
        if [[ "${LOAD_SETTINGS_FROM}" == "db" ]]; then
            mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME \
                -e "update dsip_settings set DSIP_USERNAME='${SET_DSIP_USER}' where DSIP_ID=${DSIP_ID}"
        else
            setConfigAttrib 'DSIP_USERNAME' "$SET_DSIP_USER" ${DSIP_CONFIG_FILE} -q
        fi
        DSIP_USERNAME="$SET_DSIP_USER"
    fi
    if [[ -n "${SET_KAM_USER}" ]]; then
        if [[ "${LOAD_SETTINGS_FROM}" == "db" ]]; then
            mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME \
                -e "update dsip_settings set KAM_DB_USER='${SET_KAM_USER}' where DSIP_ID=${DSIP_ID}"
        else
            setConfigAttrib 'KAM_DB_USER' "$SET_KAM_USER" ${DSIP_CONFIG_FILE} -q
        fi
        KAM_DB_USER="$SET_KAM_USER"
    fi
    if [[ -n "${SET_MAIL_USER}" ]]; then
        if [[ "${LOAD_SETTINGS_FROM}" == "db" ]]; then
            mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME \
                -e "update dsip_settings set MAIL_USERNAME='${SET_MAIL_USER}' where DSIP_ID=${DSIP_ID}"
        else
            setConfigAttrib 'MAIL_USERNAME' "$SET_MAIL_USER" ${DSIP_CONFIG_FILE} -q
        fi
        MAIL_USERNAME="$SET_MAIL_USER"
    fi

    ${PYTHON_CMD} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); from util.security import setCreds; from util.shmem import sendSyncSettingsSignal; \
        setCreds(dsip_creds='${SET_DSIP_CREDS}', api_creds='${SET_API_CREDS}', kam_creds='${SET_KAM_CREDS}', mail_creds='${SET_MAIL_CREDS}'); sendSyncSettingsSignal()"

    if [[ -n "${SET_API_CREDS}" || -n "${SET_KAM_CREDS}" || -n "${SET_KAM_USER}" ]]; then
        updateKamailioConfig
        printwarn "Restart Kamailio to make credentials active"
    else
        printdbg "dSIPRouter credentials have been updated"
    fi
}

# update MOTD banner for ssh login
function updateBanner {
    mkdir -p /etc/update-motd.d

    # don't write multiple times
    if [ -f /etc/update-motd.d/00-dsiprouter ]; then
        return
    fi

    # move old banner files
    cp -f /etc/motd ${DSIP_SYSTEM_CONFIG_DIR}/motd.bak
    cat /dev/null > /etc/motd
    chmod -x /etc/update-motd.d/*

    # add our custom banner
    (cat << EOF
#!/usr/bin/env bash

# redefine variables and functions here
ESC_SEQ="$ESC_SEQ"
ANSI_NONE="$ANSI_NONE"
ANSI_GREEN="$ANSI_GREEN"
$(declare -f printdbg)
$(declare -f getConfigAttrib)
$(declare -f displayLogo)

# updated variables on login
DSIP_PORT=\$(getConfigAttrib 'DSIP_PORT' ${DSIP_CONFIG_FILE})
EXTERNAL_IP=\$(getConfigAttrib 'EXTERNAL_IP_ADDR' ${DSIP_CONFIG_FILE})
INTERNAL_IP=\$(getConfigAttrib 'INTERNAL_IP_ADDR' ${DSIP_CONFIG_FILE})
DSIP_GUI_PROTOCOL=\$(getConfigAttrib 'DSIP_PROTO' ${DSIP_CONFIG_FILE})
VERSION=\$(getConfigAttrib 'VERSION' ${DSIP_CONFIG_FILE})

# displaying information to user
clear
displayLogo
printdbg "Version: \$VERSION"
printf '\n'
printdbg "You can access the dSIPRouter GUI by going to:"
printdbg "External IP: \${DSIP_GUI_PROTOCOL}://\${EXTERNAL_IP}:\${DSIP_PORT}"
if [ "\$EXTERNAL_IP" != "\$INTERNAL_IP" ];then
    printdbg "Internal IP: \${DSIP_GUI_PROTOCOL}://\${INTERNAL_IP}:\${DSIP_PORT}"
fi
printf '\n'

exit 0
EOF
    ) > /etc/update-motd.d/00-dsiprouter

    chmod +x /etc/update-motd.d/00-dsiprouter

    # for debian < v9 we have to update it the dynamic motd location
    if [[ "$DISTRO" == "debian" && $DISTRO_VER -lt 9 ]]; then
        sed -i -r 's|^(session.*pam_motd\.so.*motd=/run/motd).*|\1|' /etc/pam.d/sshd
    # for centos7 and debian we have to update it 'manually'
    elif [[ "$DISTRO" == "centos" ]]; then
        /etc/update-motd.d/00-dsiprouter > /etc/motd
        cronAppend "0 * * * *  /etc/update-motd.d/00-dsiprouter > /etc/motd"
    fi
}

# revert to old MOTD banner for ssh logins
function revertBanner {
    mv -f ${DSIP_SYSTEM_CONFIG_DIR}/motd.bak /etc/motd
    rm -f /etc/update-motd.d/00-dsiprouter
    chmod +x /etc/update-motd.d/*

    # remove cron entry for centos7 and debian < v9
    if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "debian" && $DISTRO_VER -lt 9 ]]; then
        cronRemove '/etc/update-motd.d/00-dsiprouter'
    fi
}

# =================
# dsip-init service
# =================
#
# Initially the init service does nothing but startup required services on boot
#
# 1. Primary usage is to ensure required services are started for dependent services
# 2. Secondary usage is to add startup commands to run on reboot (init cmds for services)
#
# This service will ensure the following services are started:
# - networking
# - syslog
# - mysql
function createInitService {
    # imported from dsip_lib.sh
    local DSIP_INIT_FILE="$DSIP_INIT_FILE"

    # only create if it doesn't exist
    if [ -e "$DSIP_INIT_FILE" ]; then
        printwarn "dsip-init service already exists"
        return
    else
        printdbg "creating dsip-init service"
    fi

    (cat << 'EOF'
[Unit]
Description=dSIPRouter Init Service
Wants=network-online.target syslog.service mysql.service
After=network.target network-online.target syslog.service mysql.service
Before=

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=true
TimeoutSec=0

[Install]
WantedBy=multi-user.target
EOF
    ) > ${DSIP_INIT_FILE}

    # set default permissions
    chmod 0644 ${DSIP_INIT_FILE}

    # enable service and start on boot
    systemctl daemon-reload
    systemctl enable dsip-init
    # startup with required services
    systemctl start dsip-init
}

function removeInitService {
    # imported from dsip_lib.sh
    local DSIP_INIT_FILE="$DSIP_INIT_FILE"

    systemctl stop dsip-init
    rm -f $DSIP_INIT_FILE
    systemctl daemon-reload

    printdbg "dsip-init service removed"
}

function upgrade {
    # TODO: set / handle parsed args
    UPGRADE_RELEASE="v0.51"

    BACKUP_DIR="/var/backups"
    CURR_BACKUP_DIR="${BACKUP_DIR}/$(date '+%Y-%m-%d')"
    mkdir -p ${BACKUP_DIR} ${CURR_BACKUP_DIR}
    mkdir -p ${CURR_BACKUP_DIR}/{etc,var/lib,${HOME},$(dirname "$DSIP_PROJECT_DIR")}

    # TODO: more cross platform / cloud RDBMS friendly dump, such as the following:
#    VIEWS=$(mysql --skip-column-names --batch -D information_schema -e 'select table_name from tables where table_schema="kamailio" and table_type="VIEW"' | perl -0777 -pe 's/\n(?!\Z)/|/g')
#    mysqldump -B kamailio --routines --triggers --hex-blob | sed -e 's|DEFINER=`[a-z0-9A-Z]*`@`[a-z0-9A-Z]*`||g' | perl -0777 -pe 's|(CREATE TABLE `?(?:'"${VIEWS}"')`?.*?)ENGINE=\w+|\1|sgm' > kamdump.sql

    mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges \
        --user="$KAM_DB_USER" --password="$KAM_DB_PASS" > ${CURR_BACKUP_DIR}/mysql_full.sql
    mysqldump --single-transaction --skip-triggers --skip-add-drop-table --insert-ignore \
        --user="$KAM_DB_USER" --password="$KAM_DB_PASS" ${KAM_DB_NAME} \
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

    mysql --user="$KAM_DB_USER" --password="$KAM_DB_PASS" ${KAM_DB_NAME} < ${CURR_BACKUP_DIR}/kamdb_merge.sql

    # TODO: fix any conflicts that would arise from our new modules / tables in KAMDB

    # TODO: print backup location info to user

    # TODO: transfer / merge backup configs to new configs
    # kam configs
    # dsip configs
    # iptables configs
    # mysql configs

    # TODO: restart services, check for good startup
}

function configGitDevEnv {
    mkdir -p ${DSIP_PROJECT_DIR}/.git/info

    cp -f ${DSIP_PROJECT_DIR}/.git/info/attributes ${DSIP_PROJECT_DIR}/.git/info/attributes.old 2>/dev/null
    cat ${DSIP_PROJECT_DIR}/resources/git/gitattributes >> ${DSIP_PROJECT_DIR}/.git/info/attributes

    cp -f ${DSIP_PROJECT_DIR}/.git/config ${DSIP_PROJECT_DIR}/.git/config.old 2>/dev/null
    cat ${DSIP_PROJECT_DIR}/resources/git/gitconfig >> ${DSIP_PROJECT_DIR}/.git/config

    cp -f ${DSIP_PROJECT_DIR}/.git/info/exclude ${DSIP_PROJECT_DIR}/.git/info/exclude.old 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/gitignore ${DSIP_PROJECT_DIR}/.git/info/exclude

    cp -f ${DSIP_PROJECT_DIR}/.git/commit-msg ${DSIP_PROJECT_DIR}/.git/commit-msg.old 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/commit-msg ${DSIP_PROJECT_DIR}/.git/commit-msg

    cp -f ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit.old 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/pre-commit.sh ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit
    chmod +x ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit

    cp -f ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg.old 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/prepare-commit-msg.sh ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg
    chmod +x ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg

    cp -f ${DSIP_PROJECT_DIR}/.git/hooks/post-commit ${DSIP_PROJECT_DIR}/.git/hooks/post-commit.old 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/post-commit.sh ${DSIP_PROJECT_DIR}/.git/hooks/post-commit
    chmod +x ${DSIP_PROJECT_DIR}/.git/hooks/post-commit

    cp -f ${DSIP_PROJECT_DIR}/resources/git/merge-changelog.sh /usr/local/bin/_merge-changelog
    chmod +x /usr/local/bin/_merge-changelog
}

function cleanGitDevEnv {
    mv -f ${DSIP_PROJECT_DIR}/.gitattributes.old ${DSIP_PROJECT_DIR}/.gitattributes 2>/dev/null
    mv -f ${DSIP_PROJECT_DIR}/.git/config.old ${DSIP_PROJECT_DIR}/.git/config 2>/dev/null
    mv -f ${DSIP_PROJECT_DIR}/.gitignore.old ${DSIP_PROJECT_DIR}/.gitignore 2>/dev/null
    mv -f ${DSIP_PROJECT_DIR}/.git/commit-msg.old ${DSIP_PROJECT_DIR}/.git/commit-msg 2>/dev/null
    mv -f ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit.old ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit 2>/dev/null
    mv -f ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg.old ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg 2>/dev/null
    mv -f ${DSIP_PROJECT_DIR}/.git/hooks/post-commit.old ${DSIP_PROJECT_DIR}/.git/hooks/post-commit 2>/dev/null
    rm -f /usr/local/bin/_merge-changelog
}

function usageOptions {
    linebreak() {
        printf '_%.0s' $(seq 1 ${COLUMNS:-100}) && echo ''
    }

    linebreak
    printf '\n%s\n%s\n' \
        "$(pprint -n USAGE:)" \
        "$0 <command> [options]"

    linebreak
    printf "\n%-s%24s%s\n" \
        "$(pprint -n COMMAND)" " " "$(pprint -n OPTIONS)"
    printf "%-30s %s\n%-30s %s\n%-30s %s\n" \
        "install" "-debug|-servernat|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine|" \
        " " "-exip <ip>|--external-ip=<ip>|-db <db host(s)>|--database=<db host(s)>|-id <num>|--dsip-id=<num>|" \
        " " "-with_lcr|--with_lcr=<num>|-with_dev|--with_dev=<num>"
    printf "%-30s %s\n" \
        "uninstall" "-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine"
    printf "%-30s %s\n" \
        "start" "-debug"
    printf "%-30s %s\n" \
        "stop" "-debug"
    printf "%-30s %s\n" \
        "restart" "-debug"
    printf "%-30s %s\n" \
        "configurekam" "-debug|-servernat"
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
    printf "%-30s %s\n%-30s %s\n" \
        "setcredentials" "-debug|-du <user>|--dsip-user=<user>|-dc <pass>|--dsip-creds=<pass>|-ac <token>|--api-creds=<token>|" \
        " " "-ku <user>|--kam-user=<user>|-kc <pass>|--kam-creds=<pass>|-mu <user>|--mail-user=<user>|-mc <pass>|--mail-creds=<pass>"
    printf "%-30s %s\n" \
        "updatekamconfig" "-debug"
    printf "%-30s %s\n" \
        "updatertpconfig" "-debug|-servernat"
    printf "%-30s %s\n" \
        "help|-h|--help"

    linebreak
    printf '\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
        "$(pprint -n SUMMARY:)" \
        "dSIPRouter is a Web Management GUI for Kamailio based on use case design, with a focus on ITSP and Carrier use cases." \
        "This means that we aren’t a general purpose GUI for Kamailio." \
        "If that's required then use Siremis, which is located at http://siremis.asipto.com/" \
        "This script is used for installing, uninstalling, managing, and configuring dSIPRouter." \
        "That includes installing the Web GUI portion, Kamailio Configuration file and optionally for installing the RTPEngine by SIPwise" \
        "This script can also be used to start, stop and restart dSIPRouter.  It will not restart Kamailio."

    linebreak
    printf '\n%s\n%s\n%s\n\n' \
        "$(pprint -n MORE INFO:)" \
        "Full documentation is available online: https://dsiprouter.readthedocs.io" \
        "Support is available from dOpenSource.  Visit us at https://dopensource.com/dsiprouter or call us at 888-907-2085"

    linebreak
    printf '\n%s\n%s\n%s\n\n' \
        "$(pprint -n PROVIDED BY:)" \
        "dOpenSource | A Flyball Company" \
        "Made in Detroit, MI USA"

    linebreak
}


# TODO: add help options for each command (with subsection usage info for that command)
function processCMD {
    # prep before processing commands
    initialChecks
    setPythonCmd # may be overridden in distro install script

    # Display usage options if no options are specified
    if (( $# == 0 )); then
        usageOptions
        cleanupAndExit 1
    fi

    # use options to add commands in any order needed
    # 1 == defaults on, 0 == defaults off
    local DISPLAY_LOGIN_INFO=0
    # for install / uninstall default to kamailio and dsiprouter services
    local DEFAULT_SERVICES=1

    # process all options before running commands
    declare -a RUN_COMMANDS
    declare -a DEFERRED_COMMANDS
    local ARG="$1"
    case $ARG in
        install)
            # always create the init service and always install sipsak
            RUN_COMMANDS+=(setCloudPlatform createInitService)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
                        set -x
                        shift
                        ;;
                    -servernat)
                        export SERVERNAT=1
                        shift
                        ;;
                    -kam|--kamailio)
                        DEFAULT_SERVICES=0
                        RUN_COMMANDS+=(installKamailio)
                        shift
                        ;;
                    -dsip|--dsiprouter)
                        DEFAULT_SERVICES=0
                        DISPLAY_LOGIN_INFO=1
                        RUN_COMMANDS+=(installDsiprouter)
                        shift
                        ;;
                    -rtp|--rtpengine)
                        DEFAULT_SERVICES=0
                        RUN_COMMANDS+=(installRTPEngine)
                        shift
                        ;;
                    -all|--all)
                        DEFAULT_SERVICES=0
                        DISPLAY_LOGIN_INFO=1
                        RUN_COMMANDS+=(installSipsak installKamailio installDsiprouter installRTPEngine)
                        shift
                        ;;
                    -exip|--external-ip=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            export EXTERNAL_IP=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            export EXTERNAL_IP="$1"
                            shift
                        fi
                        ;;
                    -db|--database=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            export KAM_DB_HOST=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            export KAM_DB_HOST="$1"
                            shift
                        fi
                        ;;
                    -id|--dsip-id=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            DSIP_ID=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            export DSIP_ID="$1"
                            shift
                        fi
                        ;;
                    -with_lcr|--with_lcr=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            if (( $(echo "$1" | cut -d '=' -f 2) > 0 )); then
                                WITH_LCR=1
                            else
                                WITH_LCR=0
                            fi
                            shift
                        else
                            WITH_LCR=1
                            shift
                        fi
                        ;;
                    -with_dev|--with_dev=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            if (( $(echo "$1" | cut -d '=' -f 2) > 0 )); then
                                RUN_COMMANDS+=(configGitDevEnv)
                            fi
                            shift
                        else
                            RUN_COMMANDS+=(configGitDevEnv)
                            shift
                        fi
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        cleanupAndExit 1
                        shift
                        ;;
                esac
            done

            # only use defaults if no discrete services specified
            if (( ${DEFAULT_SERVICES} == 1 )); then
                RUN_COMMANDS+=(installKamailio installDsiprouter)
            fi

            # add commands deferred until all install funcs are done
            RUN_COMMANDS+=(${DEFERRED_COMMANDS[@]})

            # display logo after install / uninstall commands
            RUN_COMMANDS+=(displayLogo)

            # display login info at the very end for user
            if (( ${DISPLAY_LOGIN_INFO} == 1 )); then
                RUN_COMMANDS+=(displayLoginInfo)
            fi
            ;;
        uninstall)
            RUN_COMMANDS+=(setCloudPlatform)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
                        set -x
                        shift
                        ;;
                    -rtp|--rtpengine)
                        DEFAULT_SERVICES=0
                        RUN_COMMANDS+=(uninstallRTPEngine)
                        shift
                        ;;
                    -dsip|--dsiprouter)
                        DEFAULT_SERVICES=0
                        RUN_COMMANDS+=(uninstallDsiprouter)
                        shift
                        ;;
                    -kam|--kamailio)
                        DEFAULT_SERVICES=0
                        RUN_COMMANDS+=(uninstallKamailio)
                        shift
                        ;;
                    -all|--all)    # only remove init if all services will be removed (dependency for others)
                        DEFAULT_SERVICES=0
                        RUN_COMMANDS+=(uninstallRTPEngine uninstallDsiprouter uninstallKamailio uninstallSipsak removeInitService)
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

            # clean dev environment if configured
            if [[ -e /usr/local/bin/_merge-changelog ]]; then
                RUN_COMMANDS+=(cleanGitDevEnv)
            fi

            # only use defaults if no discrete services specified
            if (( ${DEFAULT_SERVICES} == 1 )); then
                RUN_COMMANDS+=(uninstallDsiprouter uninstallKamailio)
            fi

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
                        export DEBUG=1
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
                        export DEBUG=1
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
                        export DEBUG=1
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
        configurekam)
            # reconfigure kamailio configs
            RUN_COMMANDS+=(configureKamailio updateKamailioConfig)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
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
        sslenable)
            # reconfigure ssl configs
            RUN_COMMANDS+=(configureSSL)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
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
                        export DEBUG=1
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
                        export DEBUG=1
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
                        export DEBUG=1
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
                        export DEBUG=1
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
            RUN_COMMANDS+=(setCloudPlatform resetPassword)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
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
        setcredentials)
            # set secure credentials to fixed values
            RUN_COMMANDS+=(setCredentials)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
                        set -x
                        shift
                        ;;
                    -du|--dsip-user=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_DSIP_USER=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_DSIP_USER="$1"
                            shift
                        fi
                        ;;
                    -dc|--dsip-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_DSIP_CREDS=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_DSIP_CREDS="$1"
                            shift
                        fi
                        ;;
                    -ac|--api-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_API_CREDS=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_API_CREDS="$1"
                            shift
                        fi
                        ;;
                    -ku|--kam-user=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_KAM_USER=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_KAM_USER="$1"
                            shift
                        fi
                        ;;
                    -kc|--kam-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_KAM_CREDS=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_KAM_CREDS="$1"
                            shift
                        fi
                        ;;
                    -mu|--mail-user=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_MAIL_USER=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_MAIL_USER="$1"
                            shift
                        fi
                        ;;
                    -mc|--mail-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_MAIL_CREDS=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_MAIL_CREDS="$1"
                            shift
                        fi
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
                        export DEBUG=1
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
                        export DEBUG=1
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
