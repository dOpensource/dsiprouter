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

# Default MYSQL db kamailio user values
MYSQL_KAM_DEF_USERNAME="kamailio"
MYSQL_KAM_DEF_PASSWORD="kamailiorw"
MYSQL_KAM_DEF_DATABASE="kamailio"

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

# Check if we are on AWS Instance
export AWS_ENABLED=0
# Will try to access the AWS metadata URL and will return an exit code of 22 if it fails
# The -f flag enables this feature
curl -s --connect-timeout 2 http://169.254.169.254/latest/dynamic/instance-identity/document|grep ami &>/dev/null
ret=$?
#AWS Instance
if (( $ret == 0 )); then
    export AWS_ENABLED=1
    setConfigAttrib 'CLOUD_PLATFORM' 'AWS' ${DSIP_CONFIG_FILE} -q
#Native Install or some other cloud platform that's not supported as of yet
else
    setConfigAttrib 'CLOUD_PLATFORM' '' ${DSIP_CONFIG_FILE} -q

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
| { echo -e "\e[1;49;36m"; cat; echo -e "\e[39;49;00m"; }
}

# Cleanup exported variables on exit
function cleanupAndExit {
    unset DSIP_PROJECT_DIR DSIP_INSTALL_DIR DSIP_KAMAILIO_CONFIG_DIR DSIP_KAMAILIO_CONFIG DSIP_DEFAULTS_DIR SYSTEM_KAMAILIO_CONFIG_DIR DSIP_CONFIG_FILE
    unset REQ_PYTHON_MAJOR_VER DISTRO DISTRO_VER PYTHON_CMD AWS_ENABLED PATH_UPDATE_FILE SYSTEM_RTPENGINE_CONFIG_DIR SYSTEM_RTPENGINE_CONFIG_FILE SERVERNAT
    unset RTPENGINE_VER SRC_DIR DSIP_SYSTEM_CONFIG_DIR BACKUPS_DIR DSIP_RUN_DIR KAM_VERSION CLOUD_INSTALL_LOG
    unset MYSQL_ROOT_PASSWORD MYSQL_ROOT_USERNAME MYSQL_ROOT_DATABASE MYSQL_KAM_PASSWORD MYSQL_KAM_USERNAME MYSQL_KAM_DATABASE
    unset RTP_PORT_MIN RTP_PORT_MAX DSIP_PORT EXTERNAL_IP INTERNAL_IP INTERNAL_NET PERL_MM_USE_DEFAULT
    unset -f setPythonCmd
    rm -f /etc/apt/apt.conf.d/local 2>/dev/null
    exit $1
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
    validateOSInfo

    # make sure dirs exist (ones that may not yet exist)
    mkdir -p ${DSIP_SYSTEM_CONFIG_DIR} ${SRC_DIR} ${BACKUPS_DIR} ${DSIP_RUN_DIR}

    if [[ "$DISTRO" == "debian" ]] || [[ "$DISTRO" == "ubuntu" ]]; then
        # comment out cdrom in sources as it can halt install
        sed -i -E 's/(^\w.*cdrom.*)/#\1/g' /etc/apt/sources.list
        # make sure we run package installs unattended
        export DEBIAN_FRONTEND="noninteractive"
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
    setConfigAttrib 'DSIP_SSL_KEY' "$DSIP_SSL_KEY" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_SSL_CERT' "$DSIP_SSL_CERT" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_SSL_EMAIL' "$DSIP_SSL_EMAIL" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_PROTO' "$DSIP_GUI_PROTOCOL" ${DSIP_CONFIG_FILE} -q
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
# should be run after reboot or change in network configurations
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

    # copy of template kamailio configuration to dsiprouter system config dir
    cp -f ${DSIP_KAMAILIO_CONFIG_DIR}/kamailio51_dsiprouter.cfg ${DSIP_KAMAILIO_CONFIG_FILE}
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

    # Install schema for custom LCR logic
    mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_KAM_DATABASE < ${DSIP_DEFAULTS_DIR}/lcr.sql

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
            -L $MYSQL_KAM_DATABASE ${DSIP_DEFAULTS_DIR}/dr_gw_lists.csv
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
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled
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

    if [ ! -f ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled ]; then
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

# TODO: follow same user / group guidelines we used for other services
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
    # configure dsiprouter modules
    installModules
    # set some defaults in settings.py
    configurePythonSettings

	# configure SSL
    if [ ${WITH_SSL} -eq 1 ]; then
        configureSSL
    fi

    # for AMI images the instance-id may change (could be a clone)
    # add to startup process a password reset to ensure its set correctly
    if (( $AWS_ENABLED == 1 )); then
        # add password reset to boot process (for AMI depends on network)
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
$(declare -f getInstanceID)
$(declare -f removeInitCmd)

# reset debian user password and remove dsip-init startup cmd
INSTANCE_ID=\$(getInstanceID)
mysql -e "CREATE USER IF NOT EXISTS 'debian-sys-maint'@'localhost' IDENTIFIED BY '\${INSTANCE_ID}';"
mysql -e "GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '\${INSTANCE_ID}';"
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
    fi

    # Generate a unique admin password
    generatePassword

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
    if (( $AWS_ENABLED == 1 )); then
        removeInitCmd "dsiprouter.sh resetpassword"
        removeDependsOnInit "dsiprouter.service"
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
        printwarn "kamailio is already installed"
        return
    fi

    printdbg "Attempting to install Kamailio..."
    ./kamailio/${DISTRO}/${DISTRO_VER}.sh install ${KAM_VERSION} ${DSIP_PORT}
    if [ $? -eq 0 ]; then
        # configure kamailio settings
        configureKamailio
        echo "Configuring Kamailio service"
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
        apt-get install -y perl perl-CPAN
    elif cmdExists 'yum'; then
        yum install -y perl perl-CPAN
    fi
    perl -MCPAN -e 'install URI::Escape'

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
    printf '\n'
    printdbg "The username and dynamically generated password are below:"

    pprint "Username: $(getConfigAttrib 'USERNAME' ${DSIP_CONFIG_FILE})"
    pprint "Password: $(getConfigAttrib 'PASSWORD' ${DSIP_CONFIG_FILE})"

    # Tell them how to access the URL
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

# Generate password and set it in the ${DSIP_CONFIG_FILE} PASSWORD field
function generatePassword {
    if (( $AWS_ENABLED == 1)); then
        password=$(getInstanceID)
    else
        password=$(date +%s | sha256sum | base64 | head -c 16)
    fi

    setConfigAttrib 'PASSWORD' "$password" ${DSIP_CONFIG_FILE} -q
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
        "$(pprint -n USAGE:)" \
        "$0 <command> [options]"

    linebreak
    printf "\n%-s%24s%s\n" \
        "$(pprint -n COMMAND)" " " "$(pprint -n OPTIONS)"
    printf "%-30s %s\n" \
        "install" "-debug|-exip <ip>|--external-ip=<ip>|-servernat|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine"
    printf "%-30s %s\n" \
        "uninstall" "-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine"
    printf "%-30s %s\n" \
        "start" "-debug"
    printf "%-30s %s\n" \
        "stop" "-debug"
    printf "%-30s %s\n" \
        "restart" "-debug"
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
    local ARG="$1"
    case $ARG in
        install)
            # always create the init service and always install sipsak
            RUN_COMMANDS+=(createInitService installSipsak)
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
                        RUN_COMMANDS+=(installKamailio installDsiprouter installRTPEngine)
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

            # only use defaults if no discrete services specified
            if (( ${DEFAULT_SERVICES} == 1 )); then
                RUN_COMMANDS+=(installKamailio installDsiprouter)
            fi

            # display logo after install / uninstall commands
            RUN_COMMANDS+=(displayLogo)

            # display login info at the very end for user
            if (( ${DISPLAY_LOGIN_INFO} == 1 )); then
                RUN_COMMANDS+=(displayLoginInfo)
            fi
            ;;
        uninstall)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        DEBUG=1
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
                        RUN_COMMANDS+=(uninstallRTPEngine uninstallDsiprouter uninstallKamailio removeInitService uninstallSipsak)
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
