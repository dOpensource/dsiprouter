#!/usr/bin/env bash
#
#=============== dSIPRouter Management Script ==============#
#
# install, configure, and manage dsiprouter
#
#========================== NOTES ==========================#
#
# Supported OS:
# - Debian 11 (bullseye) (BETA)
# - Debian 10 (buster)
# - Debian 9 (stretch)
# - Debian 8 (jessie)
# - CentOS 8
# - CentOS 7
# - Amazon Linux 2
# - Ubuntu 16.04 (xenial)
#
# Conventions:
# - In general exported variables & functions are used in externally called scripts / programs
#
# TODO:
# - allow user to move carriers freely between carrier groups
# - allow a carrier to be in more than one carrier group
# - add ncurses selection menu for enabling / disabling modules
# - separate kam config into smaller sections and import from main cfg
# - separate gui routes into smaller sections and import as blueprints
# - allow hot-reloading password from python configs while dsiprouter running
# - naming convention for system vs dsip config files is very confusing (make more explicit)
# - cleanup dependency installs/checks, many of these could be condensed
# - allow overwriting caller id per gwgroup / gw (setup in gui & kamcfg)
#
#============== Detailed Debugging Information =============#
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
#===========================================================#


# Set project dir (where src and install files go)
DSIP_PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(dirname $(readlink -f "$0"))}
# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh


# settings used by script that are user configurable
setStaticScriptSettings() {
    #================== STATIC_CONFIG_SETTINGS ===================#

    # Define some defaults and environment variables
    FLT_CARRIER=8
    FLT_PBX=9
    FLT_MSTEAMS=22
    FLT_INTERNAL=20
    FLT_OUTBOUND=8000
    FLT_INBOUND=9000
    FLT_LCR_MIN=10000
    FLT_FWD_MIN=20000
    WITH_LCR=1
    export DEBUG=0
    OVERRIDE_SERVERNAT=0
    export TEAMS_ENABLED=1
    export REQ_PYTHON_MAJOR_VER=3
    [[ -f /proc/net/if_inet6 ]] && export IPV6_ENABLED=1 || export IPV6_ENABLED=0
    export DSIP_SYSTEM_CONFIG_DIR="/etc/dsiprouter"
    DSIP_PRIV_KEY="${DSIP_SYSTEM_CONFIG_DIR}/privkey"
    DSIP_UUID_FILE="${DSIP_SYSTEM_CONFIG_DIR}/uuid.txt"
    export DSIP_KAMAILIO_CONFIG_DIR="${DSIP_PROJECT_DIR}/kamailio"
    export DSIP_KAMAILIO_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/kamailio/dsiprouter.cfg"
    export DSIP_KAMAILIO_TLS_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/kamailio/tls.cfg"
    export DSIP_DEFAULTS_DIR="${DSIP_KAMAILIO_CONFIG_DIR}/defaults"
    export DSIP_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py"
    export DSIP_RUN_DIR="/var/run/dsiprouter"
    export DSIP_CERTS_DIR="${DSIP_SYSTEM_CONFIG_DIR}/certs"
    DSIP_DOCS_DIR="${DSIP_PROJECT_DIR}/docs/build/html"
    export SYSTEM_KAMAILIO_CONFIG_DIR="/etc/kamailio"
    export SYSTEM_KAMAILIO_CONFIG_FILE="${SYSTEM_KAMAILIO_CONFIG_DIR}/kamailio.cfg" # will be symlinked
    export SYSTEM_KAMAILIO_TLS_CONFIG_FILE="${SYSTEM_KAMAILIO_CONFIG_DIR}/tls.cfg" # will be symlinked
    export SYSTEM_RTPENGINE_CONFIG_DIR="/etc/rtpengine"
    export SYSTEM_RTPENGINE_CONFIG_FILE="${SYSTEM_RTPENGINE_CONFIG_DIR}/rtpengine.conf"
    export PATH_UPDATE_FILE="/etc/profile.d/dsip_paths.sh" # updates paths required
    GIT_UPDATE_FILE="/etc/profile.d/dsip_git.sh" # extends git command
    export RTPENGINE_VER="mr9.3.1.4"
    export SRC_DIR="/usr/local/src"
    export BACKUPS_DIR="/var/backups/dsiprouter"
    IMAGE_BUILD=${IMAGE_BUILD:-0}
    APT_OFFICIAL_SOURCES="/etc/apt/sources.list"
    APT_OFFICIAL_PREFS="/etc/apt/preferences"
    APT_OFFICIAL_SOURCES_BAK="${BACKUPS_DIR}/original-sources.list"
    APT_OFFICIAL_PREFS_BAK="${BACKUPS_DIR}/original-sources.pref"
    YUM_OFFICIAL_REPOS="/etc/yum.repos.d/official-releases.repo"

    # Force the installation of a Kamailio version by uncommenting
    #KAM_VERSION=44 # Version 4.4.x
    #KAM_VERSION=51 # Version 5.1.x
    #KAM_VERSION=53 # Version 5.3.x

    # Uncomment and set this variable to an explicit Python executable file name
    # If set, the script will not try and find a Python version with 3.5 as the major release number
    #export PYTHON_CMD=/usr/bin/python3.4

    # Network configuration values
    export DSIP_UNIX_SOCK='/var/run/dsiprouter/dsiprouter.sock'
    export DSIP_PORT=5000
    export RTP_PORT_MIN=10000
    export RTP_PORT_MAX=20000
    export KAM_SIP_PORT=5060
    export KAM_SIPS_PORT=5061
    export KAM_DMQ_PORT=5090
    export KAM_WSS_PORT=4443
    export KAM_HEP_PORT=9060

    export DSIP_PROTO='https'
    export DSIP_API_PROTO='https'
    export DSIP_SSL_KEY="${DSIP_CERTS_DIR}/dsiprouter-key.pem"
    export DSIP_SSL_CERT="${DSIP_CERTS_DIR}/dsiprouter-cert.pem"
    export DSIP_SSL_CA="${DSIP_CERTS_DIR}/ca-list.pem"
}

# settings used by script that are generated by the script
setDynamicScriptSettings() {
    # make sure dirs exist required for this script
    mkdir -p ${DSIP_SYSTEM_CONFIG_DIR}{,/gui,/kamailio} ${SRC_DIR} ${DSIP_RUN_DIR} ${DSIP_CERTS_DIR}{,/ca} ${BACKUPS_DIR}

    # only copy the template file over to the DSIP_CONFIG_FILE if it doesn't already exist
    if [[ ! -f "${DSIP_CONFIG_FILE}" ]]; then
	    # copy over the template settings.py to be worked on (used throughout this script as well)
        cp -f ${DSIP_PROJECT_DIR}/gui/settings.py ${DSIP_CONFIG_FILE}
    fi

    # grab network settings dynamically
    export INTERNAL_IP=$(getInternalIP)
    export INTERNAL_NET=$(getInternalCIDR)
    export INTERNAL_FQDN=$(getInternalFQDN)
    export EXTERNAL_IP=$(getExternalIP)
    if [[ -z "$EXTERNAL_IP" ]]; then
	    export EXTERNAL_IP="$INTERNAL_IP"
    fi
    export EXTERNAL_FQDN=$(getExternalFQDN)
    if [[ -z "$EXTERNAL_FQDN" ]] || ! checkConn "$EXTERNAL_FQDN"; then
    	export EXTERNAL_FQDN="$INTERNAL_FQDN"
    fi
    if [[ "$EXTERNAL_IP" != "$INTERNAL_IP" ]]; then
        export SERVERNAT=1
    else
        export SERVERNAT=0
    fi

    # grab root db settings from env or settings file
    export ROOT_DB_USER=${ROOT_DB_USER:-$(getConfigAttrib 'ROOT_DB_USER' ${DSIP_CONFIG_FILE})}
    export ROOT_DB_PASS=${ROOT_DB_PASS:-$(decryptConfigAttrib 'ROOT_DB_PASS' ${DSIP_CONFIG_FILE})}
    export ROOT_DB_NAME=${ROOT_DB_NAME:-$(getConfigAttrib 'ROOT_DB_NAME' ${DSIP_CONFIG_FILE})}

    # grab kam db settings from env or settings file
    export KAM_DB_HOST=${KAM_DB_HOST:-$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})}
    export KAM_DB_TYPE=${KAM_DB_TYPE:-$(getConfigAttrib 'KAM_DB_TYPE' ${DSIP_CONFIG_FILE})}
    export KAM_DB_PORT=${KAM_DB_PORT:-$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})}
    export KAM_DB_NAME=${KAM_DB_NAME:-$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})}
    export KAM_DB_USER=${KAM_DB_USER:-$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})}
    export KAM_DB_PASS=${KAM_DB_PASS:-$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE} 2>/dev/null)}

    # grab credential max lengths from python files for later use
    # we use perl bcuz python may not be installed when this is run
    export HASHED_CREDS_ENCODED_MAX_LEN=$(grep -m 1 'HASHED_CREDS_ENCODED_MAX_LEN' ${DSIP_PROJECT_DIR}/gui/util/security.py |
        perl -pe 's%.*HASHED_CREDS_ENCODED_MAX_LEN[ \t]+=[ \t]+([0-9]+).*%\1%')
    export AESCTR_CREDS_ENCODED_MAX_LEN=$(grep -m 1 'AESCTR_CREDS_ENCODED_MAX_LEN' ${DSIP_PROJECT_DIR}/gui/util/security.py |
        perl -pe 's%.*AESCTR_CREDS_ENCODED_MAX_LEN[ \t]+=[ \t]+([0-9]+).*%\1%')


    # Set the EMAIL used to obtain Let'sEncrypt Certificates
    export DSIP_SSL_EMAIL="admin@${EXTERNAL_FQDN}"
}

# Check if we are on a VPS Cloud Instance
function setCloudPlatform {
    # 0 == not enabled, 1 == enabled
    export AWS_ENABLED=0
    export DO_ENABLED=0
    export GCE_ENABLED=0
    export AZURE_ENABLED=0
    export VULTR_ENABLED=0

    # -- amazon web service check --
    if isInstanceAMI; then
        export AWS_ENABLED=1
        CLOUD_PLATFORM='AWS'
    # -- digital ocean check --
    elif isInstanceDO; then
        export DO_ENABLED=1
        CLOUD_PLATFORM='DO'
    # -- google compute engine check --
    elif isInstanceGCE; then
        export GCE_ENABLED=1
        CLOUD_PLATFORM='GCE'
    # -- microsoft azure check --
    elif isInstanceAZURE; then
        export AZURE_ENABLED=1
        CLOUD_PLATFORM='AZURE'
    # -- vultr cloud check --
    elif isInstanceVULTR; then
        export VULTR_ENABLED=1
        CLOUD_PLATFORM='VULTR'
    # -- bare metal or unsupported cloud platform --
    else
        CLOUD_PLATFORM=''
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
cnQgY2FuIGJlIHB1cmNoYXNlZCBmcm9tIGh0dHBzOi8vZHNpcHJvdXRlci5vcmcvIAoKVGhhbmtz
IHRvIG91ciBzcG9uc29yOiBkT3BlblNvdXJjZSAoaHR0cHM6Ly9kb3BlbnNvdXJjZS5jb20pCg==" \
| base64 -d \
| { echo -e "\e[1;49;36m"; cat; echo -e "\e[39;49;00m"; }
}

# Cleanup temp files / settings and exit
function cleanupAndExit {
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

function setOSInfo {
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
}

# Validate OS and get supported Kamailio versions
function validateOSInfo {
    if [[ "$DISTRO" == "debian" ]]; then
        case "$DISTRO_VER" in
            11)
                printwarn "Your Operating System Version is in BETA support and may not function properly. Issues can be tracked at https://github.com/dOpensource/dsiprouter/"
                KAM_VERSION=${KAM_VERSION:-53}
                export APT_JESSIE_PRIORITY=50 APT_STRETCH_PRIORITY=50 APT_BUSTER_PRIORITY=50 APT_BULLSEYE_PRIORITY=990 APT_SID_PRIORITY=500
                ;;
            10)
                KAM_VERSION=${KAM_VERSION:-53}
                export APT_JESSIE_PRIORITY=50 APT_STRETCH_PRIORITY=50 APT_BUSTER_PRIORITY=990 APT_BULLSEYE_PRIORITY=500 APT_SID_PRIORITY=100
                ;;
            9)
                KAM_VERSION=${KAM_VERSION:-53}
                export APT_JESSIE_PRIORITY=50 APT_STRETCH_PRIORITY=990 APT_BUSTER_PRIORITY=500 APT_BULLSEYE_PRIORITY=100 APT_SID_PRIORITY=50
                ;;
            8)
                KAM_VERSION=${KAM_VERSION:-53}
                export APT_JESSIE_PRIORITY=990 APT_STRETCH_PRIORITY=500 APT_BUSTER_PRIORITY=100 APT_BULLSEYE_PRIORITY=50 APT_SID_PRIORITY=50
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
	        8)
                KAM_VERSION=${KAM_VERSION:-53}
                ;;
            7)
                KAM_VERSION=${KAM_VERSION:-53}
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                cleanupAndExit 1
            ;;
        esac
    elif [[ "$DISTRO" == "amazon" ]]; then
        case "$DISTRO_VER" in
            2)
                KAM_VERSION=${KAM_VERSION:-51}
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                cleanupAndExit 1
                ;;
        esac
    elif [[ "$DISTRO" == "ubuntu" ]]; then
        case "$DISTRO_VER" in
            16.04)
                KAM_VERSION=${KAM_VERSION:-51}
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

# install dsiprouter manpage
function installManPage {
    local MAN_PROGS_DIR="/usr/share/man/man1"

    printdbg "installing dsiprouter manpage"

    # Install manpage requirements
    if cmdExists 'apt-get'; then
        apt-get install -y manpages man-db
    elif cmdExists 'yum'; then
        yum install -y man-pages man-db man
    fi

    cp -f ${DSIP_PROJECT_DIR}/resources/man/dsiprouter.1 ${MAN_PROGS_DIR}/
    gzip -f ${MAN_PROGS_DIR}/dsiprouter.1
    mandb

    printdbg "dsiprouter manpage installed"
}

# uninstall dsiprouter manpage
function uninstallManPage {
    local MAN_PROGS_DIR="/usr/share/man/man1"

    printdbg "uninstalling dsiprouter manpage"

    rm -f ${MAN_PROGS_DIR}/dsiprouter.1
    rm -f ${MAN_PROGS_DIR}/dsiprouter.1.gz
    mandb

    printdbg "dsiprouter manpage uninstalled"
}

# run prior to any cmd being processed
function initialChecks {
    validateRootPriv
    setOSInfo
    validateOSInfo
    installScriptRequirements
    setStaticScriptSettings
    setDynamicScriptSettings

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

    # fix PATH if needed
    # we are using the default install paths but these may change in the future
    mkdir -p $(dirname ${PATH_UPDATE_FILE})
    if [[ ! -e "$PATH_UPDATE_FILE" ]]; then
        (cat << 'EOF'
#export PATH="/usr/local/bin${PATH:+:$PATH}"
#export PATH="${PATH:+$PATH:}/usr/sbin"
#export PATH="${PATH:+$PATH:}/usr/bin"
#export PATH="${PATH:+$PATH:}/sbin"
EOF
        ) > ${PATH_UPDATE_FILE}
    fi

    # minimalistic approach avoids growing duplicates
    # enable (uncomment) and import only what we need
    local PATH_UPDATED=0

    # - sipsak
    if ! pathCheck /usr/local/bin; then
        sed -i -r 's|^#(export PATH="/usr/local/bin\$\{PATH:\+:\$PATH\}")$|\1|' ${PATH_UPDATE_FILE}
        PATH_UPDATED=1
    fi
    # - rtpengine
    if ! pathCheck /usr/sbin; then
        sed -i -r 's|^#(export PATH="\$\{PATH:\+\$PATH:\}/usr/sbin")$|\1|' ${PATH_UPDATE_FILE}
        PATH_UPDATED=1
    fi
    # - dsiprouter
    if ! pathCheck /usr/bin; then
        sed -i -r 's|^#(export PATH="\$\{PATH:\+\$PATH:\}/usr/bin")$|\1|' ${PATH_UPDATE_FILE}
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

    possible_python_versions=$(find /usr/bin /usr/local/bin -name "python${REQ_PYTHON_MAJOR_VER}*" -regex ".*python.*[0-9]$" -executable  2>/dev/null)
    for i in $possible_python_versions; do
        ver=$($i -V 2>&1)
        # validate command produces viable python version
        if [ $? -eq 0 ]; then
            echo $ver | grep "$REQ_PYTHON_MAJOR_VER" >/dev/null
            if [ $? -eq 0 ]; then
                export PYTHON_CMD="$i"
                return 0
            fi
        fi
    done
}
export -f setPythonCmd

# exported because its used throughout called scripts as well
function reconfigureMysqlSystemdService {
    local KAMDB_LOCATION="$(cat ${DSIP_SYSTEM_CONFIG_DIR}/.mysqldblocation 2>/dev/null)"

    case "$KAM_DB_HOST" in
        "localhost"|"127.0.0.1"|"::1"|"${INTERNAL_IP}"|"${EXTERNAL_IP}"|"$(hostname)"|"$(hostname -f 2>/dev/null)")
            # if previously was remote and now local re-generate service files
            if [[ "${KAMDB_LOCATION}" == "remote" ]]; then
                systemctl stop mysql
                systemctl disable mysql
                rm -f /etc/systemd/system/mysql.service 2>/dev/null
                rm -f /etc/systemd/system/mysqld.service 2>/dev/null
                rm -f /etc/systemd/system/mariadb.service 2>/dev/null
                systemctl daemon-reload
                systemctl enable mysql
            fi

            printf '%s' 'local' > ${DSIP_SYSTEM_CONFIG_DIR}/.mysqldblocation
            ;;
        *)
            # if previously was local and now remote or inital run and is remote replace service files w/ dummy
            if [[ "${KAMDB_LOCATION}" == "local" ]] || [[ "${KAMDB_LOCATION}" == "" ]]; then
                systemctl stop mysql
                systemctl disable mysql
                cp -f ${DSIP_PROJECT_DIR}/resources/mysql/dummy.service /etc/systemd/system/mysql.service
                cp -f ${DSIP_PROJECT_DIR}/resources/mysql/dummy.service /etc/systemd/system/mysqld.service
                cp -f ${DSIP_PROJECT_DIR}/resources/mysql/dummy.service /etc/systemd/system/mariadb.service
                chmod 0644 /etc/systemd/system/mysql.service
                chmod 0644 /etc/systemd/system/mysqld.service
                chmod 0644 /etc/systemd/system/mariadb.service
                systemctl daemon-reload
                systemctl enable mysql
            fi

            printf '%s' 'remote' > ${DSIP_SYSTEM_CONFIG_DIR}/.mysqldblocation
            ;;
    esac
}
export -f reconfigureMysqlSystemdService

# generate dynamic python config settings on install
function configurePythonSettings {
    setConfigAttrib 'FLT_CARRIER' "$FLT_CARRIER" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_PBX' "$FLT_PBX" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_MSTEAMS' "$FLT_MSTEAMS" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_INTERNAL' "$FLT_INTERNAL" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_OUTBOUND' "$FLT_OUTBOUND" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_INBOUND' "$FLT_INBOUND" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_LCR_MIN' "$FLT_LCR_MIN" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_FWD_MIN' "$FLT_FWD_MIN" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'KAM_KAMCMD_PATH' "$(type -p kamcmd)" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'KAM_CFG_PATH' "$SYSTEM_KAMAILIO_CONFIG_FILE" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'RTP_CFG_PATH' "$SYSTEM_RTPENGINE_CONFIG_FILE" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_PROTO' "$DSIP_PROTO" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_UNIX_SOCK' "$DSIP_UNIX_SOCK" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_PORT' "$DSIP_PORT" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_PRIV_KEY' "$DSIP_PRIV_KEY" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_SSL_KEY' "$DSIP_SSL_KEY" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_SSL_CERT' "$DSIP_SSL_CERT" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_SSL_CA' "$DSIP_SSL_CA" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_SSL_EMAIL' "$DSIP_SSL_EMAIL" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_CERTS_DIR' "$DSIP_CERTS_DIR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_API_PROTO' "$DSIP_API_PROTO" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'CLOUD_PLATFORM' "$CLOUD_PLATFORM" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'BACKUP_FOLDER' "$BACKUPS_DIR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_PROJECT_DIR' "$DSIP_PROJECT_DIR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_DOCS_DIR' "$DSIP_DOCS_DIR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'KAM_TLSCFG_PATH' "$SYSTEM_KAMAILIO_TLS_CONFIG_FILE" ${DSIP_CONFIG_FILE} -q
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

function renewSSLCert {
    # Don't renew if a default cert was uploaded
    local DEFAULT_CERT_UPLOADED=$(mysql -sN --user="$KAM_DB_USER" --password="$KAM_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $KAM_DB_NAME \
        -e "select count(*) from dsip_certificates where domain='default'" 2> /dev/null)
    if (( ${DEFAULT_CERT_UPLOADED} == 1 )); then
	    return
    fi

    if certbot -n certificates | grep -q 'No certs found' &>/dev/null; then
        printwarn "No LetsEncrypt certificates managed by Certbot found"
        return
    fi

    certbot renew
    if (( $? == 0 )); then
        rm -f ${DSIP_CERTS_DIR}/dsiprouter*
        cp -f /etc/letsencrypt/live/${EXTERNAL_FQDN}/fullchain.pem ${DSIP_SSL_CERT}
        cp -f /etc/letsencrypt/live/${EXTERNAL_FQDN}/privkey.pem ${DSIP_SSL_KEY}
        setCertPerms
        kamcmd tls.reload
    else
        printerr "Failed Renewing Cert for ${EXTERNAL_FQDN} using LetsEncrypt"
    fi
}

function configureSSL {
    # Check if certificates already exists.  If so, use them and exit
    if [[ -f "${DSIP_SSL_CERT}" && -f "${DSIP_SSL_KEY}" ]]; then
        printwarn "Using certificates found in ${DSIP_CERTS_DIR}"
        setCertPerms
        return
    fi

    # Stop nginx if started so that LetsEncrypt can leverage port 80
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
	    docker stop dsiprouter-nginx 2>/dev/null
    else
    	firewall-cmd --zone=public --add-port=80/tcp
    fi

    # Try to create cert using LetsEncrypt's first
    printdbg "Generating Certs for ${EXTERNAL_FQDN} using LetsEncrypt"
    certbot certonly --standalone --non-interactive --agree-tos -d ${EXTERNAL_FQDN} -m ${DSIP_SSL_EMAIL}
    if (( $? == 0 )); then
        rm -f ${DSIP_CERTS_DIR}/dsiprouter*
        cp -f /etc/letsencrypt/live/${EXTERNAL_FQDN}/fullchain.pem ${DSIP_SSL_CERT}
        cp -f /etc/letsencrypt/live/${EXTERNAL_FQDN}/privkey.pem ${DSIP_SSL_KEY}
        # Add Nightly Cronjob to renew certs if not already there
        if ! crontab -l | grep -q "${DSIP_PROJECT_DIR}/dsiprouter.sh renewsslcert" 2>/dev/null; then
            cronAppend "0 0 * * * ${DSIP_PROJECT_DIR}/dsiprouter.sh renewsslcert"
        fi
    else
        printwarn "Failed Generating Certs for ${EXTERNAL_FQDN} using LetsEncrypt"

        # Worst case, generate a Self-Signed Certificate
        printdbg "Generating dSIPRouter Self-Signed Certificates"
        openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out ${DSIP_SSL_CERT} -keyout ${DSIP_SSL_KEY} -subj "/C=US/ST=MI/L=Detroit/O=dSIPRouter/CN=${EXTERNAL_FQDN}"
    fi
    setCertPerms

    # Start nginx if dSIP was installed
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
	    docker stop dsiprouter-nginx 2>/dev/null
    else
   	    firewall-cmd --zone=public --remove-port=80/tcp
    fi
}

# set TLS certificate permissions based on users available
function setCertPerms() {
    if id -u dsiprouter &>/dev/null; then
        # dsiprouter needs to have control over the certs (note that nginx should never have write access)
        chown -R dsiprouter:kamailio ${DSIP_CERTS_DIR}
        chmod 640 ${DSIP_CERTS_DIR}/*
    else
        # dsiprouter user does not yet exist so make sure kamailio user has access
        chown -R root:kamailio ${DSIP_CERTS_DIR}
        chmod 640 ${DSIP_CERTS_DIR}/dsiprouter*
    fi
}

# updates and settings in kam config that may change
# should be run after changing settings.py or change in network configurations
# TODO: support configuring separate asterisk realtime db conns / clusters (would need separate setting in settings.py)
function updateKamailioConfig {
    local DSIP_ID=${DSIP_ID:-$(getConfigAttrib 'DSIP_ID' ${DSIP_CONFIG_FILE})}
    local DSIP_VERSION=${DSIP_VERSION:-$(getConfigAttrib 'VERSION' ${DSIP_CONFIG_FILE})}
    local DSIP_API_BASEURL="$(getConfigAttrib 'DSIP_API_PROTO' ${DSIP_CONFIG_FILE})://127.0.0.1:$(getConfigAttrib 'DSIP_API_PORT' ${DSIP_CONFIG_FILE})"
    local DSIP_API_TOKEN=${DSIP_API_TOKEN:-$(decryptConfigAttrib 'DSIP_API_TOKEN' ${DSIP_CONFIG_FILE} 2>/dev/null)}
    local DEBUG=${DEBUG:-$([[ "$(getConfigAttrib 'DEBUG' ${DSIP_CONFIG_FILE})" == "True" ]] && echo '1' || echo '0')}
    local ROLE=${ROLE:-$(getConfigAttrib 'ROLE' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_GW_ENABLED=${TELEBLOCK_GW_ENABLED:-$(getConfigAttrib 'TELEBLOCK_GW_ENABLED' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_GW_IP=${TELEBLOCK_GW_IP:-$(getConfigAttrib 'TELEBLOCK_GW_IP' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_GW_PORT=${TELEBLOCK_GW_PORT:-$(getConfigAttrib 'TELEBLOCK_GW_PORT' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_MEDIA_IP=${TELEBLOCK_MEDIA_IP:-$(getConfigAttrib 'TELEBLOCK_MEDIA_IP' ${DSIP_CONFIG_FILE})}
    local TELEBLOCK_MEDIA_PORT=${TELEBLOCK_MEDIA_PORT:-$(getConfigAttrib 'TELEBLOCK_MEDIA_PORT' ${DSIP_CONFIG_FILE})}
    local KAM_WSS_PORT=${KAM_WSS_PORT:-$(getConfigAttrib 'KAM_WSS_PORT' ${DSIP_CONFIG_FILE})}
    local KAM_SIP_PORT=${KAM_SIP_PORT:-$(getConfigAttrib 'KAM_SIP_PORT' ${DSIP_CONFIG_FILE})}
    local KAM_SIPS_PORT=${KAM_SIPS_PORT:-$(getConfigAttrib 'KAM_SIPS_PORT' ${DSIP_CONFIG_FILE})}
    local KAM_DMQ_PORT=${KAM_DMQ_PORT:-$(getConfigAttrib 'KAM_DMQ_PORT' ${DSIP_CONFIG_FILE})}
    local KAM_HEP_PORT=${KAM_HEP_PORT:-$(getConfigAttrib 'KAM_HEP_PORT' ${DSIP_CONFIG_FILE})}
    local KAM_HOMER_HOST=${KAM_HOMER_HOST:-$(getConfigAttrib 'KAM_HEP_PORT' ${DSIP_CONFIG_FILE})}

    # update kamailio config file
    if (( $DEBUG == 1 )); then
        enableKamailioConfigFeature 'WITH_DEBUG' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigFeature 'WITH_DEBUG' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if (( $SERVERNAT == 1 )); then
        enableKamailioConfigFeature 'WITH_SERVERNAT' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigFeature 'WITH_SERVERNAT' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if [[ -n "$KAM_HOMER_HOST" ]]; then
        enableKamailioConfigFeature 'WITH_HOMER' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        enableKamailioConfigFeature 'WITH_HOMER' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    setKamailioConfigSubstdef 'DSIP_ID' "${DSIP_ID}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'DSIP_VERSION' "${DSIP_VERSION}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'INTERNAL_IP_ADDR' "${INTERNAL_IP}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'INTERNAL_IP_NET' "${INTERNAL_NET}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'EXTERNAL_IP_ADDR' "${EXTERNAL_IP}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'EXTERNAL_FQDN' "${EXTERNAL_FQDN}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'WSS_PORT' "${KAM_WSS_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'SIP_PORT' "${KAM_SIP_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'SIPS_PORT' "${KAM_SIPS_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'DMQ_PORT' "${KAM_DMQ_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'HEP_PORT' "${KAM_HEP_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubstdef 'HOMER_HOST' "${KAM_HOMER_HOST}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigDef 'FLT_CARRIER' "$FLT_CARRIER" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigDef 'FLT_PBX' "$FLT_PBX" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigDef 'FLT_MSTEAMS' "$FLT_MSTEAMS" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigDef 'FLT_INTERNAL' "$FLT_INTERNAL" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigDef 'FLT_OUTBOUND' "$FLT_OUTBOUND" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigDef 'FLT_INBOUND' "$FLT_INBOUND" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigDef 'FLT_LCR_MIN' "$FLT_LCR_MIN" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigDef 'FLT_FWD_MIN' "$FLT_FWD_MIN" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'server.api_server' "${DSIP_API_BASEURL}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'server.api_token' "${DSIP_API_TOKEN}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'server.role' "${ROLE}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.gw_enabled' "${TELEBLOCK_GW_ENABLED}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.gw_ip' "${TELEBLOCK_GW_IP}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.gw_port' "${TELEBLOCK_GW_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.media_ip' "${TELEBLOCK_MEDIA_IP}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigGlobal 'teleblock.media_port' "${TELEBLOCK_MEDIA_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}

    # hot reloading global settings
    if systemctl is-active --quiet kamailio 2>/dev/null; then
        sendKamCmd cfg.sets server role "${ROLE}" &>/dev/null
        sendKamCmd cfg.sets server api_server "${DSIP_API_BASEURL}" &>/dev/null
        sendKamCmd cfg.sets server api_token "${DSIP_API_TOKEN}" &>/dev/null
        sendKamCmd cfg.seti teleblock gw_enabled "${TELEBLOCK_GW_ENABLED}" &>/dev/null
        sendKamCmd cfg.sets teleblock gw_ip "${TELEBLOCK_GW_IP}" &>/dev/null
        sendKamCmd cfg.seti teleblock gw_port "${TELEBLOCK_GW_PORT}" &>/dev/null
        sendKamCmd cfg.sets teleblock media_ip "${TELEBLOCK_MEDIA_IP}" &>/dev/null
        sendKamCmd cfg.seti teleblock media_port "${TELEBLOCK_MEDIA_PORT}" &>/dev/null
    fi

    # check for cluster db connection and set kam db config settings appropriately
    # note: the '@' symbol must be escaped in perl regex
    if printf '%s' "$KAM_DB_HOST" | grep -q -oP '(\[.*\]|.*,.*)'; then
        # db connection is clustered
        enableKamailioConfigFeature 'WITH_DBCLUSTER' ${DSIP_KAMAILIO_CONFIG_FILE}

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

    # update kamailio TLS config file
    perl -e "\$external_ip='${EXTERNAL_IP}'; \$wss_port='${KAM_WSS_PORT}';" \
        -0777 -i -pe 's%(#========== webrtc_domain_start ==========#.*?\[server:).*?:.*?(\].*#========== webrtc_domain_stop ==========#)%\1${external_ip}:${wss_port}\2%s' \
        ${DSIP_KAMAILIO_TLS_CONFIG_FILE}
}

# update kamailio service startup commands accounting for any changes
function updateKamailioStartup {
    local KAM_UPDATE_OPTS=""

    # update kamailio configs on reboot
    removeInitCmd "${DSIP_PROJECT_DIR}/dsiprouter.sh updatekamconfig"
    if (( ${OVERRIDE_SERVERNAT} == 1 )); then
        KAM_UPDATE_OPTS="--servernat=${SERVERNAT}"
    fi
    addInitCmd "${DSIP_PROJECT_DIR}/dsiprouter.sh updatekamconfig $KAM_UPDATE_OPTS"

    # make sure dsip-init service runs prior to kamailio service
    removeDependsOnInit "kamailio.service"
    addDependsOnInit "kamailio.service"
}

# updates and settings in rtpengine config that may change
# should be run after reboot or change in network configurations
function updateRtpengineConfig {
    if (( ${SERVERNAT:-0} == 0 )); then
        INTERFACE="${INTERNAL_IP}"
    else
        INTERFACE="${INTERNAL_IP}!${EXTERNAL_IP}"
    fi
    setRtpengineConfigAttrib 'interface' "$INTERFACE" ${SYSTEM_RTPENGINE_CONFIG_FILE}
}

# update rtpengine service startup commands accounting for any changes
function updateRtpengineStartup {
    local RTP_UPDATE_OPTS=""

    # update rtpengine configs on reboot
    removeInitCmd "${DSIP_PROJECT_DIR}/dsiprouter.sh updatertpconfig"
    if (( ${OVERRIDE_SERVERNAT} == 1 )); then
        RTP_UPDATE_OPTS="--servernat=${SERVERNAT}"
    fi
    addInitCmd "${DSIP_PROJECT_DIR}/dsiprouter.sh updatertpconfig $RTP_UPDATE_OPTS"

    # make sure dsip-init service runs prior to rtpengine service
    removeDependsOnInit "rtpengine.service"
    addDependsOnInit "rtpengine.service"
}

# updates DNSmasq configs from DB
function updateDnsConfig {
    local KAM_DB_HOST=${KAM_DB_HOST:-$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})}
    local KAM_DB_PORT=${KAM_DB_PORT:-$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})}
    local KAM_DB_NAME=${KAM_DB_NAME:-$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})}
    local KAM_DB_USER=${KAM_DB_USER:-$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})}
    local KAM_DB_PASS=${KAM_DB_PASS:-$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})}
    local DSIP_CLUSTER_ID=${DSIP_CLUSTER_ID:-$(getConfigAttrib 'DSIP_CLUSTER_ID' ${DSIP_CONFIG_FILE})}
    # temp-fix for cloud-init not updating hostname in /etc/hosts on boot
    local DNS_CONFIG="127.0.1.1 $(hostname -f 2>/dev/null) $(hostname)\n"

    # grab hosts from db
    local INTERNAL_CLUSTER_HOSTS=(
        $(mysql -sN --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" --user="${KAM_DB_USER}" --password="${KAM_DB_PASS}" --database="${KAM_DB_NAME}" \
            -e "SELECT INTERNAL_IP_ADDR FROM dsip_settings WHERE DSIP_CLUSTER_ID = ${DSIP_CLUSTER_ID};" 2>/dev/null)
    )
    local EXTERNAL_CLUSTER_HOSTS=(
        $(mysql -sN --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" --user="${KAM_DB_USER}" --password="${KAM_DB_PASS}" --database="${KAM_DB_NAME}" \
            -e "SELECT EXTERNAL_IP_ADDR FROM dsip_settings WHERE DSIP_CLUSTER_ID = ${DSIP_CLUSTER_ID};" 2>/dev/null)
    )
    local NUM_HOSTS=${#INTERNAL_CLUSTER_HOSTS[@]}

    # only search through cluster hosts if we got results
    if (( ${NUM_HOSTS} > 0 )); then
        # find valid connections on dmq port:
        # try internal ip first and then external ip
        for i in $(seq 0 $((${NUM_HOSTS}-1))); do
            if checkConn ${INTERNAL_CLUSTER_HOSTS[$i]} ${KAM_DMQ_PORT}; then
                DNS_CONFIG+="${INTERNAL_CLUSTER_HOSTS[$i]} local.cluster\n"
            elif checkConn ${EXTERNAL_CLUSTER_HOSTS[$i]} ${KAM_DMQ_PORT}; then
                DNS_CONFIG+="${EXTERNAL_CLUSTER_HOSTS[$i]} local.cluster\n"
            fi
        done
    # otherwise make sure local node is resolvable when querying cluster
    else
        DNS_CONFIG+="${INTERNAL_IP} local.cluster\n"
    fi

    # update hosts file
    perl -e "\$cluster_hosts=\"${DNS_CONFIG}\";" \
        -0777 -i -pe 's|(#+DSIP_CONFIG_START).*?(#+DSIP_CONFIG_END)|\1\n${cluster_hosts}\2|gms' /etc/hosts

    # tell dnsmasq to reload configs
    if [ -f /var/run/dnsmasq/dnsmasq.pid ]; then
        kill -SIGHUP $(cat /var/run/dnsmasq/dnsmasq.pid) 2>/dev/null
    elif [ -f /var/run/dnsmasq.pid ]; then
        kill -SIGHUP $(cat /var/run/dnsmasq.pid) 2>/dev/null
    else
        kill -SIGHUP $(pidof dnsmasq) 2>/dev/null
    fi
}

function updateCACertsDir {
    awk -v dsip_certs_dir="${DSIP_CERTS_DIR}" \
        'BEGIN {c=0;}
        /BEGIN CERT/{c++} {
            print > "${dsip_certs_dir}/ca/cert." c ".pem"
        }' <${DSIP_CERTS_DIR}/ca-list.pem
    openssl rehash ${DSIP_CERTS_DIR}/ca/
    chown -R dsiprouter:kamailio ${DSIP_CERTS_DIR}/ca/
    chmod 640 ${DSIP_CERTS_DIR}/ca/cert.*.pem
}

# Update dynamic addresses in address table
function updateDynamicAddresses {
    local OLD_ADDR_IDS=( ) NEW_ADDR_IDS=( ) NEW_ADDR_LIST=( ) SQL_STATEMENTS=( )
    lcaol OLD_ADDR_ID="" UAC_ID="" SIP_ADDR="" INSERT_TEMPLATE=""

    # update resolved IP address entries for dr_gateways entries using DNS addresses
    # - dr_gateways to address mapping: dr_gateways.description['addr_list'] -> address.id
    while IFS= read -r ROW; do
        # split up the fields
        OLD_ADDR_IDS=( $(cut -d $'\t' -f 1 <<<"$ROW") )
        SIP_ADDR=$(cut -d $'\t' -f 2 <<<"$ROW")

        # get other address fields (should be same for the list of addresses)
        INSERT_TEMPLATE=$(
            mysql -sNA --user="$KAM_DB_USER" --password="$KAM_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $KAM_DB_NAME \
                -e "SELECT * FROM address WHERE id IN (${OLD_ADDR_IDS[@]}) LIMIT 1;" |
                awk -F $'\t' '{printf "INSERT INTO address VALUES(NULL,%s,RESOLVED_ADDR,%s,%s,%s);",$2,$4,$5,$6}'
        )

        # delete old addresses and create new ones
        SQL_STATEMENTS+=("DELETE FROM address WHERE id IN (${OLD_ADDR_IDS[@]});")
        for ADDR in $(hostToIP -a "$SIP_ADDR"); do
            NEW_ADDR_LIST+=("$ADDR")
            SQL_STATEMENTS+=( $(perl -e "\$addr='$ADDR';" -pe 's%RESOLVED_ADDR%${addr}%' <<<"$INSERT_TEMPLATE" 2>/dev/null) )
        done

        # run sql statements as a transaction and check for errors
        sqlAsTransaction --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" --db="$KAM_DB_NAME" "${SQL_STATEMENTS[@]}"
        (( $? != 0 )) && { printerr 'Failed updating gateway associated addresses'; cleanupAndExit 1; }

        # update address list
        NEW_ADDR_IDS=( $(
        mysql -sNA --user="$KAM_DB_USER" --password="$KAM_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $KAM_DB_NAME \
            -e "SELECT id FROM address WHERE ip_addr IN ($(joinwith '' ',' '' ${NEW_ADDR_LIST[@]});"
        ) )

        # run sql statements as a transaction and check for errors
        sqlAsTransaction --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" --db="$KAM_DB_NAME" \
            "UPDATE dr_gateways SET description = JSON_REPLACE(description, '$.addr_list', '[$(joinwith '' ',' '' ${NEW_ADDR_IDS[@]})]');"
        (( $? != 0 )) && { printerr 'Failed updating gateway associated addresses'; cleanupAndExit 1; }

    done < <(
    mysql -sNA --user="$KAM_DB_USER" --password="$KAM_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $KAM_DB_NAME <<-'EOF'
SELECT REGEXP_REPLACE(JSON_EXTRACT(description, '$.addr_list'), '\\[([^\\[\\]]+)\\]', '\\1') AS addr_list, address AS sip_addr
FROM dr_gateways
WHERE JSON_EXISTS(description, '$.addr_list')
  AND REGEXP_REPLACE(address,
    '^'
    '(?:(?P<proto>[a-zA-Z]+):/?/?)?'
    '(?:(?P<userpw>[a-zA-Z0-9\\-_.]+(?::.+)?)(?:@))?'
    '(?:'
    '(?:\\[?(?P<ipv6>(?:[0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(?::[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(?:ffff(?::0{1,4}){0,1}:){0,1}(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])|(?:[0-9a-fA-F]{1,4}:){1,4}:(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\\]?)|'
    '(?P<ipv4>(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\\.(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\\.(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\\.(?:[0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))|'
    '(?P<host>(?:(?:[a-zA-Z0-9]|[a-zA-Z0-9_][a-zA-Z0-9\\-_]*[a-zA-Z0-9])\\.)*(?:[a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9]))'
    ')'
    '(?::(?P<port>[1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5]))?'
    '(?P<path>/[^\\s?;]*)?'
    '(?:(?:[?;])(?P<params>.*))?'
    '$',
    '\\5') <> '';
EOF
)

    # reset vars
    OLD_ADDR_IDS=( ) NEW_ADDR_IDS=( ) NEW_ADDR_LIST=( ) SQL_STATEMENTS=( )
    OLD_ADDR_ID="" UAC_ID="" SIP_ADDR="" INSERT_TEMPLATE=""

    # update resolved IP address entries for dr_gateways and uacreg entries using DNS addresses
    # - dr_gateways to address mapping: dr_gateways.description['addr_list'] -> address.id
    # - uacreg to address mapping: uacreg.l_uuid -> dr_gw_lists.id, dr_gw_lists.description['name']+'-uac' -> address.tag['name']
    while IFS= read -r ROW; do
        # split up the fields
        OLD_ADDR_ID=$(cut -d $'\t' -f 1 <<<"$ROW")
        UAC_ID=$(cut -d $'\t' -f 2 <<<"$ROW")

        # get other address fields (will make new address associated to uac entry)
        INSERT_TEMPLATE=$(
            mysql -sNA --user="$KAM_DB_USER" --password="$KAM_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $KAM_DB_NAME \
                -e "SELECT * FROM address WHERE id='$OLD_ADDR_ID' LIMIT 1;" |
                awk -F $'\t' '{printf "INSERT INTO address VALUES(NULL,%s,RESOLVED_ADDR,%s,%s,%s);",$2,$4,$5,$6}'
        )

        # delete old addresses and create new ones
        SQL_STATEMENTS+=("DELETE FROM address WHERE id='$OLD_ADDR_ID';")
        for ADDR in $(hostToIP -a "$SIP_ADDR"); do
            NEW_ADDR_LIST+=("$ADDR")
            SQL_STATEMENTS+=( $(perl -e "\$addr='$ADDR';" -pe 's%RESOLVED_ADDR%${addr}%' <<<"$INSERT_TEMPLATE" 2>/dev/null) )
        done

        # update address list
        NEW_ADDR_IDS=( $(
        mysql -sNA --user="$KAM_DB_USER" --password="$KAM_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $KAM_DB_NAME \
            -e "SELECT id FROM address WHERE ip_addr IN ($(joinwith '' ',' '' ${NEW_ADDR_LIST[@]});"
        ) )
    done < <(
    mysql -sNA --user="$KAM_DB_USER" --password="$KAM_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $KAM_DB_NAME <<-'EOF'
SELECT t1.id AS uac_id, t3.id AS addr_id
FROM uacreg t1
  JOIN dr_gw_lists t2 ON t1.l_uuid = t2.id
  JOIN address t3 ON CONCAT(JSON_UNQUOTE(JSON_EXTRACT(t2.description, '$.name')), '-uac') =
                     JSON_UNQUOTE(JSON_EXTRACT(t3.tag, '$.name'));
EOF
)

    # run sql statements after collecting them all, as a transaction and check for errors
    sqlAsTransaction --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" --db="$KAM_DB_NAME" "${SQL_STATEMENTS[@]}"
    (( $? != 0 )) && { printerr 'Failed updating uac auth associated addresses'; cleanupAndExit 1; }

    # update local addresses that may change as network changes
    local INTERNAL_NET_PREFIX=$(echo -n "$INTERNAL_NET" | cut -d '/' -f 2)
    sqlAsTransaction --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" --db="$KAM_DB_NAME" \
        "UPDATE address set ip_addr='$INTERNAL_IP', mask='$INTERNAL_NET_PREFIX' WHERE JSON_UNQUOTE(JSON_EXTRACT(tag, '$.name')) = 'dsip-internal';"
    (( $? != 0 )) && { printerr 'Failed updating internal dynamic addresses'; cleanupAndExit 1; }
}

function generateKamailioConfig {
    # copy of template kamailio configuration to dsiprouter system config dir
    cp -f ${DSIP_KAMAILIO_CONFIG_DIR}/kamailio_dsiprouter.cfg ${DSIP_KAMAILIO_CONFIG_FILE}
    cp -f ${DSIP_KAMAILIO_CONFIG_DIR}/tls_dsiprouter.cfg ${DSIP_KAMAILIO_TLS_CONFIG_FILE}

    # Set the External IP Address for the WebRTC Port
    perl -e "\$external_ip='${EXTERNAL_IP}'; \$wss_port='${KAM_WSS_PORT}';" \
        -0777 -i -pe 's%(#========== webrtc_domain_start ==========#.*?\[server:).*?:.*?(\].*#========== webrtc_domain_stop ==========#)%\1${external_ip}:${wss_port}\2%s' \
        ${DSIP_KAMAILIO_TLS_CONFIG_FILE}

    # version specific settings
    if (( ${KAM_VERSION} >= 52 )); then
        sed -i -r -e 's~#+(modparam\(["'"'"']htable["'"'"'], ?["'"'"']dmq_init_sync["'"'"'], ?[0-9]\))~\1~g' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi

    # Fix the mpath
    fixMPATH

    # non-module features to enable
    if (( ${WITH_LCR} == 1 )); then
        enableKamailioConfigFeature 'WITH_LCR' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigFeature 'WITH_LCR' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi

    # Backup kamcfg and link the dsiprouter kamcfg
    cp -f ${SYSTEM_KAMAILIO_CONFIG_FILE} ${SYSTEM_KAMAILIO_CONFIG_FILE}.$(date +%Y%m%d_%H%M%S) 2>/dev/null
    cp -f ${SYSTEM_KAMAILIO_TLS_CONFIG_FILE} ${SYSTEM_KAMAILIO_TLS_CONFIG_FILE}.$(date +%Y%m%d_%H%M%S) 2>/dev/null
    rm -f ${SYSTEM_KAMAILIO_CONFIG_FILE} 2>/dev/null
    rm -f ${SYSTEM_KAMAILIO_TLS_CONFIG_FILE} 2>/dev/null
    ln -sf ${DSIP_KAMAILIO_CONFIG_FILE} ${SYSTEM_KAMAILIO_CONFIG_FILE}
    ln -sf ${DSIP_KAMAILIO_TLS_CONFIG_FILE} ${SYSTEM_KAMAILIO_TLS_CONFIG_FILE}

    # kamcfg will contain plaintext passwords / tokens
    # make sure we give it reasonable permissions
    chown root:kamailio ${DSIP_KAMAILIO_CONFIG_FILE}
    chmod 0640 ${DSIP_KAMAILIO_CONFIG_FILE}
}

function configureKamailioDB {
    # make sure kamailio user and privileges exist
    if ! checkDBUserExists --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" \
    "${KAM_DB_USER}@localhost"; then
        mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $ROOT_DB_NAME \
            -e "CREATE USER '$KAM_DB_USER'@'localhost' IDENTIFIED BY '$KAM_DB_PASS';" \
            -e "GRANT ALL PRIVILEGES ON $KAM_DB_NAME.* TO '$KAM_DB_USER'@'localhost';" \
            -e "FLUSH PRIVILEGES;"
    fi
    if ! checkDBUserExists --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" \
    "${KAM_DB_USER}@%"; then
        mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $ROOT_DB_NAME \
            -e "CREATE USER '$KAM_DB_USER'@'%' IDENTIFIED BY '$KAM_DB_PASS';" \
            -e "GRANT ALL PRIVILEGES ON $KAM_DB_NAME.* TO '$KAM_DB_USER'@'%';" \
            -e "FLUSH PRIVILEGES;"
    fi

    # Install schema for drouting module
    mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}"  $KAM_DB_NAME \
        -e "delete from version where table_name in ('dr_gateways','dr_groups','dr_gw_lists','dr_custom_rules','dr_rules')"
    mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        -e "drop table if exists dr_gateways,dr_groups,dr_gw_lists,dr_custom_rules,dr_rules"
    if [ -e  /usr/share/kamailio/mysql/drouting-create.sql ]; then
        mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
            < /usr/share/kamailio/mysql/drouting-create.sql
    else
        sqlscript=$(find / -name '*drouting-create.sql' | grep 'mysql' | head -1)
        mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
            < $sqlscript
    fi

    # Update schema for address table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/address.sql

    # Update schema for carrierroute table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/carrierroute.sql

    # Update schema for carrierfailureroute table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/carrierfailureroute.sql

    # Update schema for dispatcher table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dispatcher.sql

    # Update schema for domainpolicy table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/domainpolicy.sql

    # Update schema for dr_gateways table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dr_gateways.sql

    # Update schema for dr_groups table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dr_groups.sql

    # Update schema for dr_gw_lists table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dr_gw_lists.sql

    # Update schema for dr_rules table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dr_rules.sql

    # Update schema for globalblacklist table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/globalblacklist.sql

    # Update schema for lcr_gw table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/lcr_gw.sql

    # Update schema for speed_dial table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/speed_dial.sql

    # Update schema for subscribers table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/subscriber.sql

    # Update schema for trusted table
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/trusted.sql

    # Install schema for custom LCR logic
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dsip_lcr.sql

    # Install schema for custom MaintMode logic
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dsip_maintmode.sql

    # Install schema for Call Limit
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dsip_calllimit.sql

    # Install schema for Notifications
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dsip_notification.sql

    # Install schema for gw2gwgroup
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
        < ${DSIP_DEFAULTS_DIR}/dsip_gw2gwgroup.sql

    # Install schema for dsip_cdrinfo
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" $KAM_DB_NAME --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" \
        < ${DSIP_DEFAULTS_DIR}/dsip_cdrinfo.sql

    # Install schema for dsip_settings
    envsubst < ${DSIP_DEFAULTS_DIR}/dsip_settings.sql |
        mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" $KAM_DB_NAME --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}"

    # Install schema for dsip_hardfwd and dsip_failfwd and dsip_prefix_mapping
    sed -e "s|FLT_INBOUND_REPLACE|${FLT_INBOUND}|g" ${DSIP_DEFAULTS_DIR}/dsip_forwarding.sql |
        mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME

    # TODO: we need to test and re-implement this.
#    # required if tables exist and we are updating
#    function resetIncrementers {
#        SQL_TABLES=$(
#            (for t in "$@"; do printf ",'$t'"; done) | cut -d ',' -f '2-'
#        )
#
#        # reset auto increment for related tables to max btwn the related tables
#        INCREMENT=$(
#            mysql --skip-column-names --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $ROOT_DB_NAME \ -e "\
#                SELECT MAX(AUTO_INCREMENT) FROM INFORMATION_SCHEMA.TABLES \
#                WHERE TABLE_SCHEMA = '$KAM_DB_NAME' \
#                AND TABLE_NAME IN($SQL_TABLES);"
#        )
#        for t in "$@"; do
#            mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
#                -e "ALTER TABLE $t AUTO_INCREMENT=$INCREMENT"
#        done
#    }
#
#    # reset auto incrementers for related tables
#    resetIncrementers "dr_gw_lists"
#    resetIncrementers "uacreg"

    # truncate tables first if kamailio already installed
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
        mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME \
            -e "TRUNCATE TABLE address; TRUNCATE TABLE dr_gateways; TRUNCATE TABLE dr_rules;"
    fi

    # import default carriers and outbound routes
    mkdir -p /tmp/defaults
    local INTERNAL_NET_PREFIX=$(echo -n "$INTERNAL_NET" | cut -d '/' -f 2)
    # generate defaults subbing in dynamic values
    cp -f ${DSIP_DEFAULTS_DIR}/dr_gw_lists.csv /tmp/defaults/dr_gw_lists.csv
    sed "s/FLT_CARRIER/$FLT_CARRIER/g; s/FLT_PBX/$FLT_PBX/g; s/FLT_MSTEAMS/$FLT_MSTEAMS/g; s/FLT_INTERNAL/$FLT_INTERNAL/g; s/INTERNAL_IP/$INTERNAL_IP/g; s/INTERNAL_NET_PREFIX/$INTERNAL_NET_PREFIX/g;" \
        ${DSIP_DEFAULTS_DIR}/address.csv > /tmp/defaults/address.csv
    sed "s/FLT_CARRIER/$FLT_CARRIER/g; s/FLT_PBX/$FLT_PBX/g; s/FLT_MSTEAMS/$FLT_MSTEAMS/g; s/FLT_INTERNAL/$FLT_INTERNAL/g;" \
        ${DSIP_DEFAULTS_DIR}/dr_gateways.csv > /tmp/defaults/dr_gateways.csv
    sed "s/FLT_OUTBOUND/$FLT_OUTBOUND/g; s/FLT_INBOUND/$FLT_INBOUND/g;" \
        ${DSIP_DEFAULTS_DIR}/dr_rules.csv > /tmp/defaults/dr_rules.csv

    # import default carriers
    mysqlimport --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" \
        --fields-terminated-by=';' --ignore-lines=0  -L $KAM_DB_NAME /tmp/defaults/address.csv
    mysqlimport --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" \
        --fields-terminated-by=';' --ignore-lines=0  -L $KAM_DB_NAME /tmp/defaults/dr_gw_lists.csv
    mysqlimport --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" \
        --fields-terminated-by=';' --ignore-lines=0  -L $KAM_DB_NAME /tmp/defaults/dr_gateways.csv
    mysqlimport --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" \
        --fields-terminated-by=';' --ignore-lines=0  -L $KAM_DB_NAME /tmp/defaults/dr_rules.csv

    # cleanup temp files
    rm -rf /tmp/defaults
}

# TODO: deprecated since CLI command is being deprecated
function enableSERVERNAT {
    enableKamailioConfigFeature 'WITH_SERVERNAT' ${DSIP_KAMAILIO_CONFIG_FILE}

    printwarn "SERVERNAT is enabled - Restarting Kamailio is required"
    printwarn "You can restart it by executing: systemctl restart kamailio"
}
# TODO: deprecated since CLI command is being deprecated
function disableSERVERNAT {
	disableKamailioConfigFeature 'WITH_SERVERNAT' ${DSIP_KAMAILIO_CONFIG_FILE}

	printwarn "SERVERNAT is disabled - Restarting Kamailio is required"
	printdbg "You can restart it by executing: systemctl restart kamailio"
}

# Try to locate the Kamailio modules directory.  It will use the last modules directory found
function fixMPATH {
    mpath=$(find /usr/lib{32,64,}/{i386*/*,i386*/kamailio/*,x86_64*/*,x86_64*/kamailio/*,*} -name drouting.so -printf '%h/' -quit 2>/dev/null)

    if [ "$mpath" != '' ]; then
        setKamailioConfigGlobal 'mpath' "${mpath}" ${DSIP_KAMAILIO_CONFIG_FILE}
        printdbg "The Kamailio mpath has been updated to: $mpath"
    else
        printerr "Can't find the module path for Kamailio.  Please ensure Kamailio is installed and try again!"
        cleanupAndExit 1
    fi
}

# Requirements to run this script / any imported functions
installScriptRequirements() {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.requirementsinstalled" ]; then
        return
    fi

    printdbg 'Installing one-time script requirements'
    if cmdExists 'apt-get'; then
        DEBIAN_FRONTEND=noninteractive apt-get update -y &&
        DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget gawk perl sed git dnsutils
    elif cmdExists 'yum'; then
        yum update -y &&
        yum install -y curl wget gawk perl sed git bind-utils
    fi

    if (( $? != 0 )); then
        printerr 'Could not install script requirements'
        cleanupAndExit 1
    else
        printdbg 'One-time script requirements installed'
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.requirementsinstalled
    fi
}

# Configure system repo sources to ensure we get the right package versions
# TODO: support configuring ubuntu/centos/amazon linux repo's
#       - ubuntu refs:
#       https://repogen.simplylinux.ch/
#       https://mirrors.ustc.edu.cn/repogen/
#       https://gist.github.com/rhuancarlos/c4d3c0cf4550db5326dca8edf1e76800
#       - centos refs:
#       https://unix.stackexchange.com/questions/52666/how-do-i-install-the-stock-centos-repositories
#       https://wiki.centos.org/PackageManagement/Yum/Priorities
configureSystemRepos() {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.reposconfigured" ]; then
        return
    fi

    printdbg 'Configuring system repositories'
    if [[ "$DISTRO" == "debian" ]]; then
        mv -f ${APT_OFFICIAL_SOURCES} ${APT_OFFICIAL_SOURCES_BAK} 2>/dev/null
        mv -f ${APT_OFFICIAL_PREFS} ${APT_OFFICIAL_PREFS_BAK} 2>/dev/null
        cp -f ${DSIP_PROJECT_DIR}/resources/apt/debian/official-releases.list ${APT_OFFICIAL_SOURCES}
        envsubst < ${DSIP_PROJECT_DIR}/resources/apt/debian/official-releases.pref >${APT_OFFICIAL_PREFS}
        apt-get update -y
    elif [[ "$DISTRO" == "centos" ]]; then
        # TODO: create official repo file (centos repo's)
        # TODO: install yum priorities plugin
        # TODO: set priorities on official repo

        true
    elif [[ "$DISTRO" == "amazon" ]]; then
        # TODO: create official repo file (centos or amazon repo's? probably centos w/ less priority than amazon repo's)
        # TODO: install yum priorities plugin
        # TODO: set priorities on official repo

        true
    elif [[ "$DISTRO" == "ubuntu" ]]; then
        # TODO: create official repo list
        # TODO: create preferences and set priorities for ubuntu specific versions
#        cp -f ${DSIP_PROJECT_DIR}/resources/apt/ubuntu/official-releases.list ${APT_OFFICIAL_SOURCES}
#        envsubst < ${DSIP_PROJECT_DIR}/resources/apt/ubuntu/official-releases.pref > ${APT_OFFICIAL_PREFS}
#        apt-get update -y

        true
    fi

    if (( $? == 1 )); then
        printerr 'Could not configure system repositories'
        cleanupAndExit 1
    elif (( $? >= 100 )); then
	    printwarn 'Some issue(s) with system repositories'
    else
        printdbg 'System repositories configured successfully'
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.reposconfigured
    fi
}

# remove dsiprouter system configs
removeDsipSystemConfig() {
    rm -rf ${DSIP_SYSTEM_CONFIG_DIR}

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.reposconfigured" ]; then
        if cmdExists 'apt-get'; then
            mv -f ${APT_OFFICIAL_SOURCES_BAK} ${APT_OFFICIAL_SOURCES}
            mv -f ${APT_OFFICIAL_PREFS_BAK} ${APT_OFFICIAL_PREFS}
            apt-get update -y
#        elif cmdExists 'yum'; then
#            rm -f ${YUM_OFFICIAL_REPOS}
#            yum update -y
        fi
    fi
}

# Install and configure mysql server
function installMysql {
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.mysqlinstalled" ]]; then
        printwarn "MySQL is already installed"
        return
    fi

    printdbg "Attempting to install / congifure MySQL..."
    ${DSIP_PROJECT_DIR}/mysql/${DISTRO}/${DISTRO_VER}.sh install

    if (( $? != 0 )); then
        printerr "MySQL install failed"
        cleanupAndExit 1
    fi

    # Restart MySQL with the new configurations
    systemctl restart mysql
    if systemctl is-active --quiet mysql; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.mysqlinstalled
        printdbg "------------------------------------"
        pprint "MySQL Installation is complete!"
        printdbg "------------------------------------"
    else
        printerr "MySQL install failed"
        cleanupAndExit 1
    fi
}

# Remove mysql and its configs
function uninstallMysql {
    if [[ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.mysqlinstalled" ]]; then
        printwarn "MySQL is not installed - skipping removal"
        return
    fi

    printdbg "Attempting to uninstall MySQL..."
    ${DSIP_PROJECT_DIR}/mysql/$DISTRO/${DISTRO_VER}.sh uninstall

    if (( $? != 0 )); then
        printerr "MySQL uninstall failed"
        cleanupAndExit 1
    fi

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.mysqlinstalled
    printdbg "MySQL was uninstalled"
}

# Install the RTPEngine from sipwise
function installRTPEngine {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]; then
        printwarn "RTPEngine is already installed"
        return
    fi

    printdbg "Attempting to install RTPEngine..."
    ${DSIP_PROJECT_DIR}/rtpengine/${DISTRO}/install.sh install
    ret=$?
    if (( $ret == 0 )); then
        enableKamailioConfigFeature 'WITH_RTPENGINE' ${DSIP_KAMAILIO_CONFIG_FILE}
        systemctl restart kamailio
        printdbg "configuring RTPEngine service"
    elif (( $ret == 2 )); then
        enableKamailioConfigFeature 'WITH_RTPENGINE' ${DSIP_KAMAILIO_CONFIG_FILE}
        printwarn "RTPEngine install waiting on reboot"
        cleanupAndExit 0
    else
        printerr "RTPEngine install failed"
        cleanupAndExit 1
    fi

    updateRtpengineStartup

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
    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]; then
        printwarn "RTPEngine is not installed! - uninstalling anyway to be safe"
    fi

    printdbg "Attempting to uninstall RTPEngine..."
    ${DSIP_PROJECT_DIR}/rtpengine/$DISTRO/install.sh uninstall

    if (( $? == 0 )); then
        if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
            disableKamailioConfigFeature 'WITH_RTPENGINE' ${DSIP_KAMAILIO_CONFIG_FILE}
            systemctl restart kamailio
        fi
    else
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

# TODO: allow password changes on cloud instances (remove password reset after image creation)
# we should be starting the web server as root and dropping root privilege after
# this is standard practice, but we would have to consider file permissions
# it would be easier to manage if we moved dsiprouter configs to /etc/dsiprouter
function installDsiprouter {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]; then
        printwarn "dSIPRouter is already installed"
        return
    fi

	printdbg "Attempting to install dSIPRouter..."
    # configure generated source files prior to install
    configurePythonSettings
    ${DSIP_PROJECT_DIR}/dsiprouter/${DISTRO}/${DISTRO_VER}.sh install

	if [ $? -ne 0 ]; then
	    printerr "dSIPRouter install failed"
	    cleanupAndExit 1
	else
	    printdbg "Configuring dSIPRouter settings"
	fi

    # if python was just installed its not exported in this proc yet
 	setPythonCmd
    if [ $? -ne 0 ]; then
        printerr "dSIPRouter install failed"
        cleanupAndExit 1
    fi

    # add dsiprouter CLI command to the path
    ln -s ${DSIP_PROJECT_DIR}/dsiprouter.sh /usr/bin/dsiprouter
    # enable bash command line completion if not already
    perl -i -0777 -pe 's%#(if ! shopt -oq posix; then\n)#([ \t]+if \[ -f /usr/share/bash-completion/bash_completion \]; then\n)#(.*?\n)#(.*?\n)#(.*?\n)#(.*?\n)#(.*?\n)%\1\2\3\4\5\6\7%s' /etc/bash.bashrc
    # add command line completion for dsiprouter CLI
    cp -f ${DSIP_PROJECT_DIR}/dsiprouter/dsip_completion.sh /etc/bash_completion.d/dsiprouter
    . /etc/bash_completion
    # make sure current python version is in the path
    # required in dsiprouter.py shebang (will fail startup without)
    ln -sf ${PYTHON_CMD} "/usr/local/bin/python${REQ_PYTHON_MAJOR_VER}"

    # Set dsip private key (used for encryption across services) by following precedence:
    # 1:    set via cmdline arg
    # 2:    set prior to externally
    # 3:    generate new key
    if [[ -n "${SET_DSIP_PRIV_KEY}" ]]; then
        printf '%s' "${SET_DSIP_PRIV_KEY}" > ${DSIP_PRIV_KEY}
    elif [ -f "${DSIP_PRIV_KEY}" ]; then
        :
    else
        ${PYTHON_CMD} -c "import os,sys; os.chdir('${DSIP_PROJECT_DIR}/gui'); sys.path.insert(0, '/etc/dsiprouter/gui'); from util.security import AES_CTR; AES_CTR.genKey()"
    fi

    # Generate UUID unique to this dsiprouter instance
    uuidgen > ${DSIP_UUID_FILE}

    # Generate unique credentials for our services
    RESET_DSIP_GUI_PASS=1 RESET_DSIP_API_TOKEN=1 RESET_KAM_DB_PASS=1 RESET_DSIP_IPC_TOKEN=1
    resetPassword
    # Set credentials if any given on CLI
    setCredentials

    # configure dsiprouter modules
    installModules

    # Restrict access to settings and private key
    chown dsiprouter:root ${DSIP_PRIV_KEY}
    chmod 0400 ${DSIP_PRIV_KEY}
    chown dsiprouter:root ${DSIP_CONFIG_FILE}
    chmod 0600 ${DSIP_CONFIG_FILE}

    # dsiprouter needs to have control over the kamailio dir (dynamic changes may be made)
    chown dsiprouter:kamailio ${DSIP_SYSTEM_CONFIG_DIR}/kamailio
    # Set permissions on the backup directory and subdirectories
    chown -R dsiprouter:root ${BACKUPS_DIR}
    # Set the permissions of the cert directory now that dSIPRouter has been installed
    chown dsiprouter:kamailio ${DSIP_CERTS_DIR}/*

    # for cloud images the instance-id may change (could be a clone)
    # add to startup process a password reset to ensure its set correctly
    # this is only for cloud image builds and is removed after first boot
    if (( $IMAGE_BUILD == 1 )) && (( $AWS_ENABLED == 1 || $DO_ENABLED == 1 || $GCE_ENABLED == 1 || $AZURE_ENABLED == 1 || VULTR_ENABLED == 1 )); then
        (cat << EOF
#!/usr/bin/env bash

# declare any constants imported functions rely on
DSIP_INIT_FILE="$DSIP_INIT_FILE"

# declare imported functions from library
$(declare -f removeInitCmd)

# reset admin user password and remove startup cmd from dsip-init
${DSIP_PROJECT_DIR}/dsiprouter.sh resetpassword -fid

removeInitCmd '.reset_admin_pass.sh'
rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.reset_admin_pass.sh

exit 0
EOF
        ) > ${DSIP_SYSTEM_CONFIG_DIR}/.reset_admin_pass.sh
        chmod +x ${DSIP_SYSTEM_CONFIG_DIR}/.reset_admin_pass.sh
        addInitCmd "${DSIP_SYSTEM_CONFIG_DIR}/.reset_admin_pass.sh"

        # Required changes for Debian-based AMI's
        if (( $AWS_ENABLED == 1 )) && [[ $DISTRO == "debian" || $DISTRO == "ubuntu" ]]; then
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
$(declare -f isInstanceVULTR)
$(declare -f getInstanceID)
$(declare -f removeInitCmd)

# reset debian user password and remove startup cmd from dsip-init
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
            addInitCmd "${DSIP_SYSTEM_CONFIG_DIR}/.reset_debiansys_user.sh"
        fi
    fi

    # generate documentation for GUI
    # TODO: we should fix these errors instead of masking them
    cd ${DSIP_PROJECT_DIR}/docs &&
    make html >/dev/null 2>&1
    cd -

    # install documentationor the CLI
    installManPage

    # add dependency on dsip-init service in startup boot order
    addDependsOnInit "dsiprouter.service"

    # Restart dSIPRouter and Kamailio with new configurations
    if [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled ]; then
    	systemctl restart kamailio
    fi
    systemctl restart dsiprouter
    if systemctl is-active --quiet dsiprouter; then
        # custom dsiprouter MOTD banner for ssh logins
        # only update on successfull install so we don't confuse user
        updateBanner

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

    # remove dsip-init service dependency
    removeDependsOnInit "dsiprouter.service"

    # Remove dsiprouter crontab entries
    printdbg "Removing dsiprouter crontab entries"
    cronRemove 'dsiprouter_cron.py'

    # Remove dsip private key
    rm -f ${DSIP_PRIV_KEY}

    # revert to previous MOTD ssh login banner
    revertBanner

    # remove dsiprouter and dsiprouterd commands from the path
    rm -f /usr/bin/dsiprouter
    # remove command line completion for dsiprouter.sh
    rm -f /etc/bash_completion.d/dsiprouter

    # remove CLI documentation
    uninstallManPage

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled

    printdbg "dSIPRouter was uninstalled"
}

function installKamailio {
    local NOW=$(date '+%s')
    local KAMDB_BACKUP_DIR="${BACKUPS_DIR}/kamdb"
    local KAMDB_DATABASE_BACKUP_FILE="${KAMDB_BACKUP_DIR}/db-${NOW}.sql"
    local KAMDB_USER_BACKUP_FILE="${KAMDB_BACKUP_DIR}/user-${NOW}.sql"

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
        printwarn "kamailio is already installed"
        return
    else
        printdbg "Attempting to install Kamailio..."
    fi

    # backup and drop kam db if it exists already
    mkdir -p ${KAMDB_BACKUP_DIR}

    if cmdExists 'mysql'; then
        if checkDB --user="$ROOT_DB_USER" --pass="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME; then
            printdbg "Backing up kamailio DB to ${KAMDB_DATABASE_BACKUP_FILE} before fresh install"
            dumpDB --user="$ROOT_DB_USER" --pass="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $KAM_DB_NAME > ${KAMDB_DATABASE_BACKUP_FILE}
            mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $ROOT_DB_NAME \
                -e "DROP DATABASE $KAM_DB_NAME;"
            printdbg "Backing up kamailio DB Users to ${KAMDB_USER_BACKUP_FILE} before fresh install"
            dumpDBUser --user="$ROOT_DB_USER" --pass="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" "${KAM_DB_USER}@${KAM_DB_NAME}" > ${KAMDB_USER_BACKUP_FILE}
            mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $ROOT_DB_NAME \
                -e "DROP USER IF EXISTS '$KAM_DB_USER'@'%'; DROP USER IF EXISTS '$KAM_DB_USER'@'localhost';"
        fi
    fi

    ${DSIP_PROJECT_DIR}/kamailio/${DISTRO}/${DISTRO_VER}.sh install ${KAM_VERSION} ${DSIP_PORT}
    if (( $? == 0 )); then
        configureSSL
        configureKamailioDB
        generateKamailioConfig
        updateKamailioConfig
        updateKamailioStartup
        # update dynamic addresses every 5 minutes
        cronAppend "*/5 * * * * ${DSIP_PROJECT_DIR}/dsiprouter.sh updatedynamicaddrs"
    else
        printerr "kamailio install failed"
        cleanupAndExit 1
    fi

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

    # remove cronjobs for kamailio
    cronRemove "${DSIP_PROJECT_DIR}/dsiprouter.sh updatedynamicaddrs"

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled

    printdbg "kamailio was uninstalled"
}


function installModules {
    # Remove any previous dsiprouter cronjobs
    cronRemove 'dsiprouter_cron.py'

    # Install / Uninstall dSIPModules
    for dir in ${DSIP_PROJECT_DIR}/gui/modules/*; do
        if [[ -e ${dir}/install.sh ]]; then
            ${dir}/install.sh
        fi
    done
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
    if cmdExists 'apt-get'; then
        apt-get install -y make gcc g++ automake autoconf openssl check git dirmngr pkg-config dh-autoreconf
    elif cmdExists 'yum'; then
        yum install -y make gcc gcc-c++ automake autoconf openssl check git
    fi

    # Install testing requirements
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

# Install DNSmasq stub resolver for local DNS
# used by kamailio dmq replication
# TODO: right now updating /etc/hosts is messy because some cloud configs don't update it properly
#       i.e.) could-init does not update hostnames properly
#       we should instead integrate / configure these init systems on install
# TODO: right now we disabled systemd-resolvd and manually configure /etc/resolv.conf
#       we should instead integrate with systemd-resolvd or openresolv or network-manager
# TODO: move DNSmasq install to its own directory
installDnsmasq() {
    local START_DIR="$(pwd)"
    local DNSMASQ_LISTEN_ADDRS="127.0.0.1"
    local DNSMASQ_NAME_SERVERS=("nameserver 127.0.0.1")
    local DNSMASQ_NAME_SERVERS_REV=("nameserver 127.0.0.1")

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled" ]; then
        printwarn "DNSmasq is already installed"
        return
    else
        printdbg "Attempting to install DNSmasq"
    fi

    # ipv6 compatibility
    if (( ${IPV6_ENABLED} == 1 )); then
        DNSMASQ_LISTEN_ADDRS="127.0.0.1,::1"
        DNSMASQ_NAME_SERVERS=("nameserver 127.0.0.1" "nameserver ::1")
        DNSMASQ_NAME_SERVERS_REV=("nameserver ::1" "nameserver 127.0.0.1")
    fi

    # create dnsmasq user and group
    # output removed, some cloud providers (DO) use caching and output is misleading
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel dnsmasq &>/dev/null; groupdel dnsmasq &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "DNSmasq DNS Resolver" dnsmasq &>/dev/null

    # install dnsmasq
    if cmdExists 'apt-get'; then
        apt-get install -y dnsmasq
    elif cmdExists 'yum'; then
        yum install -y dnsmasq
    fi

    # if systemd dns resolver is installed disable it
    systemctl stop systemd-resolved 2>/dev/null
    systemctl disable systemd-resolved 2>/dev/null

    # dnsmasq configuration
    mv -f /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
    cat << EOF >/etc/dnsmasq.conf
port=53
domain-needed
bogus-priv
strict-order
listen-address=${DNSMASQ_LISTEN_ADDRS}
bind-interfaces
user=dnsmasq
group=dnsmasq
conf-file=/etc/dnsmasq.conf
resolv-file=/etc/resolv.conf
pid-file=/var/run/dnsmasq/dnsmasq.pid
EOF

    # make sure dnsmasq is first nameserver (utilizing dhclient)
    [ ! -f "/etc/dhcp/dhclient.conf" ] && touch /etc/dhcp/dhclient.conf
    if grep -q 'DSIP_CONFIG_START' /etc/dhcp/dhclient.conf 2>/dev/null; then
        perl -0777 -i -pe "s|(#+DSIP_CONFIG_START).*?(#+DSIP_CONFIG_END)|\1\nprepend domain-name-servers ${DNSMASQ_LISTEN_ADDRS};\n\2|gms" /etc/dhcp/dhclient.conf
    else
        printf '\n%s\n%s\n%s\n\n' \
            '#####DSIP_CONFIG_START' \
            "prepend domain-name-servers ${DNSMASQ_LISTEN_ADDRS};" \
            '#####DSIP_CONFIG_END' >> /etc/dhcp/dhclient.conf
    fi
    if ! grep -q -E 'nameserver 127\.0\.0\.1|nameserver ::1' /etc/resolv.conf 2>/dev/null; then
        # extra check in case no nameserver found
        if ! grep -q 'nameserver' /etc/resolv.conf 2>/dev/null; then
            joinwith '' $'\n' '' "${DNSMASQ_NAME_SERVERS[@]}" >> /etc/resolv.conf
        else
            tac /etc/resolv.conf | sed -r -e "0,\|^nameserver.*|{s||$(joinwith '' '' '\n' "${DNSMASQ_NAME_SERVERS_REV[@]}" | tac)&|}" | tac >/tmp/resolv.conf
            mv -f /tmp/resolv.conf /etc/resolv.conf
        fi
    fi

    # setup hosts in cluster node is resolvable
    # cron and kam service will configure these dynamically
    if grep -q 'DSIP_CONFIG_START' /etc/hosts 2>/dev/null; then
        perl -e "\$int_ip='${INTERNAL_IP}'; \$ext_ip='${EXTERNAL_IP}'; \$int_fqdn='${INTERNAL_FQDN}'; \$ext_fqdn='${EXTERNAL_FQDN}';" \
            -0777 -i -pe 's|(#+DSIP_CONFIG_START).*?(#+DSIP_CONFIG_END)|\1\n${int_ip} ${int_fqdn} local.cluster\n${ext_ip} ${ext_fqdn} local.cluster\n\2|gms' /etc/hosts
    else
        printf '\n%s\n%s\n%s\n\n' \
            '#####DSIP_CONFIG_START' \
            "${INTERNAL_IP} ${INTERNAL_FQDN} local.cluster" \
            "${EXTERNAL_IP} ${EXTERNAL_FQDN} local.cluster" \
            '#####DSIP_CONFIG_END' >> /etc/hosts
    fi

    # configure systemd service
    (cat <<'EOF'
[Unit]
Description=dnsmasq - A lightweight DHCP and caching DNS server
Requires=network.target
Wants=nss-lookup.target
Before=nss-lookup.target
After=network.target

[Service]
Type=forking
PIDFile=/run/dnsmasq/dnsmasq.pid
Environment='RUN_DIR=/var/run/dnsmasq'
PIDFile=/var/run/dnsmasq/dnsmasq.pid
# make sure everything is setup correctly before starting
ExecStartPre=!-/bin/mkdir -p ${RUN_DIR}
ExecStartPre=!-/bin/chown -R dnsmasq:dnsmasq ${RUN_DIR}
ExecStartPre=/usr/sbin/dnsmasq --test
# We run dnsmasq via the /etc/init.d/dnsmasq script which acts as a
# wrapper picking up extra configuration files and then execs dnsmasq
# itself, when called with the "systemd-exec" function.
ExecStart=/etc/init.d/dnsmasq systemd-exec
# The systemd-*-resolvconf functions configure (and deconfigure)
# resolvconf to work with the dnsmasq DNS server. They're called like
# this to get correct error handling (ie don't start-resolvconf if the
# dnsmasq daemon fails to start.
ExecStartPost=/etc/init.d/dnsmasq systemd-start-resolvconf
ExecStop=/etc/init.d/dnsmasq systemd-stop-resolvconf
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
    ) >/etc/systemd/system/dnsmasq.service

    # start on boot
    systemctl daemon-reload
    systemctl enable dnsmasq

    # update DNS hosts prior to dSIPRouter startup
    addInitCmd "${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig"
    # update DNS hosts every minute
    cronAppend "0 * * * * ${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig"

    systemctl restart dnsmasq
    if systemctl is-active --quiet dnsmasq; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled
        pprint "DNSmasq was installed"
    else
        printerr "DNSmasq install failed"
        cleanupAndExit 1
    fi

    cd ${START_DIR}
}

uninstallDnsmasq() {
    local START_DIR="$(pwd)"

    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled" ]; then
        printwarn "DNSmasq is not installed or failed during install - uninstalling anyway to be safe"
    fi

    # stop the process
    systemctl stop dnsmasq

    # uninstall dnsmasq
    if cmdExists 'apt-get'; then
        apt-get remove -y dnsmasq
    elif cmdExists 'yum'; then
        yum remove -y dnsmasq
    fi

    # remove dnsmasq configuration
    rm -f /etc/dnsmasq.conf /etc/dnsmasq.conf.bak 2>/dev/null

    # remove localhost from name servers
    sed -ir -e '/#+DSIP_CONFIG_START/,/#+DSIP_CONFIG_END/d' /etc/dhcp/dhclient.conf
    sed -i -e '/nameserver 127.0.0.1/d' /etc/resolv.conf

    # remove cluster hosts from /etc/hosts
    sed -ir -e '/#+DSIP_CONFIG_START/,/#+DSIP_CONFIG_END/d' /etc/hosts

    # remove cron job
    cronRemove "${DSIP_PROJECT_DIR}/dsiprouter.sh updatednsconfig"

    # if systemd dns resolver installed re-enable it
    systemctl enable systemd-resolved 2>/dev/null
    systemctl start systemd-resolved 2>/dev/null

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled

    printdbg "DNSmasq was uninstalled"

    cd ${START_DIR}
}

function start {
    local START_DSIPROUTER=${START_DSIPROUTER:-1}
    local START_KAMAILIO=${START_KAMAILIO:-0}
    local START_RTPENGINE=${START_RTPENGINE:-0}

    # propagate runtime settings to the app config
    updatePythonRuntimeSettings

    # Start Kamailio if told to and installed
    if (( $START_KAMAILIO == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled ]; then
        systemctl start kamailio
        # Make sure process is still running
        if ! systemctl is-active --quiet kamailio; then
            printerr "Unable to start Kamailio"
            cleanupAndExit 1
        else
            pprint "Kamailio was started"
        fi
    fi

    # Start RTPEngine if told to and installed
    if (( $START_RTPENGINE == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled ]; then
        systemctl start rtpengine
        # Make sure process is still running
        if ! systemctl is-active --quiet rtpengine; then
            printerr "Unable to start RTPEngine"
            cleanupAndExit 1
        else
            pprint "RTPEngine was started"
        fi
    fi

    # Start the dSIPRouter if told to and installed
    if (( $START_DSIPROUTER == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled ]; then
        if (( $DEBUG == 1 )); then
            # perform pre-startup commands systemd would normally do
            mkdir -p ${DSIP_RUN_DIR}
            chown -R dsiprouter:dsiprouter ${DSIP_RUN_DIR}
            chown -R dsiprouter:root ${BACKUPS_DIR}
            chown -R dsiprouter:dsiprouter ${DSIP_SYSTEM_CONFIG_DIR}/gui
            chown -R dsiprouter:kamailio ${DSIP_SYSTEM_CONFIG_DIR}/certs
            chown -R dsiprouter:kamailio ${DSIP_SYSTEM_CONFIG_DIR}/kamailio
            # start the reverse proxy first
            systemctl start nginx
            # keep dSIPRouter in the foreground, only used for debugging issues
            sudo -u dsiprouter -g dsiprouter ${PYTHON_CMD} ${DSIP_PROJECT_DIR}/gui/dsiprouter.py
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
            # start the reverse proxy first
            systemctl start nginx
            # normal startup, fork dSIPRouter as background process
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
    local STOP_DSIPROUTER=${STOP_DSIPROUTER:-1}
    local STOP_KAMAILIO=${STOP_KAMAILIO:-0}
    local STOP_RTPENGINE=${STOP_RTPENGINE:-0}

    # propagate runtime settings to the app config
    updatePythonRuntimeSettings

    # Stop Kamailio if told to and installed
    if (( $STOP_KAMAILIO == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled ]; then
        systemctl stop kamailio
        # Make sure process is not running
        if systemctl is-active --quiet kamailio; then
            printerr "Unable to stop Kamailio"
            cleanupAndExit 1
        else
            pprint "Kamailio was stopped"
        fi
    fi

    # Stop RTPEngine if told to and installed
    if (( $STOP_RTPENGINE == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled ]; then
        systemctl stop rtpengine
        # Make sure process is not running
        if systemctl is-active --quiet rtpengine; then
            printerr "Unable to stop RTPEngine"
            cleanupAndExit 1
        else
            pprint "RTPEngine was stopped"
        fi
    fi

    # Stop the dSIPRouter if told to and installed
    if (( $STOP_DSIPROUTER == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled ]; then
	    systemctl stop nginx
        # if started in debug mode we have to manually kill the process
        if ! systemctl is-active --quiet dsiprouter; then
            pkill -SIGTERM -f dsiprouter
            if pgrep -f nginx &>/dev/null; then
                printerr "Unable to stop dSIPRouter"
                cleanupAndExit 1
            else
                pprint "dSIPRouter was stopped"
            fi
        else
            systemctl stop dsiprouter
            if systemctl is-active --quiet dsiprouter; then
                printerr "Unable to stop dSIPRouter"
                cleanupAndExit 1
            else
                pprint "dSIPRouter was stopped"
            fi
        fi
    fi
}

function displayLoginInfo {
    local DSIP_USERNAME=${DSIP_USERNAME:-$(getConfigAttrib 'DSIP_USERNAME' ${DSIP_CONFIG_FILE})}
    local DSIP_PASSWORD=${DSIP_PASSWORD:-"<HASH CAN NOT BE UNDONE> (reset password if you forgot it)"}
    local DSIP_API_TOKEN=${DSIP_API_TOKEN:-$(decryptConfigAttrib 'DSIP_API_TOKEN' ${DSIP_CONFIG_FILE})}
    local DSIP_IPC_SOCK="$(getConfigAttrib 'DSIP_IPC_SOCK' ${DSIP_CONFIG_FILE})"
    local DSIP_IPC_PASS=${DSIP_IPC_PASS:-$(decryptConfigAttrib 'DSIP_IPC_PASS' ${DSIP_CONFIG_FILE})}
    local KAM_DB_USER=${KAM_DB_USER:-$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})}
    local KAM_DB_PASS=${KAM_DB_PASS:-$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})}

    echo -ne '\n'
    printdbg "Your systems credentials are below (keep in a safe place)"
    pprint "dSIPRouter GUI Username: ${DSIP_USERNAME}"
    pprint "dSIPRouter GUI Password: ${DSIP_PASSWORD}"
    pprint "dSIPRouter API Token: ${DSIP_API_TOKEN}"
    pprint "dSIPRouter IPC Password: ${DSIP_IPC_PASS}"
    pprint "Kamailio DB Username: ${KAM_DB_USER}"
    pprint "Kamailio DB Password: ${KAM_DB_PASS}"
    echo -ne '\n'

    printdbg "You can access the dSIPRouter WEB GUI here"
    pprint "External IP: ${DSIP_PROTO}://${EXTERNAL_IP}:${DSIP_PORT}"
    if [ "$EXTERNAL_IP" != "$INTERNAL_IP" ];then
        pprint "Internal IP: ${DSIP_PROTO}://${INTERNAL_IP}:${DSIP_PORT}"
    fi
    echo -ne '\n'

    printdbg "You can access the dSIPRouter REST API here"
    pprint "External IP: ${DSIP_API_PROTO}://${EXTERNAL_IP}:${DSIP_PORT}"
    if [ "$EXTERNAL_IP" != "$INTERNAL_IP" ];then
        pprint "Internal IP: ${DSIP_API_PROTO}://${INTERNAL_IP}:${DSIP_PORT}"
    fi
    echo -ne '\n'

    printdbg "You can access the dSIPRouter IPC API here"
    pprint "UNIX Domain Socket: ${DSIP_IPC_SOCK}"
    echo -ne '\n'

    printdbg "You can access the Kamailio DB here"
    pprint "Database Host: ${KAM_DB_HOST}:${KAM_DB_PORT}"
    pprint "Database Name: ${KAM_DB_NAME}"
    echo -ne '\n'
}

# resets credentials for our services to a new random value by default
# mail credentials don't apply bcuz they pertain to an external service
# only cloud image builds will use the instance ID unless explicitly forced
function resetPassword {
    printdbg 'Resetting credentials'

    local RESET_DSIP_GUI_PASS=${RESET_DSIP_GUI_PASS:-1}
    local RESET_DSIP_API_TOKEN=${RESET_DSIP_API_TOKEN:-1}
    local RESET_KAM_DB_PASS=${RESET_KAM_DB_PASS:-1}
    local RESET_DSIP_IPC_TOKEN=${RESET_DSIP_IPC_TOKEN:-1}
    local RESET_FORCE_INSTANCE_ID=${RESET_FORCE_INSTANCE_ID:-0}

    if (( $RESET_DSIP_GUI_PASS == 1 )); then
        if (( $IMAGE_BUILD == 1 || $RESET_FORCE_INSTANCE_ID == 1 )); then
            if [[ -n "$CLOUD_PLATFORM" ]]; then
                export DSIP_PASSWORD=$(getInstanceID)
            fi
        else
            export DSIP_PASSWORD=$(urandomChars 64)
        fi
    fi
    if (( $RESET_DSIP_API_TOKEN == 1 )); then
        export DSIP_API_TOKEN=$(urandomChars 64)
    fi
    if (( $RESET_KAM_DB_PASS == 1 )); then
        export KAM_DB_PASS=$(urandomChars 64)
    fi
    if (( $RESET_DSIP_IPC_TOKEN == 1 )); then
        export DSIP_IPC_PASS=$(urandomChars 64)
    fi

    ${PYTHON_CMD} << EOF
import os,sys; os.chdir('${DSIP_PROJECT_DIR}/gui');
sys.path.insert(0, '/etc/dsiprouter/gui')
from util.security import Credentials; from util.ipc import sendSyncSettingsSignal;
Credentials.setCreds(dsip_creds='${DSIP_PASSWORD}', api_creds='${DSIP_API_TOKEN}', kam_creds='${KAM_DB_PASS}', ipc_creds='${DSIP_IPC_PASS}');
try:
    sendSyncSettingsSignal();
except:
    pass
EOF

    if (( $RESET_KAM_DB_PASS == 1 )); then
	    mysql --user="$ROOT_DB_USER" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" $ROOT_DB_NAME \
            -e "set password for $KAM_DB_USER@localhost = PASSWORD('${KAM_DB_PASS}');flush privileges"
    fi

    # can be hot reloaded while running
    if (( $RESET_DSIP_API_TOKEN == 1 )); then
        updateKamailioConfig
        printdbg 'Credentials have been updated'
    # can NOT be hot reloaded while running
    elif (( $RESET_KAM_DB_PASS == 1 )); then
        printwarn 'Restarting services with new configurations'
        systemctl restart kamailio
        systemctl restart dsiprouter
        printdbg 'Credentials have been updated'
    # all configs already hot reloaded
    else
        printdbg 'Credentials have been updated'
    fi
}

# updates credentials in dsip / kam config files / kam db
# also exports credentials to variables for latter commands
function setCredentials {
    printdbg 'Setting credentials'

    # variables that can be set prior to running
    local SET_DSIP_GUI_USER="${SET_DSIP_GUI_USER}"
    local SET_DSIP_GUI_PASS="${SET_DSIP_GUI_PASS}"
    local SET_DSIP_API_TOKEN="${SET_DSIP_API_TOKEN}"
    local SET_DSIP_MAIL_USER="${SET_DSIP_MAIL_USER}"
    local SET_DSIP_MAIL_PASS="${SET_DSIP_MAIL_PASS}"
    local SET_DSIP_IPC_TOKEN="${SET_DSIP_IPC_TOKEN}"
    local SET_KAM_DB_USER="${SET_KAM_DB_USER}"
    local SET_KAM_DB_PASS="${SET_KAM_DB_PASS}"
    local SET_KAM_DB_HOST="${SET_KAM_DB_HOST}"
    local SET_KAM_DB_PORT="${SET_KAM_DB_PORT}"
    local SET_KAM_DB_NAME="${SET_KAM_DB_NAME}"
    local SET_ROOT_DB_USER="${SET_ROOT_DB_USER}"
    local SET_ROOT_DB_PASS="${SET_ROOT_DB_PASS}"
    local SET_ROOT_DB_NAME="${SET_ROOT_DB_NAME}"
    local LOAD_SETTINGS_FROM=${LOAD_SETTINGS_FROM:-$(getConfigAttrib 'LOAD_SETTINGS_FROM' ${DSIP_CONFIG_FILE})}
    local DSIP_ID=${DSIP_ID:-$(getConfigAttrib 'DSIP_ID' ${DSIP_CONFIG_FILE})}
    # the SQL statements to run for these updates
    local SQL_STATEMENTS=()
    local DEFERRED_SQL_STATEMENTS=()
    # how settings will be propagated to live systems
    # 0 == no reload required, 1 == hot reload required, 2 == hard reload required
    local RELOAD_TYPE=0

    # sanity check, can we connect to the DB as the root user?
    # we determine if user already changed DB creds (and just want dsiprouter to store them accordingly)
    if checkDB --user="$ROOT_DB_USER" --pass="$ROOT_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" $ROOT_DB_NAME ; then
        :
    elif checkDB --user="${SET_ROOT_DB_USER:-$ROOT_DB_USER}" --pass="${SET_ROOT_DB_PASS:-$ROOT_DB_PASS}" \
    --host="${SET_KAM_DB_HOST:-$KAM_DB_HOST}" --port="${SET_KAM_DB_PORT:-$KAM_DB_PORT}" \
    ${SET_ROOT_DB_NAME:-$ROOT_DB_NAME}; then
        KAM_DB_HOST=${SET_KAM_DB_HOST:-$KAM_DB_HOST}
        KAM_DB_PORT=${SET_KAM_DB_PORT:-$KAM_DB_PORT}
        ROOT_DB_USER=${SET_ROOT_DB_USER:-$ROOT_DB_USER}
        ROOT_DB_PASS=${SET_ROOT_DB_PASS:-$ROOT_DB_PASS}
        ROOT_DB_NAME=${SET_ROOT_DB_NAME:-$ROOT_DB_NAME}
    else
        printerr 'Connection to DB failed'
        cleanupAndExit 1
    fi

    # update non-encrypted settings locally and gather statements for updating DB
    if [[ -n "${SET_DSIP_GUI_USER}" ]]; then
        SQL_STATEMENTS+=("update kamailio.dsip_settings set DSIP_USERNAME='${SET_DSIP_GUI_USER}' where DSIP_ID=${DSIP_ID};")
        setConfigAttrib 'DSIP_USERNAME' "$SET_DSIP_GUI_USER" ${DSIP_CONFIG_FILE} -q
    fi
    if [[ -n "${SET_DSIP_API_TOKEN}" ]]; then
        RELOAD_TYPE=1
    fi
    if [[ -n "${SET_DSIP_MAIL_USER}" ]]; then
        SQL_STATEMENTS+=("update kamailio.dsip_settings set MAIL_USERNAME='${SET_DSIP_MAIL_USER}' where DSIP_ID=${DSIP_ID};")
        setConfigAttrib 'MAIL_USERNAME' "$SET_DSIP_MAIL_USER" ${DSIP_CONFIG_FILE} -q
    fi
    if [[ -n "${SET_KAM_DB_USER}" ]]; then
        RELOAD_TYPE=2
        # if user exists update username, otherwise we need to create the user
        if checkDBUserExists --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" \
        "${KAM_DB_USER}@localhost"; then
            DEFERRED_SQL_STATEMENTS+=("update mysql.user set User='$SET_KAM_DB_USER' where User='$KAM_DB_USER' AND Host='localhost';")
        else
            DEFERRED_SQL_STATEMENTS+=("CREATE USER '$SET_KAM_DB_USER'@'localhost' IDENTIFIED BY '${SET_KAM_DB_PASS:-$KAM_DB_PASS}';")
            DEFERRED_SQL_STATEMENTS+=("GRANT ALL PRIVILEGES ON $KAM_DB_NAME.* TO '$SET_KAM_DB_USER'@'localhost';")
        fi
        if checkDBUserExists --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" \
        "${KAM_DB_USER}@%"; then
            DEFERRED_SQL_STATEMENTS+=("update mysql.user set User='$SET_KAM_DB_USER' where User='$KAM_DB_USER' AND Host='%';")
        else
            DEFERRED_SQL_STATEMENTS+=("CREATE USER '$SET_KAM_DB_USER'@'%' IDENTIFIED BY '${SET_KAM_DB_PASS:-$KAM_DB_PASS}';")
            DEFERRED_SQL_STATEMENTS+=("GRANT ALL PRIVILEGES ON $KAM_DB_NAME.* TO '$SET_KAM_DB_USER'@'%';")
        fi
        SQL_STATEMENTS+=("update kamailio.dsip_settings set KAM_DB_USER='${SET_KAM_DB_USER}' where DSIP_ID=${DSIP_ID};")
        setConfigAttrib 'KAM_DB_USER' "$SET_KAM_DB_USER" ${DSIP_CONFIG_FILE} -q
    fi
    if [[ -n "${SET_KAM_DB_PASS}" ]]; then
        RELOAD_TYPE=2
        DEFERRED_SQL_STATEMENTS+=("update mysql.user set authentication_string=PASSWORD('${SET_KAM_DB_PASS}') where User='${SET_KAM_DB_USER:-$KAM_DB_USER}';")
    fi
    if [[ -n "${SET_KAM_DB_HOST}" ]]; then
        RELOAD_TYPE=2
        #DEFERRED_SQL_STATEMENTS+=("update mysql.user set Host='${SET_KAM_DB_HOST}' where User='${SET_KAM_DB_USER:-$KAM_DB_USER}' and Host<>'${KAM_DB_HOST}';")
        #DEFERRED_SQL_STATEMENTS+=("update mysql.user set Host='${SET_KAM_DB_HOST}' where User='${SET_ROOT_DB_USER:-$ROOT_DB_USER}' and Host='${KAM_DB_HOST}';")
        setConfigAttrib 'KAM_DB_HOST' "$SET_KAM_DB_HOST" ${DSIP_CONFIG_FILE} -q
        reconfigureMysqlSystemdService
    fi
    if [[ -n "${SET_KAM_DB_PORT}" ]]; then
        RELOAD_TYPE=2
        setConfigAttrib 'KAM_DB_PORT' "$SET_KAM_DB_PORT" ${DSIP_CONFIG_FILE} -q
    fi
    # TODO: allow changing live database name
    if [[ -n "${SET_KAM_DB_NAME}" ]]; then
        RELOAD_TYPE=2
        setConfigAttrib 'KAM_DB_NAME' "$SET_KAM_DB_NAME" ${DSIP_CONFIG_FILE} -q
    fi
    if [[ -n "${SET_ROOT_DB_USER}" ]]; then
        DEFERRED_SQL_STATEMENTS+=("update mysql.user set User='${SET_ROOT_DB_USER}' where User='${ROOT_DB_USER}';")
        setConfigAttrib 'ROOT_DB_USER' "$SET_ROOT_DB_USER" ${DSIP_CONFIG_FILE} -q
    fi
    if [[ -n "${SET_ROOT_DB_PASS}" ]]; then
        DEFERRED_SQL_STATEMENTS+=("update mysql.user set authentication_string=PASSWORD('${SET_ROOT_DB_PASS}') where User='${SET_ROOT_DB_USER:-$ROOT_DB_USER}';")
    fi
    # TODO: allow changing live database name
    if [[ -n "${SET_ROOT_DB_NAME}" ]]; then
        setConfigAttrib 'ROOT_DB_NAME' "$SET_ROOT_DB_NAME" ${DSIP_CONFIG_FILE} -q
    fi
    DEFERRED_SQL_STATEMENTS+=("flush privileges;")

    # update non-encrypted settings on DB
    if [[ "$LOAD_SETTINGS_FROM" == "db" ]]; then
        sqlAsTransaction --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" "${SQL_STATEMENTS[@]}"
        if (( $? != 0 )); then
            printerr 'Failed setting credentials on DB'
            cleanupAndExit 1
        fi
    fi

    # update DB live settings (privileges etc..)
    sqlAsTransaction --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" "${DEFERRED_SQL_STATEMENTS[@]}"
    if (( $? != 0 )); then
        printerr 'Failed setting credentials on DB'
        cleanupAndExit 1
    fi

    # update encrypted settings
    ${PYTHON_CMD} << EOF
import os,sys; os.chdir('${DSIP_PROJECT_DIR}/gui');
sys.path.insert(0, '/etc/dsiprouter/gui')
from util.security import Credentials;
Credentials.setCreds(dsip_creds='${SET_DSIP_GUI_PASS}', api_creds='${SET_DSIP_API_TOKEN}', kam_creds='${SET_KAM_DB_PASS}', mail_creds='${SET_DSIP_MAIL_PASS}', ipc_creds='${SET_DSIP_IPC_TOKEN}');
EOF
    if (( $? != 0 )); then
        printerr 'Failed setting encrypted credentials'
        cleanupAndExit 1
    fi

    # synchronize settings (between local, DB, and cluster)
    ${PYTHON_CMD} << EOF 2>/dev/null
import os,sys; os.chdir('${DSIP_PROJECT_DIR}/gui');
sys.path.insert(0, '/etc/dsiprouter/gui')
from util.ipc import sendSyncSettingsSignal;
sendSyncSettingsSignal();
EOF

    # export variables for later usage in this script
    export DSIP_USERNAME=${SET_DSIP_GUI_USER:-$DSIP_USERNAME}
    export DSIP_PASSWORD=${SET_DSIP_GUI_PASS:-$DSIP_PASSWORD}
    export DSIP_API_TOKEN=${SET_DSIP_API_TOKEN:-$DSIP_API_TOKEN}
    export MAIL_USERNAME=${SET_DSIP_MAIL_USER:-$MAIL_USERNAME}
    export MAIL_PASSWORD=${SET_DSIP_MAIL_PASS:-$MAIL_PASSWORD}
    export DSIP_IPC_PASS=${SET_DSIP_IPC_TOKEN:-$DSIP_IPC_PASS}
    export KAM_DB_USER=${SET_KAM_DB_USER:-$KAM_DB_USER}
    export KAM_DB_PASS=${SET_KAM_DB_PASS:-$KAM_DB_PASS}
    export KAM_DB_HOST=${SET_KAM_DB_HOST:-$KAM_DB_HOST}
    export KAM_DB_PORT=${SET_KAM_DB_PORT:-$KAM_DB_PORT}
    export KAM_DB_NAME=${SET_KAM_DB_NAME:-$KAM_DB_NAME}
    export ROOT_DB_USER=${SET_ROOT_DB_USER:-$ROOT_DB_USER}
    export ROOT_DB_PASS=${SET_ROOT_DB_PASS:-$ROOT_DB_PASS}
    export ROOT_DB_NAME=${SET_ROOT_DB_NAME:-$ROOT_DB_NAME}

    # propagate settings based on reload type required
    if (( ${RELOAD_TYPE} == 0 )); then
        printdbg 'Credentials have been updated'
    elif (( ${RELOAD_TYPE} == 1 )); then
        updateKamailioConfig
        printdbg 'Credentials have been updated'
    elif (( ${RELOAD_TYPE} == 2 )); then
        updateKamailioConfig
        printwarn 'Restarting services with new configurations'
        systemctl restart mysql
        systemctl restart kamailio
        systemctl restart dsiprouter
        printdbg 'Credentials have been updated'
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
    chmod -x /etc/update-motd.d/* 2>/dev/null

    # add our custom banner script (dynamically updates MOTD banner)
    (cat << EOF
#!/usr/bin/env bash

# redefine variables and functions here
ESC_SEQ="$ESC_SEQ"
ANSI_NONE="$ANSI_NONE"
ANSI_GREEN="$ANSI_GREEN"
$(declare -f printdbg)
$(declare -f getConfigAttrib)
$(declare -f displayLogo)
$(declare -f getInternalIP)
$(declare -f getExternalIP)
$(declare -f checkConn)

# updated variables on login
INTERNAL_IP=\$(getInternalIP)
EXTERNAL_IP=\$(getExternalIP)
if [[ -z "\$EXTERNAL_IP" ]]; then
    EXTERNAL_IP="\$INTERNAL_IP"
fi
DSIP_PORT=\$(getConfigAttrib 'DSIP_PORT' ${DSIP_CONFIG_FILE})
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

    # for debian < v9 we have to update the dynamic motd location
    if [[ "$DISTRO" == "debian" && $DISTRO_VER -lt 9 ]]; then
        sed -i -r 's|^(session.*pam_motd\.so.*motd=/run/motd).*|\1|' /etc/pam.d/sshd
    # for centos7 and debian we have to update it 'manually'
    elif [[ "$DISTRO" == "centos" ]]; then
        /etc/update-motd.d/00-dsiprouter > /etc/motd
        cronAppend "*/5 * * * *  /etc/update-motd.d/00-dsiprouter > /etc/motd"
    fi
}

# revert to old MOTD banner for ssh logins
function revertBanner {
    mv -f ${DSIP_SYSTEM_CONFIG_DIR}/motd.bak /etc/motd
    rm -f /etc/update-motd.d/00-dsiprouter
    chmod +x /etc/update-motd.d/* 2>/dev/null

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
# - dnsmasq
# - nginx
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

    case "$DISTRO" in
        centos|amazon)
            # alias and link rsyslog to syslog service as in debian
            # allowing rsyslog to be accessible via syslog namespace
            # the settings are already there just commented out by default
            sed -i -r 's|^[;](.*)|\1|g' /lib/systemd/system/rsyslog.service
            ln -sf /lib/systemd/system/rsyslog.service /etc/systemd/system/syslog.service
            systemctl daemon-reload
            ;;
        *)
            ;;
    esac

    (cat << 'EOF'
[Unit]
Description=dSIPRouter Init Service
Wants=network-online.target syslog.service mysql.service dnsmasq.service nginx.service
After=network.target network-online.target syslog.service mysql.service dnsmasq.service nginx.service
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

# TODO: not finished, not vetted, needs more work
function upgrade {
    KAM_DB_HOST=${KAM_DB_HOST:-$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})}
    KAM_DB_PORT=${KAM_DB_PORT:-$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})}
    KAM_DB_NAME=${KAM_DB_NAME:-$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})}
    KAM_DB_USER=${KAM_DB_USER:-$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})}
    KAM_DB_PASS=${KAM_DB_PASS:-$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})}
    DSIP_CLUSTER_ID=${DSIP_CLUSTER_ID:-$(getConfigAttrib 'DSIP_CLUSTER_ID' ${DSIP_CONFIG_FILE})}

    CURRENT_RELEASE=$(getConfigAttrib 'VERSION' ${DSIP_CONFIG_FILE})

    # Check if already upgraded
    #rel = $((`echo "$CURRENT_RELEASE" == "$UPGRADE_RELEASE" | bc`))
    #if [ $rel -eq 1 ]; then


    #    pprint "dSIPRouter is already updated to $UPGRADE_RELEASE!"
    #    return

    #fi

    # Return an error if the release doesn't exist
   if ! git branch -a --format='%(refname:short)' | grep -qE "^${UPGRADE_RELEASE}\$" 2>/dev/null; then
        printdbg "The $UPGRADE_RELEASE release doesn't exist. Please select another release"
        return 1
   fi

    BACKUP_DIR="/var/backups"
    CURR_BACKUP_DIR="${BACKUP_DIR}/$(date '+%Y-%m-%d')"
    mkdir -p ${BACKUP_DIR} ${CURR_BACKUP_DIR}
    mkdir -p ${CURR_BACKUP_DIR}/{etc,var/lib,${HOME},$(dirname "$DSIP_PROJECT_DIR")}

    cp -r ${DSIP_PROJECT_DIR} ${CURR_BACKUP_DIR}/${DSIP_PROJECT_DIR}
    cp -r ${SYSTEM_KAMAILIO_CONFIG_DIR} ${CURR_BACKUP_DIR}/${SYSTEM_KAMAILIO_CONFIG_DIR}

    #Stash any changes so that GUI will allow us to pull down a new release
    #git stash
    #git checkout $UPGRADE_RELEASE
    #git stash apply

    generateKamailioConfig
    updateKamailioConfig
    updateKamailioStartup

    # Upgrade the version
    setConfigAttrib 'VERSION' "$UPGRADE_RELEASE" ${DSIP_CONFIG_FILE}

    # Restart Kamailio
    systemctl restart kamailio
    systemctl restart dsiprouter
}

# TODO: this is unfinished
function upgradeOld {
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
        --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" > ${CURR_BACKUP_DIR}/mysql_full.sql
    mysqldump --single-transaction --skip-triggers --skip-add-drop-table --insert-ignore \
        --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" ${KAM_DB_NAME} \
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

    mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="${KAM_DB_HOST}" --port="${KAM_DB_PORT}" ${KAM_DB_NAME} < ${CURR_BACKUP_DIR}/kamdb_merge.sql

    # TODO: fix any conflicts that would arise from our new modules / tables in KAMDB

    # TODO: print backup location info to user

    # TODO: transfer / merge backup configs to new configs
    # kam configs
    # dsip configs
    # iptables configs
    # mysql configs

    # TODO: restart services, check for good startup
}

# TODO: add bash cmd completion for new options provided by gitwrapper.sh
function configGitDevEnv {
    ${PYTHON_CMD} -m pip install pipreqs

    mkdir -p ${BACKUPS_DIR}/git/info ${BACKUPS_DIR}/git/hooks
    mkdir -p ${DSIP_PROJECT_DIR}/.git/info ${DSIP_PROJECT_DIR}/.git/hooks

    cp -f ${DSIP_PROJECT_DIR}/.git/info/attributes ${BACKUPS_DIR}/git/info/attributes 2>/dev/null
    cat ${DSIP_PROJECT_DIR}/resources/git/gitattributes >> ${DSIP_PROJECT_DIR}/.git/info/attributes

    cp -f ${DSIP_PROJECT_DIR}/.git/config ${BACKUPS_DIR}/git/config 2>/dev/null
    cat ${DSIP_PROJECT_DIR}/resources/git/gitconfig >> ${DSIP_PROJECT_DIR}/.git/config

    cp -f ${DSIP_PROJECT_DIR}/.git/info/exclude ${BACKUPS_DIR}/git/info/exclude 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/gitignore ${DSIP_PROJECT_DIR}/.git/info/exclude

    cp -f ${DSIP_PROJECT_DIR}/.git/commit-msg ${BACKUPS_DIR}/git/commit-msg 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/commit-msg ${DSIP_PROJECT_DIR}/.git/commit-msg

    cp -f ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit ${BACKUPS_DIR}/git/hooks/pre-commit 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/hooks/pre-commit ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit
    chmod +x ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit

    cp -f ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg ${BACKUPS_DIR}/git/hooks/prepare-commit-msg 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/hooks/prepare-commit-msg ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg
    chmod +x ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg

    cp -f ${DSIP_PROJECT_DIR}/.git/hooks/commit-msg ${BACKUPS_DIR}/git/hooks/commit-msg 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/hooks/commit-msg ${DSIP_PROJECT_DIR}/.git/hooks/commit-msg
    chmod +x ${DSIP_PROJECT_DIR}/.git/hooks/commit-msg

    cp -f ${DSIP_PROJECT_DIR}/.git/hooks/post-commit ${BACKUPS_DIR}/git/hooks/post-commit 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/hooks/post-commit ${DSIP_PROJECT_DIR}/.git/hooks/post-commit
    chmod +x ${DSIP_PROJECT_DIR}/.git/hooks/post-commit

    cp -f ${DSIP_PROJECT_DIR}/.git/hooks/pre-push ${BACKUPS_DIR}/git/hooks/pre-push 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/resources/git/hooks/pre-push ${DSIP_PROJECT_DIR}/.git/hooks/pre-push
    chmod +x ${DSIP_PROJECT_DIR}/.git/hooks/pre-push

    cp -f ${DSIP_PROJECT_DIR}/resources/git/merge-changelog.sh /usr/local/bin/_merge-changelog
    chmod +x /usr/local/bin/_merge-changelog

    cp -f ${DSIP_PROJECT_DIR}/resources/git/check_syntax.py /usr/local/bin/_git_check_syntax
    chmod +x /usr/local/bin/_git_check_syntax

    cp -f ${DSIP_PROJECT_DIR}/resources/git/gitwrapper.sh ${GIT_UPDATE_FILE}
    . ${GIT_UPDATE_FILE}
}

function cleanGitDevEnv {
    mv -f ${BACKUPS_DIR}/git/info/attributes ${DSIP_PROJECT_DIR}/.git/info/attributes 2>/dev/null
    mv -f ${BACKUPS_DIR}/git/config ${DSIP_PROJECT_DIR}/.git/config 2>/dev/null
    mv -f ${BACKUPS_DIR}/git/info/exclude ${DSIP_PROJECT_DIR}/.git/info/exclude 2>/dev/null
    mv -f ${BACKUPS_DIR}/git/commit-msg ${DSIP_PROJECT_DIR}/.git/commit-msg 2>/dev/null
    mv -f ${BACKUPS_DIR}/git/hooks/pre-commit ${DSIP_PROJECT_DIR}/.git/hooks/pre-commit 2>/dev/null
    mv -f ${BACKUPS_DIR}/git/hooks/prepare-commit-msg ${DSIP_PROJECT_DIR}/.git/hooks/prepare-commit-msg 2>/dev/null
    mv -f ${BACKUPS_DIR}/git/hooks/commit-msg ${DSIP_PROJECT_DIR}/.git/hooks/commit-msg 2>/dev/null
    mv -f ${BACKUPS_DIR}/git/hooks/post-commit ${DSIP_PROJECT_DIR}/.git/hooks/post-commit 2>/dev/null
    mv -f ${BACKUPS_DIR}/git/hooks/pre-push ${DSIP_PROJECT_DIR}/.git/hooks/pre-push 2>/dev/null
    rm -f /usr/local/bin/_merge-changelog
    rm -f /usr/local/bin/_git_check_syntax
    rm -f ${GIT_UPDATE_FILE}
}

# run install commands across a cluster of nodes
# TODO: parallel ssh execution for install cmds
# TODO: need to handle re-attempt better, when one node fails and others did not
#       we could overwrite key, attempt install (will pass on already installed configs), re-encrypt
#       this would require some way of knowing whether the credentials changed
#       or we could check for install and decrypt/store creds before replcaing key and re-encrypting
clusterInstall() { (
    local TMP_PRIV_KEY="${DSIP_PROJECT_DIR}/dsip_privkey"
    local SSH_DEFAULT_OPTS="-o StrictHostKeyChecking=no -o CheckHostIp=no -o ServerAliveInterval=5 -o ServerAliveCountMax=2"
    local SSH_HOSTS=() SSH_CMDS=() SSH_PWDS=() SCP_CMDS=()
    local USER PASS HOST PORT SSH_REMOTE_HOST SSH_OPTS SCP_OPTS
    local SSH_CMD="ssh" SCP_CMD="scp"

    printdbg 'Installing requirements for cluster install'
    if cmdExists 'apt-get'; then
        apt-get install -y sshpass
    elif cmdExists 'yum'; then
        yum install -y epel-release sshpass
    fi

    # sanity check
    if (( $? != 0 )); then
        printerr 'Could not install requirements for cluster install'; cleanupAndExit 1
    fi

    # create private key if not set on cmdline
    if [[ -n "${SET_DSIP_PRIV_KEY}" ]]; then
        printf '%s' "${SET_DSIP_PRIV_KEY}" > ${TMP_PRIV_KEY}
        unset SET_DSIP_PRIV_KEY
    else
        dd bs=1 count=32 if=/dev/urandom of=${TMP_PRIV_KEY} 2>/dev/null
    fi
    # protect it until destroyed
    chmod 0400 ${TMP_PRIV_KEY}

    # guarantee key will be destroyed when subshell exits
    cleanupHandler() {
        rm -f ${TMP_PRIV_KEY}
        trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM
    }
    trap 'cleanupHandler $?' EXIT SIGHUP SIGINT SIGQUIT SIGTERM

    # loop through nodes to:
    #  - validate conn
    #  - validate unattended ssh
    #  - collect ssh/scp cmds and pwds
    for NODE in "${SSH_SYNC_NODES[@]}"; do
        # parse node info
        USER=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -d ':' -f -1)
        PASS=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -s -d ':' -f 2-)
        HOST=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1)
        PORT=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -s -d ':' -f 2-)

        # default user is root for ssh
        USER=${USER:-root}
        # default port is 22 for ssh
        PORT=${PORT:-22}
        # host is required per node
        if [ -z "$HOST" ]; then
            printerr "Node [${NODE}] does not contain a host"; usageOptions; exit 1
        else
            SSH_REMOTE_HOST="${HOST}"
        fi
        SSH_REMOTE_HOST="${USER}@${SSH_REMOTE_HOST}"

        # select auth method and set vars accordingly
        if [ -n "$PASS" ]; then
            export SSHPASS="${PASS}"
            SSH_CMD="sshpass -e ssh"
            SCP_CMD="sshpass -e scp"
            SSH_OPTS="${SSH_DEFAULT_OPTS} -o PreferredAuthentications=password"
        else
            SSH_CMD="ssh"
            SCP_CMD="scp"
            SSH_OPTS="${SSH_DEFAULT_OPTS} -o PreferredAuthentications=publickey"
        fi

        # finalize cmds
        SCP_OPTS="${SSH_OPTS} -P ${PORT} -C -p -r -q -o IPQoS=throughput"
        SSH_OPTS="${SSH_OPTS} -p ${PORT}"
        SCP_CMD="${SCP_CMD} ${SCP_OPTS} ${DSIP_PROJECT_DIR}/. ${SSH_REMOTE_HOST}:/tmp/dsiprouter/"
        SSH_CMD="${SSH_CMD} ${SSH_OPTS} ${SSH_REMOTE_HOST}"

        if (( $DEBUG == 1 )); then
            printdbg "SSH_CMD: ${SSH_CMD}"
            printdbg "SCP_CMD: ${SCP_CMD}"
        fi

        printdbg "Validating tcp connection to ${HOST}"
        if ! checkConn ${HOST} ${PORT}; then
            printerr "Could not establish connection to host [${HOST}] on port [${PORT}]"; exit 1
        fi

        printdbg "Validating unattended ssh connection to ${HOST}"
        if ! checkSSH ${SSH_CMD}; then
            printerr "Could not establish unattended ssh connection to [${SSH_REMOTE_HOST}] on port [${PORT}]"; exit 1
        fi

        SSH_CMDS+=( "$SSH_CMD" )
        SCP_CMDS+=( "$SCP_CMD" )
        SSH_PWDS+=( "$PASS" )
        SSH_HOSTS+=( "$HOST" )
    done

    # loop through nodes to:
    # - setup and secure private key
    # - run script install command
    for i in "${!SSH_SYNC_NODES[@]}"; do
        printdbg "Starting remote install on ${SSH_HOSTS[$i]}"

        # password used by ssh/scp
        if [ -n "${SSH_PWDS[$i]}" ]; then
            export SSHPASS="${SSH_PWDS[$i]}"
        fi

        printdbg "Copying project files to ${SSH_HOSTS[$i]}"
        ${SCP_CMDS[$i]} 2>&1
        if (( $? != 0 )); then
            printerr "Copying files to ${SSH_HOSTS[$i]} failed"
            exit 1
        fi

        printdbg "Running remote install on ${SSH_HOSTS[$i]}"
        ${SSH_CMDS[$i]} bash 2>&1 <<- EOSSH
        # local debug of remote commands
        if (( $DEBUG == 1 )); then
            set -x
        fi

        # setting up project files on node
        rm -rf ${DSIP_PROJECT_DIR} 2>/dev/null
        mv -f /tmp/dsiprouter ${DSIP_PROJECT_DIR}

        # setup cluster private key on node
        mkdir -p ${DSIP_SYSTEM_CONFIG_DIR}
        mv -f ${TMP_PRIV_KEY} ${DSIP_PRIV_KEY}
        chown root:root ${DSIP_PRIV_KEY}
        chmod 0400 ${DSIP_PRIV_KEY}

        # run script command
        DSIP_ID=$((i+1)) ${DSIP_PROJECT_DIR}/dsiprouter.sh install ${SSH_SYNC_ARGS[@]}
EOSSH
        if (( $? != 0 )); then
            printerr "Remote install on ${SSH_HOSTS[$i]} failed"
            exit 1
        fi

        i=$((i+1))
    done
) || cleanupAndExit $?; }

function usageOptions {
    linebreak() {
        printf '_%.0s' $(seq 1 ${COLUMNS:-100}) && echo ''
    }

    linebreak
    printf '\n%s\n%s\n' \
        "$(pprint -n USAGE:)" \
        "dsiprouter <command> [options]"

    linebreak
    printf "\n%-s%24s%s\n" \
        "$(pprint -n COMMAND)" " " "$(pprint -n OPTIONS)"
    printf "%-30s %s\n%-30s %s\n%-30s %s\n%-30s %s\n" \
        "install" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine|-servernat|--servernat=<num>|-exip <ip>|--external-ip=<ip>|" \
        " " "-db <[user[:pass]@]dbhost[:port][/dbname]>|--database=<[user[:pass]@]dbhost[:port][/dbname]>|-dsipcid <num>|--dsip-clusterid=<num>|" \
        " " "-dbadmin <[user][:pass][/dbname]>|--database-admin=<[user][:pass][/dbname]>|-dsipcsync <num>|--dsip-clustersync=<num>|" \
        " " "-dsipkey <32 chars>|--dsip-privkey=<32 chars>|-with_lcr|--with_lcr=<num>|-with_dev|--with_dev=<num>|-homer <homer_host[:heplify_port]>]"
    printf "%-30s %s\n" \
        "uninstall" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine]"
    printf "%-30s %s\n" \
        "upgrade" "[-debug] <-rel <release number>|--release=<release number>>"
    printf "%-30s %s\n" \
        "clusterinstall" "[-debug|-homer <homer_host[:heplify_port]>|] <[user1[:pass1]@]node1[:port1]> <[user2[:pass2]@]node2[:port2]> ... -- [INSTALL OPTIONS]"
    printf "%-30s %s\n" \
        "start" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine]"
    printf "%-30s %s\n" \
        "stop" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine]"
    printf "%-30s %s\n" \
        "restart" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine]"
    printf "%-30s %s\n" \
        "configurekam" "[-debug|-servernat|--servernat=<num>]"
    printf "%-30s %s\n" \
        "renewsslcert" "[-debug]"
    printf "%-30s %s\n" \
        "configuresslcert" "[-debug|-f|--force]"
    printf "%-30s %s\n" \
        "installmodules" "[-debug]"
    printf "%-30s %s\n" \
        "enableservernat" "[-debug]"
    printf "%-30s %s\n" \
        "disableservernat" "[-debug]"
    printf "%-30s %s\n" \
        "resetpassword" "[-debug|-all|--all|-dc|--dsip-creds|-ac|--api-creds|-kc|--kam-creds|-ic|--ipc-creds|-fid|--force-instance-id]"
    printf "%-30s %s\n%-30s %s\n%-30s %s\n%-30s %s\n" \
        "setcredentials" "[-debug|-dc <[user][:pass]>|--dsip-creds=<[user][:pass]>|-ac <token>|--api-creds=<token>|" \
        " " "-kc <[user[:pass]@]dbhost[:port][/dbname]>|--kam-creds=<[user[:pass]@]dbhost[:port][/dbname]>|" \
        " " "-mc <[user][:pass]>|--mail-creds=<[user][:pass]>|-ic <token>|--ipc-creds=<token>]|" \
        " " "-dac <[user][:pass][/dbname]>|--db-admin-creds=<[user][:pass][/dbname]>"
    printf "%-30s %s\n" \
        "generatekamconfig" "[-debug]"
    printf "%-30s %s\n" \
        "updatekamconfig" "[-debug|-servernat|--servernat=<num>]"
    printf "%-30s %s\n" \
        "updatertpconfig" "[-debug|-servernat|--servernat=<num>]"
    printf "%-30s %s\n" \
        "updatednsconfig" "[-debug]"
    printf "%-30s %s\n" \
        "version|-v|--version" ""
    printf "%-30s %s\n" \
        "help|-h|--help" ""

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

# make the output a little cleaner
# shellcheck disable=SC2120
function setVerbosityLevel {
    if [[ "$*" != *"-debug"* ]]; then
        # quiet pkg managers when not debugging
        if cmdExists 'apt-get'; then
            function apt-get() {
                command apt-get -qq "$@"
            }
            export -f apt-get
        fi
        if cmdExists 'yum'; then
            function yum() {
                command yum -q -e 0 "$@"
            }
            export -f yum
        fi
        if cmdExists 'dnf'; then
            function dnf() {
                command dnf -q -e 0 "$@"
            }
            export -f dnf
        fi
        # quiet make when not debugging
        function make() {
            command make -s "$@"
        }
        export -f make
    fi
}

# prep before processing command
function preprocessCMD {
    # Display usage options if no command is specified
    if (( $# == 0 )); then
        usageOptions
        cleanupAndExit 1
    fi

    # Don't prep on clusterinstall, command is run on remote nodes
    # we only need a portion of the script settings
    if [[ "$1" == "clusterinstall" ]]; then
        setStaticScriptSettings
    else
        initialChecks
        setPythonCmd
        setVerbosityLevel "$@"
    fi
}

# process the commands to be executed
# TODO: add help options for each command (with subsection usage info for that command)
# TODO: -servernat (short option w/ no value) deprecated in favor of -servernat <num> (short option w/ value)
function processCMD {
    # pre-processing / initial checks
    preprocessCMD "$@"

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
            # always add official repo's, set platform, and create init service
            RUN_COMMANDS+=(configureSystemRepos setCloudPlatform createInitService)
            shift

            local NEW_ROOT_DB_USER="" NEW_ROOT_DB_PASS="" NEW_ROOT_DB_NAME="" DB_CONN_URI="" TMP_ARG=""
            local SET_KAM_DB_USER="" SET_KAM_DB_PASS="" SET_KAM_DB_HOST="" SET_KAM_DB_PORT="" SET_KAM_DB_NAME=""

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
                        set -x
                        shift
                        ;;
                    -kam|--kamailio)
                        DEFAULT_SERVICES=0
                        RUN_COMMANDS+=(installSipsak installDnsmasq installMysql installKamailio)
                        shift
                        ;;
                    -dsip|--dsiprouter)
                        DEFAULT_SERVICES=0
                        DISPLAY_LOGIN_INFO=1
                        RUN_COMMANDS+=(installSipsak installMysql installDsiprouter)
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
                        RUN_COMMANDS+=(installSipsak installDnsmasq installMysql installKamailio installDsiprouter installRTPEngine)
                        shift
                        ;;
                    -servernat|--servernat=*)
                        OVERRIDE_SERVERNAT=1
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            if (( $(echo "$1" | cut -d '=' -f 2) > 0 )); then
                                export SERVERNAT=1
                            else
                                export SERVERNAT=0
                            fi
                            shift
                        else
                            export SERVERNAT=1
                            shift
                        fi
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
                            DB_CONN_URI=$(printf '%s' "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            DB_CONN_URI="$1"
                            shift
                        fi

                        SET_KAM_DB_USER=$(parseDBConnURI -user "$DB_CONN_URI")
                        SET_KAM_DB_PASS=$(parseDBConnURI -pass "$DB_CONN_URI")
                        SET_KAM_DB_HOST=$(parseDBConnURI -host "$DB_CONN_URI")
                        SET_KAM_DB_PORT=$(parseDBConnURI -port "$DB_CONN_URI")
                        SET_KAM_DB_NAME=$(parseDBConnURI -name "$DB_CONN_URI")

                        # sanity check (required params)
                        if [[ -n "${SET_KAM_DB_HOST}" ]]; then
                            export KAM_DB_HOST="${SET_KAM_DB_HOST}"
                        else
                            printerr 'Database Host is required and was not found in connection uri'
                            cleanupAndExit 1
                        fi
                        # set optional params (only if provided)
                        if [[ -n "${SET_KAM_DB_USER}" ]]; then
                            export KAM_DB_USER="${SET_KAM_DB_USER}"
                        fi
                        if [[ -n "${SET_KAM_DB_PASS}" ]]; then
                            export KAM_DB_PASS="${SET_KAM_DB_PASS}"
                        fi
                        if [[ -n "${SET_KAM_DB_PORT}" ]]; then
                            export KAM_DB_PORT="${SET_KAM_DB_PORT}"
                        fi
                        if [[ -n "${SET_KAM_DB_NAME}" ]]; then
                            export KAM_DB_NAME="${SET_KAM_DB_NAME}"
                        fi
                        ;;
                    -dsipcid|--dsip-clusterid=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            setConfigAttrib 'DSIP_CLUSTER_ID' "$(echo "$1" | cut -d '=' -f 2)" ${DSIP_CONFIG_FILE}
                            shift
                        else
                            shift
                            setConfigAttrib 'DSIP_CLUSTER_ID' "$1" ${DSIP_CONFIG_FILE}
                            shift
                        fi
                        ;;
                    -dbadmin|--database-admin=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            DB_CONN_URI=$(printf '%s' "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            DB_CONN_URI="$1"
                            shift
                        fi

                        NEW_ROOT_DB_USER=$(perl -pe 's%([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\1%' <<<"$DB_CONN_URI")
                        NEW_ROOT_DB_PASS=$(perl -pe 's%([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\2%' <<<"$DB_CONN_URI")
                        NEW_ROOT_DB_NAME=$(perl -pe 's%([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\3%' <<<"$DB_CONN_URI")

                        # sanity check (required params)
                        if [[ -n "${NEW_ROOT_DB_USER}" ]]; then
                            export ROOT_DB_USER="${NEW_ROOT_DB_USER}"
                        else
                            printerr 'Root Database User is required and was not found in connection uri'
                            cleanupAndExit 1
                        fi
                        # set optional params (only if provided)
                        if [[ -n "${NEW_ROOT_DB_PASS}" ]]; then
                            export ROOT_DB_PASS="${NEW_ROOT_DB_PASS}"
                        fi
                        if [[ -n "${NEW_ROOT_DB_NAME}" ]]; then
                            export ROOT_DB_NAME="${NEW_ROOT_DB_NAME}"
                        fi
                        ;;
                    -dsipcsync|--dsip-clustersync=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            setConfigAttrib 'DSIP_CLUSTER_SYNC' "$(echo "$1" | cut -d '=' -f 2)" ${DSIP_CONFIG_FILE}
                            shift
                        else
                            shift
                            setConfigAttrib 'DSIP_CLUSTER_SYNC' "$1" ${DSIP_CONFIG_FILE}
                            shift
                        fi
                        # change default for loading settings to db
                        setConfigAttrib 'LOAD_SETTINGS_FROM' "db" ${DSIP_CONFIG_FILE} -q
                        ;;
                    -dsipkey|--dsip-privkey=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_DSIP_PRIV_KEY="$(printf '%s' "$1" | cut -d '=' -f 2)"
                            shift
                        else
                            shift
                            SET_DSIP_PRIV_KEY="$1"
                            shift
                        fi
                        # sanity check
                        if (( $(printf '%s' "${SET_DSIP_PRIV_KEY}" | wc -c) != 32 )); then
                            printerr 'dSIPRouter private key must be 32 bytes'
                            cleanupAndExit 1
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
                    -homer)
                        shift
                        export KAM_HOMER_HOST=$(printf '%s' "$1" | cut -d ':' -f -1)
                        TMP_ARG="$(printf '%s' "$1" | cut -s -d ':' -f 2)"
                        [[ -n "$TMP" ]] && export KAM_HEP_PORT="$TMP"
                        shift
                        # sanity check
                        if [[ -z "$KAM_HOMER_HOST" ]]; then
                            printerr 'Missing required argument <homer_host> to option -homer'
                            cleanupAndExit 1
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
                DISPLAY_LOGIN_INFO=1
                RUN_COMMANDS+=(installSipsak installDnsmasq installMysql installKamailio installDsiprouter)
            fi

            # add displaying logo and login info to deferred commands
            DEFERRED_COMMANDS+=(displayLogo)
            if (( ${DISPLAY_LOGIN_INFO} == 1 )); then
                DEFERRED_COMMANDS+=(displayLoginInfo)
            fi

            # add commands deferred until all install funcs are done
            RUN_COMMANDS+=(${DEFERRED_COMMANDS[@]})
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
                        RUN_COMMANDS+=(uninstallKamailio uninstallDnsmasq)
                        shift
                        ;;
                    # only remove init and system config dir if all services will be removed (dependency for others)
                    # same goes for official repo configs, we only remove if all dsiprouter configs are being removed
                    -all|--all)
                        DEFAULT_SERVICES=0
                        RUN_COMMANDS+=(uninstallRTPEngine uninstallDsiprouter uninstallKamailio uninstallMysql uninstallDnsmasq uninstallSipsak removeInitService removeDsipSystemConfig)
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
                RUN_COMMANDS+=(uninstallDsiprouter uninstallKamailio uninstallMysql uninstallDnsmasq uninstallSipsak)
            fi

            # clean dev environment if configured
            if [[ -e /usr/local/bin/_merge-changelog ]]; then
                RUN_COMMANDS+=(cleanGitDevEnv)
            fi

            # display logo after install / uninstall commands
            RUN_COMMANDS+=(displayLogo)
            ;;
        clusterinstall)
            # install across remote cluster
            RUN_COMMANDS+=(clusterInstall)
            shift

            SSH_SYNC_NODES=()
            SSH_SYNC_ARGS=()

            # loop through args and grab nodes
            while (( $# > 0 )); do
                ARG="$1"
                case $ARG in
                    --)
                        shift
                        break
                        ;;
                    -debug)
                        export DEBUG=1
                        set -x
                        shift
                        ;;
                    -homer)
                        shift
                        export KAM_HOMER_HOST=$(printf '%s' "$1" | cut -d ':' -f -1)
                        TMP_ARG="$(printf '%s' "$1" | cut -s -d ':' -f 2)"
                        [[ -n "$TMP" ]] && export KAM_HEP_PORT="$TMP"
                        shift
                        # sanity check
                        if [[ -z "$KAM_HOMER_HOST" ]]; then
                            printerr 'Missing required argument <homer_host> to option -homer'
                            cleanupAndExit 1
                        fi
                        ;;
                    *)  # add to list of nodes
                        SSH_SYNC_NODES+=( "$ARG" )
                        shift
                        ;;
                esac
            done

            # scrap the --
            shift

            # loop through args and grab install options
            while (( $# > 0 )); do
                ARG="$1"
                case $ARG in
                    # we will transport securely instead
                    -dsipkey|--dsip-privkey=*)
                        if echo "$ARG" | grep -q '=' 2>/dev/null; then
                            SET_DSIP_PRIV_KEY="$(printf '%s' "$ARG" | cut -d '=' -f 2)"
                            shift
                        else
                            shift
                            SET_DSIP_PRIV_KEY="$ARG"
                            shift
                        fi
                        # sanity check
                        if (( $(printf '%s' "${SET_DSIP_PRIV_KEY}" | wc -c) != 32 )); then
                            printerr 'dSIPRouter private key must be 32 bytes'
                            cleanupAndExit 1
                        fi
                        ;;
                    *)  # add to list of args
                        SSH_SYNC_ARGS+=( "$ARG" )
                        shift
                        ;;
                esac
            done

            # sanity check
            if (( ${#SSH_SYNC_NODES[@]} < 1 )); then
                printerr "At least 2 nodes are required to setup cluster"
                usageOptions
                cleanupAndExit 1
            fi
            ;;
        start)
            # start installed services
            RUN_COMMANDS+=(start)
            shift

            # process debug option before parsing others
            if [[ "$1" == "-debug" ]]; then
                export DEBUG=1
                set -x
                shift
            fi

            # default to only starting dsip gui
            if (( $# == 0 )); then
                START_DSIPROUTER=1
            else
                START_DSIPROUTER=0
            fi

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -all|--all)
                        START_DSIPROUTER=1
                        START_KAMAILIO=1
                        START_RTPENGINE=1
                        shift
                        ;;
                    -dsip|--dsiprouter)
                        START_DSIPROUTER=1
                        shift
                        ;;
                    -kam|--kamailio)
                        START_KAMAILIO=1
                        shift
                        ;;
                    -rtp|--rtpengine)
                        START_RTPENGINE=1
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
            # stop installed services
            RUN_COMMANDS+=(stop)
            shift

            # process debug option before parsing others
            if [[ "$1" == "-debug" ]]; then
                export DEBUG=1
                set -x
                shift
            fi

            # default to only stopping dsip gui
            if (( $# == 0 )); then
                STOP_DSIPROUTER=1
            else
                STOP_DSIPROUTER=0
            fi

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -all|--all)
                        STOP_DSIPROUTER=1
                        STOP_KAMAILIO=1
                        STOP_RTPENGINE=1
                        shift
                        ;;
                    -dsip|--dsiprouter)
                        STOP_DSIPROUTER=1
                        shift
                        ;;
                    -kam|--kamailio)
                        STOP_KAMAILIO=1
                        shift
                        ;;
                    -rtp|--rtpengine)
                        STOP_RTPENGINE=1
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
            # restart installed services
            RUN_COMMANDS+=(stop start)
            shift

            # process debug option before parsing others
            if [[ "$1" == "-debug" ]]; then
                export DEBUG=1
                set -x
                shift
            fi

            # default to only restarting dsip gui
            if (( $# == 0 )); then
                STOP_DSIPROUTER=1
                START_DSIPROUTER=1
            else
                STOP_DSIPROUTER=0
                START_DSIPROUTER=0
            fi

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -all|--all)
                        STOP_DSIPROUTER=1
                        START_DSIPROUTER=1
                        STOP_KAMAILIO=1
                        START_KAMAILIO=1
                        STOP_RTPENGINE=1
                        START_RTPENGINE=1
                        shift
                        ;;
                    -dsip|--dsiprouter)
                        STOP_DSIPROUTER=1
                        START_DSIPROUTER=1
                        shift
                        ;;
                    -kam|--kamailio)
                        STOP_KAMAILIO=1
                        START_KAMAILIO=1
                        shift
                        ;;
                    -rtp|--rtpengine)
                        STOP_RTPENGINE=1
                        START_RTPENGINE=1
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
	    upgrade)
            # reconfigure kamailio configs
            RUN_COMMANDS+=(upgrade)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
                        set -x
                        shift
                        ;;
                    -dsipcid|--dsip-clusterid=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            setConfigAttrib 'DSIP_CLUSTER_ID' "$(echo "$1" | cut -d '=' -f 2)" ${DSIP_CONFIG_FILE}
                            shift
                        else
                            shift
                            setConfigAttrib 'DSIP_CLUSTER_ID' "$1" ${DSIP_CONFIG_FILE}
                            shift
                        fi
                        ;;
                    -rel|--release=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            export UPGRADE_RELEASE="$(echo "$1" | cut -d '=' -f 2)"
			                shift
                        else
                            shift
                            export UPGRADE_RELEASE="$1"
                            shift
			            fi

                        if [[ -z "$UPGRADE_RELEASE" ]]; then
                            printerr "Please specify a release tag (ie v0.64)"
                            usageOptions
                            cleanupAndExit 1
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
        # TODO: add commands for configuring rtpengine using same setup
        #       i.e.) configurertp should be externally accessible and documented
        configurekam)
            # reconfigure kamailio configs
            RUN_COMMANDS+=(generateKamailioConfig updateKamailioConfig updateKamailioStartup)
            shift

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
                        set -x
                        shift
                        ;;
                    -servernat|--servernat=*)
                        OVERRIDE_SERVERNAT=1
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            if (( $(echo "$1" | cut -d '=' -f 2) > 0 )); then
                                export SERVERNAT=1
                            else
                                export SERVERNAT=0
                            fi
                            shift
                        else
                            export SERVERNAT=1
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
        renewsslcert)
            # reconfigure ssl configs
            RUN_COMMANDS+=(renewSSLCert)
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
	    configuresslcert)
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
                    -f|--force)
                        rm -f $DSIP_CERTS_DIR/dsiprouter-cert.pem
                        rm -f $DSIP_CERTS_DIR/dsiprouter-key.pem
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
        # TODO: deprecated in favor of using updatekamconfig command
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
        # TODO: deprecated in favor of using updatekamconfig command
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
            # reset secure credentials
            RUN_COMMANDS+=(setCloudPlatform resetPassword displayLoginInfo)
            shift

            # process debug option before parsing others
            if [[ "$1" == "-debug" ]]; then
                export DEBUG=1
                set -x
                shift
            fi

            # default to only resetting dsip gui password
            if (( $# == 0 )); then
                RESET_DSIP_GUI_PASS=1
            else
                RESET_DSIP_GUI_PASS=0
            fi

            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -all|--all)
                        RESET_DSIP_GUI_PASS=1
                        RESET_DSIP_API_TOKEN=1
                        RESET_KAM_DB_PASS=1
                        RESET_DSIP_IPC_TOKEN=1
                        shift
                        ;;
                    -dc|--dsip-creds)
                        RESET_DSIP_GUI_PASS=1
                        shift
                        ;;
                    -ac|--api-creds)
                        RESET_DSIP_API_TOKEN=1
                        shift
                        ;;
                    -kc|--kam-creds)
                        RESET_KAM_DB_PASS=1
                        shift
                        ;;
                    -ic|--ipc-creds)
                        RESET_DSIP_IPC_TOKEN=1
                        shift
                        ;;
                    -fid|--force-instance-id)
                        RESET_FORCE_INSTANCE_ID=1
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
                    -dc|--dsip-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            CREDS_URI=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            CREDS_URI="$1"
                            shift
                        fi

                        SET_DSIP_GUI_USER=$(perl -pe 's%([^:/\t\r\n\v\f]+)?(?::([^/\t\r\n\v\f]*))?%\1%' <<<"$CREDS_URI")
                        SET_DSIP_GUI_PASS=$(perl -pe 's%([^:/\t\r\n\v\f]+)?(?::([^/\t\r\n\v\f]*))?%\2%' <<<"$CREDS_URI")
                        ;;
                    -ac|--api-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_DSIP_API_TOKEN=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_DSIP_API_TOKEN="$1"
                            shift
                        fi
                        ;;
                    -kc|--kam-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            DB_CONN_URI=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            DB_CONN_URI="$1"
                            shift
                        fi

                        # sanity check
                        if [[ -z "${DB_CONN_URI}" ]]; then
                            printerr "Credentials must be given for option $OPT"
                            cleanupAndExit 1
                        fi

                        SET_KAM_DB_USER=$(parseDBConnURI -user "$DB_CONN_URI")
                        SET_KAM_DB_PASS=$(parseDBConnURI -pass "$DB_CONN_URI")
                        SET_KAM_DB_HOST=$(parseDBConnURI -host "$DB_CONN_URI")
                        SET_KAM_DB_PORT=$(parseDBConnURI -port "$DB_CONN_URI")
                        SET_KAM_DB_NAME=$(parseDBConnURI -name "$DB_CONN_URI")
                        ;;
                    -mc|--mail-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            CREDS_URI=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            CREDS_URI="$1"
                            shift
                        fi

                        SET_DSIP_MAIL_USER=$(perl -pe 's%([^:/\t\r\n\v\f]+)?(?::([^/\t\r\n\v\f]*))?%\1%' <<<"$CREDS_URI")
                        SET_DSIP_MAIL_PASS=$(perl -pe 's%([^:/\t\r\n\v\f]+)?(?::([^/\t\r\n\v\f]*))?%\2%' <<<"$CREDS_URI")
                        ;;
                    -ic|--ipc-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_DSIP_IPC_TOKEN=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_DSIP_IPC_TOKEN="$1"
                            shift
                        fi
                        ;;
                    -dac|--database-admin-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            DB_CONN_URI=$(printf '%s' "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            DB_CONN_URI="$1"
                            shift
                        fi

                        # sanity check
                        if [[ -z "${DB_CONN_URI}" ]]; then
                            printerr "Credentials must be given for option $OPT"
                            cleanupAndExit 1
                        fi

                        SET_ROOT_DB_USER=$(perl -pe 's%([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\1%' <<<"$DB_CONN_URI")
                        SET_ROOT_DB_PASS=$(perl -pe 's%([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\2%' <<<"$DB_CONN_URI")
                        SET_ROOT_DB_NAME=$(perl -pe 's%([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\3%' <<<"$DB_CONN_URI")
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
        # TODO: deprecated in favor of using configurekam command
        generatekamconfig)
            # generate kamailio configs from templates
            RUN_COMMANDS+=(generateKamailioConfig)
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
        # TODO: deprecated as an EXTERNAL command, should only be used by internal scripts
        #       users should use configurekam command to configure kamailio instead
        updatekamconfig)
            # update kamailio config
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
                    -servernat|--servernat=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            if (( $(echo "$1" | cut -d '=' -f 2) > 0 )); then
                                export SERVERNAT=1
                            else
                                export SERVERNAT=0
                            fi
                            shift
                        else
                            export SERVERNAT=1
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
        # TODO: deprecated as an EXTERNAL command, should only be used by internal scripts
        #       users should use configurertp command to configure rtpengine instead
        # TODO: create configurertp command for user configurable settings
        updatertpconfig)
            # update rtpengine config
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
                    -servernat|--servernat=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            if (( $(echo "$1" | cut -d '=' -f 2) > 0 )); then
                                export SERVERNAT=1
                            else
                                export SERVERNAT=0
                            fi
                            shift
                        else
                            export SERVERNAT=1
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
        # TODO: deprecated as an EXTERNAL command, should only be used by internal scripts
        #       users should not need to configure dnsmasq themselves
        updatednsconfig)
            # update dnsmasq config
            RUN_COMMANDS+=(updateDnsConfig)
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
        # internal command, generates CA dir from CA bundle file
        updatecacertsdir)
            # update cacerts config
            RUN_COMMANDS+=(updateCACertsDir)
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
        updatedynamicaddrs)
            # update resolved DNS addresses
            RUN_COMMANDS+=(updateDynamicAddresses)
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
        version|-v|--version)
            printf '%s\n' "$(getConfigAttrib 'VERSION' ${DSIP_CONFIG_FILE})"
            cleanupAndExit 1
            ;;
        help|-h|--help)
            usageOptions
            cleanupAndExit 1
            ;;
        *)
            printerr "Invalid command [$ARG]"
            usageOptions
            cleanupAndExit 1
            ;;
    esac

    # remove dupliaate commands, while preserving order
    # shellcheck disable=SC2207
    RUN_COMMANDS=( $(printf '%s\n' "${RUN_COMMANDS[@]}" | awk '!x[$0]++') )

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
    for RUN_COMMAND in "${RUN_COMMANDS[@]}"; do
        $RUN_COMMAND
    done
    cleanupAndExit 0
} #end of processCMD

processCMD "$@"
