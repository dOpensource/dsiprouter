#!/usr/bin/env bash
#
#=============== dSIPRouter Management Script ==============#
#
# install, configure, and manage dsiprouter
#
#========================== NOTES ==========================#
#
# Supported OS:
# - Debian 12 (bullseye)    - STABLE
# - Debian 11 (bullseye)    - STABLE
# - Debian 10 (buster)      - STABLE
# - Debian 9 (stretch)      - DEPRECATED
# - CentOS 9 (stream)       - STABLE
# - CentOS 8 (stream)       - STABLE
# - CentOS 7                - DEPRECATED
# - RedHat Linux 8          - ALPHA
# - Alma Linux 8            - ALPHA
# - Rocky Linux 8           - ALPHA
# - Amazon Linux 2          - STABLE
# - Ubuntu 22.04 (jammy)    - ALPHA
# - Ubuntu 20.04 (focal)    - DEPRECATED
#
# Conventions:
# - In general exported variables & functions are used in externally called scripts / programs
#
# TODO:
# - allow user to move carriers freely between carrier groups
# - allow a carrier to be in more than one carrier group
# - add ncurses selection menu for enabling / disabling modules
# - naming convention for system vs dsip config files is very confusing (make more explicit)
# - cleanup dependency installs/checks, many of these could be condensed
# - allow overwriting caller id per gwgroup / gw (setup in gui & kamcfg)
# - update tests with new mysql command wrapper functions
# - update HA scripts with new mysql command wrapper functions
# - add documentation generation to supported CLI commands
# - move python install into it's own script to allow fine grain control of version/compilation if needed
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


# set project dir (where src files are located)
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(dirname $(readlink -f "$0"))}
# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh


# settings used by script that are user configurable
function setStaticScriptSettings() {
    # to be clear, we define constants or variables with defaults here
    # generally these configuration settings effect how this script or the platform operate
    # do not change these settings without knowing exactly how it effects normal operation
    FLT_CARRIER=8
    FLT_PBX=9
    FLT_MSTEAMS=17
    FLT_OUTBOUND=8000
    FLT_INBOUND=9000
    FLT_LCR_MIN=10000
    FLT_FWD_MIN=20000
    WITH_LCR=1
    export DEBUG=0
    export TEAMS_ENABLED=1
    DSIP_MIN_PYTHON_VER='3.8'
    export PYTHON_VENV="${DSIP_PROJECT_DIR}/venv"
    export PYTHON_CMD="${PYTHON_VENV}/bin/python"
    export PROJECT_KAMAILIO_CONFIG_DIR="${DSIP_PROJECT_DIR}/kamailio/configs"
    export PROJECT_DSIP_DEFAULTS_DIR="${DSIP_PROJECT_DIR}/kamailio/defaults"
    export DSIP_SYSTEM_CONFIG_DIR="/etc/dsiprouter"
    DSIP_PRIV_KEY="${DSIP_SYSTEM_CONFIG_DIR}/privkey"
    export DSIP_KAMAILIO_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/kamailio/kamailio.cfg"
    export DSIP_KAMAILIO_TLS_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/kamailio/tls.cfg"
    export DSIP_CONFIG_FILE="${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py"
    export DSIP_RUN_DIR="/run/dsiprouter"
    export DSIP_LIB_DIR="/var/lib/dsiprouter"
    export DSIP_CERTS_DIR="${DSIP_SYSTEM_CONFIG_DIR}/certs"
    DSIP_DOCS_DIR="${DSIP_PROJECT_DIR}/docs/build/html"
    export SYSTEM_KAMAILIO_CONFIG_DIR="/etc/kamailio"
    export SYSTEM_KAMAILIO_CONFIG_FILE="${SYSTEM_KAMAILIO_CONFIG_DIR}/kamailio.cfg" # will be symlinked
    export SYSTEM_KAMAILIO_TLS_CONFIG_FILE="${SYSTEM_KAMAILIO_CONFIG_DIR}/tls.cfg" # will be symlinked
    export SYSTEM_RTPENGINE_CONFIG_DIR="/etc/rtpengine"
    export SYSTEM_RTPENGINE_CONFIG_FILE="${SYSTEM_RTPENGINE_CONFIG_DIR}/rtpengine.conf"
    export PATH_UPDATE_FILE="/etc/profile.d/dsip_paths.sh" # updates paths required
    GIT_UPDATE_FILE="/etc/profile.d/dsip_git.sh" # extends git command
    DSIP_SUDOERS_FILE="/etc/sudoers.d/99-dsiprouter"
    export SRC_DIR="/usr/local/src"
    export BACKUPS_DIR="/var/backups/dsiprouter"
    IMAGE_BUILD=${IMAGE_BUILD:-0}
    APT_OFFICIAL_SOURCES="/etc/apt/sources.list"
    APT_OFFICIAL_PREFS="/etc/apt/preferences"
    APT_OFFICIAL_SOURCES_BAK="${BACKUPS_DIR}/original-sources.list"
    APT_OFFICIAL_PREFS_BAK="${BACKUPS_DIR}/original-sources.pref"
    APT_DSIP_CONFIG="/etc/apt/apt.conf.d/99dsiprouter"
    YUM_OFFICIAL_REPOS="/etc/yum.repos.d/official-releases.repo"

    # Force the installation of an Kamailio version by uncommenting
    # can also be set as an environment variable
    #KAM_VERSION=57 # Version 5.7.x

    # Force the installation of an RTPEngine version by uncommenting
    # can also be set as an environment variable
    #RTPENGINE_VER="mr11.5.1.11"

    # Network configuration values
    export DSIP_UNIX_SOCK='/run/dsiprouter/dsiprouter.sock'
    export DSIP_PORT=5000
    export RTP_PORT_MIN=10000
    export RTP_PORT_MAX=20000
    export KAM_SIP_PORT=5060
    export KAM_SIPS_PORT=5061
    export KAM_DMQ_PORT=5090
    export KAM_WSS_PORT=4443
    export HOMER_HEP_PORT=9060

    export DSIP_PROTO='https'
    export DSIP_API_PROTO='https'
    export DSIP_SSL_KEY="${DSIP_CERTS_DIR}/dsiprouter-key.pem"
    export DSIP_SSL_CERT="${DSIP_CERTS_DIR}/dsiprouter-cert.pem"
    export DSIP_SSL_CA="${DSIP_CERTS_DIR}/ca-list.pem"
}

# settings used by script that are generated by the script
function setDynamicScriptSettings() {
    # TEMP: parse these options ahead of time until we can move arg parsing ahead of this logic
    # [note to self] this will require preempting undefined functions and/or some porting to bash-native versions of parsing logic
    if [[ "$1" == "install" ]]; then
        shift
        local OPT
        for OPT in "$@"; do
            case $OPT in
                -dmz|--dmz=*)
                    NETWORK_MODE=2
                    if echo "$1" | grep -q '=' 2>/dev/null; then
                        TMP=$(echo "$1" | cut -d '=' -f 2)
                        shift
                    else
                        shift
                        TMP="$1"
                        shift
                    fi
                    PUBLIC_IFACE=$(echo "$TMP" | cut -d ',' -f 1)
                    PRIVATE_IFACE=$(echo "$TMP" | cut -d ',' -f 2)
                    ;;
                -netm|--network-mode=*)
                    if echo "$1" | grep -q '=' 2>/dev/null; then
                        NETWORK_MODE=$(echo "$1" | cut -d '=' -f 2)
                        shift
                    else
                        shift
                        NETWORK_MODE="$1"
                        shift
                    fi
                    ;;
            esac
        done
    fi

    # network settings determined by mode
    NETWORK_MODE=${NETWORK_MODE:-$(getConfigAttrib 'NETWORK_MODE' ${DSIP_CONFIG_FILE})}
    NETWORK_MODE=${NETWORK_MODE:-0}

    # TODO: ipv6 intentionally disabled here
    export IPV6_ENABLED=0

    # grab the network settings dynamically
    if (( $NETWORK_MODE == 0 )); then
        export INTERNAL_IP_ADDR=$(getInternalIP -4)
        export INTERNAL_IP_NET=$(getInternalCIDR -4)
        export INTERNAL_IP6_ADDR=$(getInternalIP -6)
        export INTERNAL_IP_NET6=$(getInternalCIDR -6)

        # if external ip address is not found then this box is on an internal subnet
        EXTERNAL_IP_ADDR=$(getExternalIP -4)
        export EXTERNAL_IP_ADDR=${EXTERNAL_IP_ADDR:-$INTERNAL_IP_ADDR}
        EXTERNAL_IP6_ADDR=$(getExternalIP -6)
        export EXTERNAL_IP6_ADDR=${EXTERNAL_IP6_ADDR:-$INTERNAL_IP6_ADDR}

        # determine whether ipv6 is enabled
        # /proc/net/if_inet6 tells us if the kernel has ipv6 enabled
#		if [[ -f /proc/net/if_inet6 ]] && [[ -n "$INTERNAL_IP6_ADDR" ]]; then
#			# sanity check, is the ipv6 address routable?
#			# if not we can not use this address (interface is not configured properly)
#			if ! checkConn "$INTERNAL_IP6_ADDR"; then
#				printerr "IPV6 enabled but address [$INTERNAL_IP6_ADDR] is not routable"
#				exit 1
#			fi
#			export IPV6_ENABLED=1
#		else
#			export IPV6_ENABLED=0
#		fi

        # the address we put in the contact when registering to carriers via uac module
        # by default it is set to the external IP of this server
        export UAC_REG_ADDR="$EXTERNAL_IP_ADDR"

        export INTERNAL_FQDN=$(getInternalFQDN)
        export EXTERNAL_FQDN=$(getExternalFQDN)
        if [[ -z "$EXTERNAL_FQDN" ]] || ! checkConn "$EXTERNAL_FQDN"; then
            # if external fqdn is not routable set it to the internal fqdn instead
            export EXTERNAL_FQDN="$INTERNAL_FQDN"
        fi
	
	# set the external fqdn to the internal fqdn if the hostname contain vultrusercontent
	# Kamailio doesn't like hostname names with dots and LetsEncrypt can't create certs for that domain
	grep vultrusercontent <<< "$EXTERNAL_FQDN" >/dev/null
	if (( $? == 0 ));then
            export EXTERNAL_FQDN="$INTERNAL_FQDN"
	
	fi

    # network settings pulled from env variables or from config file
    elif (( $NETWORK_MODE == 1 )); then
        export INTERNAL_IP_ADDR=${INTERNAL_IP_ADDR:-$(getConfigAttrib 'INTERNAL_IP_ADDR' ${DSIP_CONFIG_FILE})}
        export INTERNAL_IP_NET=${INTERNAL_IP_NET:-$(getConfigAttrib 'INTERNAL_IP_NET' ${DSIP_CONFIG_FILE})}
        export INTERNAL_IP6_ADDR=${INTERNAL_IP6_ADDR:-$(getConfigAttrib 'INTERNAL_IP6_ADDR' ${DSIP_CONFIG_FILE})}
        export INTERNAL_IP_NET6=${INTERNAL_IP_NET6:-$(getConfigAttrib 'INTERNAL_IP_NET6' ${DSIP_CONFIG_FILE})}

        export EXTERNAL_IP_ADDR=${EXTERNAL_IP_ADDR:-$(getConfigAttrib 'EXTERNAL_IP_ADDR' ${DSIP_CONFIG_FILE})}
        export EXTERNAL_IP6_ADDR=${EXTERNAL_IP6_ADDR:-$(getConfigAttrib 'EXTERNAL_IP6_ADDR' ${DSIP_CONFIG_FILE})}

#		if [[ -n "$IPV6_ENABLED" ]]; then
#			export IPV6_ENABLED
#		else
#			[[ "$(getConfigAttrib 'IPV6_ENABLED' ${DSIP_CONFIG_FILE})" == "True" ]] &&
#				export IPV6_ENABLED=1 ||
#				export IPV6_ENABLED=0
#		fi

        export INTERNAL_FQDN=${INTERNAL_FQDN:-$(getConfigAttrib 'INTERNAL_FQDN' ${DSIP_CONFIG_FILE})}
        export EXTERNAL_FQDN=${EXTERNAL_FQDN:-$(getConfigAttrib 'EXTERNAL_FQDN' ${DSIP_CONFIG_FILE})}
        export UAC_REG_ADDR=${UAC_REG_ADDR:-$(getConfigAttrib 'UAC_REG_ADDR' ${DSIP_CONFIG_FILE})}
    # network settings resolved dynamically except IP/subnets (they are resolved by interfaces from CLI args or from the config)
    elif (( $NETWORK_MODE == 2 )); then
        PUBLIC_IFACE=${PUBLIC_IFACE:-$(getConfigAttrib 'PUBLIC_IFACE' ${DSIP_CONFIG_FILE})}
        PRIVATE_IFACE=${PRIVATE_IFACE:-$(getConfigAttrib 'PRIVATE_IFACE' ${DSIP_CONFIG_FILE})}

        export INTERNAL_IP_ADDR=$(getIP -4 "$PRIVATE_IFACE")
        export INTERNAL_IP_NET=$(getInternalCIDR -4 "$PRIVATE_IFACE")
        export INTERNAL_IP6_ADDR=$(getIP -6 "$PRIVATE_IFACE")
        export INTERNAL_IP_NET6=$(getInternalCIDR -6 "$PRIVATE_IFACE")

        EXTERNAL_IP_ADDR=$(getIP -4 "$PUBLIC_IFACE")
        export EXTERNAL_IP_ADDR=${EXTERNAL_IP_ADDR:-$INTERNAL_IP_ADDR}
        EXTERNAL_IP6_ADDR=$(getIP -6 "$PUBLIC_IFACE")
        export EXTERNAL_IP6_ADDR=${EXTERNAL_IP6_ADDR:-$INTERNAL_IP6_ADDR}

#		if [[ -f /proc/net/if_inet6 ]] && [[ -n "$INTERNAL_IP6_ADDR" ]]; then
#			# sanity check, is the ipv6 address routable?
#			# if not we can not use this address (interface is not configured properly)
#			if ! checkConn "$INTERNAL_IP6_ADDR"; then
#				printerr "IPV6 enabled but address [$INTERNAL_IP6_ADDR] is not routable"
#				exit 1
#			fi
#			export IPV6_ENABLED=1
#		else
#			export IPV6_ENABLED=0
#		fi

        # the address we put in the contact when registering to carriers via uac module
        # by default it is set to the external IP of this server
        export UAC_REG_ADDR="$EXTERNAL_IP_ADDR"

        export INTERNAL_FQDN=$(getInternalFQDN)
        export EXTERNAL_FQDN=$(getExternalFQDN)
        if [[ -z "$EXTERNAL_FQDN" ]] || ! checkConn "$EXTERNAL_FQDN"; then
            # if external fqdn is not routable set it to the internal fqdn instead
            export EXTERNAL_FQDN="$INTERNAL_FQDN"
        fi
    else
        printerr 'Network Mode is invalid, can not proceed any further'
        exit 1
    fi

    # if the public ip address is not the same as the internal address then enable serverside NAT
    if [[ "$EXTERNAL_IP_ADDR" != "$INTERNAL_IP_ADDR" ]]; then
        export SERVERNAT=1
    else
        export SERVERNAT=0
    fi
    # same as above but for ipv6, note that NAT is rarely used on ipv6 networks
    if (( ${IPV6_ENABLED} == 1 )) && [[ "$EXTERNAL_IP6_ADDR" != "$INTERNAL_IP6_ADDR" ]]; then
        export SERVERNAT6=1
    else
        export SERVERNAT6=0
    fi

    # grab root db settings from env or settings file
    export ROOT_DB_USER=${ROOT_DB_USER:-$(getConfigAttrib 'ROOT_DB_USER' ${DSIP_CONFIG_FILE})}
    export ROOT_DB_PASS=${ROOT_DB_PASS:-$(decryptConfigAttrib 'ROOT_DB_PASS' ${DSIP_CONFIG_FILE})}
    export ROOT_DB_HOST=${ROOT_DB_HOST:-$(getConfigAttrib 'ROOT_DB_HOST' ${DSIP_CONFIG_FILE})}
    export ROOT_DB_PORT=${ROOT_DB_PORT:-$(getConfigAttrib 'ROOT_DB_PORT' ${DSIP_CONFIG_FILE})}
    export ROOT_DB_NAME=${ROOT_DB_NAME:-$(getConfigAttrib 'ROOT_DB_NAME' ${DSIP_CONFIG_FILE})}

    # grab kam db settings from env or settings file
    export KAM_DB_HOST=${KAM_DB_HOST:-$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})}
    export KAM_DB_TYPE=${KAM_DB_TYPE:-$(getConfigAttrib 'KAM_DB_TYPE' ${DSIP_CONFIG_FILE})}
    export KAM_DB_PORT=${KAM_DB_PORT:-$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})}
    export KAM_DB_NAME=${KAM_DB_NAME:-$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})}
    export KAM_DB_USER=${KAM_DB_USER:-$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})}
    export KAM_DB_PASS=${KAM_DB_PASS:-$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE} 2>/dev/null)}

    # set the email used to obtain LetsEncrypt Certificates
    export DSIP_SSL_EMAIL="admin@${EXTERNAL_FQDN}"

    export DSIP_ID=$(getConfigAttrib 'DSIP_ID' ${DSIP_CONFIG_FILE})
    if [[ "$DSIP_ID" == "None" || -z "$DSIP_ID" ]]; then
        export DSIP_ID=$(cat /etc/machine-id | hashCreds)
    fi

    export HOMER_ID=$(getConfigAttrib 'HOMER_ID' ${DSIP_CONFIG_FILE})
    if [[ "$HOMER_ID" == "None" ]] || [[ -z "$HOMER_ID" ]]; then
        export HOMER_ID=$(cat /etc/machine-id | hashCreds -l 4 | dd if=/dev/stdin of=/dev/stdout bs=1 count=8 2>/dev/null | hextoint)
    fi

    # find the repo where we are getting upgrades from
    # note that remote is assumed to be "origin"
    # note that the VCS is assumed to be git
    GIT_REPO_URL=$(getConfigAttrib 'GIT_REPO_URL' ${DSIP_CONFIG_FILE})
    GIT_RELEASE_URL=$(getConfigAttrib 'GIT_RELEASE_URL' ${DSIP_CONFIG_FILE})

    export CURR_BACKUP_DIR=${CURR_BACKUP_DIR:-"${BACKUPS_DIR}/$(date '+%s')"}
}

# Check if we are on a VPS Cloud Instance
function setCloudPlatform() {
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

function displayLogo() {
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

# check if running as root
function validateRootPriv() {
    if (( $(id -u 2>/dev/null) != 0 )); then
        printerr "$0 must be run as root user"
        exit 1
    fi
}

# Validate OS and export OS specific config variables
function validateOSInfo() {
    export DISTRO=$(getDistroName)
    export DISTRO_VER=$(getDistroVer)
    export DISTRO_MAJOR_VER=$(cut -d '.' -f 1 <<<"$DISTRO_VER")
    export DISTRO_MINOR_VER=$(cut -s -d '.' -f 2 <<<"$DISTRO_VER")

    if [[ "$DISTRO" == "debian" ]]; then
        case "$DISTRO_VER" in
            12)
                KAM_VERSION=${KAM_VERSION:-57}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr11.5.1.11"}
                export APT_STRETCH_PRIORITY=50 APT_BUSTER_PRIORITY=50 APT_BULLSEYE_PRIORITY=500 APT_BOOKWORM_PRIORITY=990
                ;;
            11)
                KAM_VERSION=${KAM_VERSION:-57}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr11.5.1.11"}
                export APT_STRETCH_PRIORITY=50 APT_BUSTER_PRIORITY=50 APT_BULLSEYE_PRIORITY=990 APT_BOOKWORM_PRIORITY=500
                ;;
            10)
                KAM_VERSION=${KAM_VERSION:-57}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr11.5.1.11"}
                export APT_STRETCH_PRIORITY=50 APT_BUSTER_PRIORITY=990 APT_BULLSEYE_PRIORITY=500 APT_BOOKWORM_PRIORITY=100
                ;;
            9)
                printerr "Your Operating System Version is DEPRECATED. To ask for support open an issue https://github.com/dOpensource/dsiprouter/"
                KAM_VERSION=${KAM_VERSION:-55}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr9.5.5.1"}
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                exit 1
                ;;
        esac
    elif [[ "$DISTRO" == "centos" ]]; then
        case "$DISTRO_VER" in
            8|9)
                KAM_VERSION=${KAM_VERSION:-57}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr11.5.1.11"}
                ;;
            7)
                printwarn "Your Operating System Version is DEPRECATED. To ask for support open an issue https://github.com/dOpensource/dsiprouter/"
                KAM_VERSION=${KAM_VERSION:-55}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr9.5.5.1"}
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                exit 1
            ;;
        esac
    elif [[ "$DISTRO" == "amzn" ]]; then
        case "$DISTRO_VER" in
            2)
                KAM_VERSION=${KAM_VERSION:-57}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr9.5.5.1"}
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                exit 1
                ;;
        esac
    elif [[ "$DISTRO" == "ubuntu" ]]; then
        case "$DISTRO_VER" in
            22.04)
                printwarn "Your operating System Version is in ALPHA support. Some features may not work yet. Use at your own risk."
                KAM_VERSION=${KAM_VERSION:-57}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr11.5.1.11"}
                export APT_FOCAL_PRIORITY=100 APT_JAMMY_PRIORITY=990
                ;;
            20.04)
                printwarn "Your Operating System Version is DEPRECATED. To ask for support open an issue https://github.com/dOpensource/dsiprouter/"
                KAM_VERSION=${KAM_VERSION:-57}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr11.5.1.11"}
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                exit 1
                ;;
        esac
    elif [[ "$DISTRO" =~ rhel|almalinux|rocky ]]; then
        case "$DISTRO_MAJOR_VER" in
            8)
                printwarn "Your operating System Version is in ALPHA support. Some features may not work yet. Use at your own risk."
                KAM_VERSION=${KAM_VERSION:-57}
                RTPENGINE_VER=${RTPENGINE_VER:-"mr11.5.1.11"}
                ;;
            *)
                printerr "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                exit 1
                ;;
        esac
    else
        printerr "Your Operating System is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
        exit 1
    fi

    # export it for external scripts
    export KAM_VERSION
    export RTPENGINE_VER
}

# run prior to any cmd being processed
function initialChecks() {
    validateRootPriv
    validateOSInfo
    setStaticScriptSettings
    setupScriptRequiredFiles
    installScriptRequirements
    setDynamicScriptSettings
}

# exported because its used throughout called scripts as well
function reconfigureMysqlSystemdService() {
    local KAMDB_HOST="${SET_KAM_DB_HOST:-$KAM_DB_HOST}"
    local KAMDB_LOCATION="$(cat ${DSIP_SYSTEM_CONFIG_DIR}/.mysqldblocation 2>/dev/null)"

    case "$KAMDB_HOST" in
        # in this case mysql server is running on this node
        "localhost"|"127.0.0.1"|"::1"|"${INTERNAL_IP_ADDR}"|"${EXTERNAL_IP_ADDR}"|"${INTERNAL_IP6_ADDR}"|"${EXTERNAL_IP6_ADDR}"|"$(hostname 2>/dev/null)"|"$(hostname -f 2>/dev/null)")
            # if previously was remote and now local re-generate service files
            if [[ "${KAMDB_LOCATION}" == "remote" ]]; then
                systemctl disable mariadb
                rm -f /etc/systemd/system/mariadb.service 2>/dev/null
            fi

            printf '%s' 'local' > ${DSIP_SYSTEM_CONFIG_DIR}/.mysqldblocation
            ;;
        # in this case mysql server is running on a remote node
        *)
            # if previously was local and now remote or inital run and is remote replace service files w/ dummy
            if [[ "${KAMDB_LOCATION}" == "local" ]] || [[ "${KAMDB_LOCATION}" == "" ]]; then
                systemctl disable mariadb
                cp -f ${DSIP_PROJECT_DIR}/mysql/systemd/dummy.service /etc/systemd/system/mariadb.service
                chmod 644 /etc/systemd/system/mariadb.service
            fi

            printf '%s' 'remote' > ${DSIP_SYSTEM_CONFIG_DIR}/.mysqldblocation
            ;;
    esac

    systemctl daemon-reload
    systemctl enable mariadb
}
export -f reconfigureMysqlSystemdService

function generateDsiprouterConfig() {
    mkdir -p ${BACKUPS_DIR}/gui/
    cp -f ${DSIP_SYSTEM_CONFIG_DIR}/gui/*.py ${BACKUPS_DIR}/gui/ 2>/dev/null
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/gui/*.py 2>/dev/null
    cp -f ${DSIP_PROJECT_DIR}/gui/settings.py ${DSIP_CONFIG_FILE}
}

# TODO: update DB settings here as well, currently they are updated in dsiprouter.py
#       ^^ this is required to support loading settings from DB, i.e. LOAD_SETTINGS_FROM='db'
function updateDsiprouterConfig() {
    local NETWORK_MODE=${NETWORK_MODE:-$(getConfigAttrib 'NETWORK_MODE' ${DSIP_CONFIG_FILE})}

    # the following variables are always updated
    setConfigAttrib 'KAM_KAMCMD_PATH' "$(type -p kamcmd)" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'KAM_CFG_PATH' "$SYSTEM_KAMAILIO_CONFIG_FILE" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'KAM_TLSCFG_PATH' "$SYSTEM_KAMAILIO_TLS_CONFIG_FILE" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'RTP_CFG_PATH' "$SYSTEM_RTPENGINE_CONFIG_FILE" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'FLT_CARRIER' "$FLT_CARRIER" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_PBX' "$FLT_PBX" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_MSTEAMS' "$FLT_MSTEAMS" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_OUTBOUND' "$FLT_OUTBOUND" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_INBOUND' "$FLT_INBOUND" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_LCR_MIN' "$FLT_LCR_MIN" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'FLT_FWD_MIN' "$FLT_FWD_MIN" ${DSIP_CONFIG_FILE}
    setConfigAttrib 'DSIP_PROJECT_DIR' "$DSIP_PROJECT_DIR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'DSIP_DOCS_DIR' "$DSIP_DOCS_DIR" ${DSIP_CONFIG_FILE} -q

    # the following variables are only updated when set
    [[ -n "$DSIP_ID" ]] && setConfigAttrib 'DSIP_ID' "$DSIP_ID" ${DSIP_CONFIG_FILE} -qb
    [[ -n "$DSIP_CLUSTER_ID" ]] && setConfigAttrib 'DSIP_CLUSTER_ID' "$DSIP_CLUSTER_ID" ${DSIP_CONFIG_FILE}
    if [[ -n "$DSIP_CLUSTER_SYNC" ]]; then
        if (( $DSIP_CLUSTER_SYNC == 1 )); then
            setConfigAttrib 'DSIP_CLUSTER_SYNC' 'True' ${DSIP_CONFIG_FILE}
        else
            setConfigAttrib 'DSIP_CLUSTER_SYNC' 'False' ${DSIP_CONFIG_FILE}
        fi
    fi
    [[ -n "$DSIP_PROTO" ]] && setConfigAttrib 'DSIP_PROTO' "$DSIP_PROTO" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_PORT" ]] && setConfigAttrib 'DSIP_PORT' "$DSIP_PORT" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_API_PROTO" ]] && setConfigAttrib 'DSIP_API_PROTO' "$DSIP_API_PROTO" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_API_PORT" ]] && setConfigAttrib 'DSIP_API_PORT' "$DSIP_API_PORT" ${DSIP_CONFIG_FILE}
    [[ -n "$DSIP_PRIV_KEY" ]] && setConfigAttrib 'DSIP_PRIV_KEY' "$DSIP_PRIV_KEY" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_PID_FILE" ]] && setConfigAttrib 'DSIP_PID_FILE' "$DSIP_PID_FILE" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_UNIX_SOCK" ]] && setConfigAttrib 'DSIP_UNIX_SOCK' "$DSIP_UNIX_SOCK" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_IPC_SOCK" ]] && setConfigAttrib 'DSIP_IPC_SOCK' "$DSIP_IPC_SOCK" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_LOG_LEVEL" ]] && setConfigAttrib 'DSIP_LOG_LEVEL' "$DSIP_LOG_LEVEL" ${DSIP_CONFIG_FILE}
    [[ -n "$DSIP_LOG_FACILITY" ]] && setConfigAttrib 'DSIP_LOG_FACILITY' "$DSIP_LOG_FACILITY" ${DSIP_CONFIG_FILE}
    [[ -n "$DSIP_SSL_KEY" ]] && setConfigAttrib 'DSIP_SSL_KEY' "$DSIP_SSL_KEY" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_SSL_CERT" ]] && setConfigAttrib 'DSIP_SSL_CERT' "$DSIP_SSL_CERT" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_SSL_CA" ]] && setConfigAttrib 'DSIP_SSL_CA' "$DSIP_SSL_CA" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_SSL_EMAIL" ]] && setConfigAttrib 'DSIP_SSL_EMAIL' "$DSIP_SSL_EMAIL" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DSIP_CERTS_DIR" ]] && setConfigAttrib 'DSIP_CERTS_DIR' "$DSIP_CERTS_DIR" ${DSIP_CONFIG_FILE} -q
    [[ -n "$VERSION" ]] && setConfigAttrib 'VERSION' "$VERSION" ${DSIP_CONFIG_FILE} -q
    [[ -n "$ROLE" ]] && setConfigAttrib 'ROLE' "$ROLE" ${DSIP_CONFIG_FILE} -q
    [[ -n "$GUI_INACTIVE_TIMEOUT" ]] && setConfigAttrib 'GUI_INACTIVE_TIMEOUT' "$GUI_INACTIVE_TIMEOUT" ${DSIP_CONFIG_FILE}
    [[ -n "$KAM_DB_DRIVER" ]] && setConfigAttrib 'KAM_DB_DRIVER' "$KAM_DB_DRIVER" ${DSIP_CONFIG_FILE} -q
    [[ -n "$KAM_DB_TYPE" ]] && setConfigAttrib 'KAM_DB_TYPE' "$KAM_DB_TYPE" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DEFAULT_AUTH_DOMAIN" ]] && setConfigAttrib 'DEFAULT_AUTH_DOMAIN' "$DEFAULT_AUTH_DOMAIN" ${DSIP_CONFIG_FILE} -q
    [[ -n "$TELEBLOCK_GW_ENABLED" ]] && setConfigAttrib 'TELEBLOCK_GW_ENABLED' "$TELEBLOCK_GW_ENABLED" ${DSIP_CONFIG_FILE}
    [[ -n "$TELEBLOCK_GW_IP" ]] && setConfigAttrib 'TELEBLOCK_GW_IP' "$TELEBLOCK_GW_IP" ${DSIP_CONFIG_FILE} -q
    [[ -n "$TELEBLOCK_GW_PORT" ]] && setConfigAttrib 'TELEBLOCK_GW_PORT' "$TELEBLOCK_GW_PORT" ${DSIP_CONFIG_FILE} -q
    [[ -n "$TELEBLOCK_MEDIA_IP" ]] && setConfigAttrib 'TELEBLOCK_MEDIA_IP' "$TELEBLOCK_MEDIA_IP" ${DSIP_CONFIG_FILE} -q
    [[ -n "$TELEBLOCK_MEDIA_PORT" ]] && setConfigAttrib 'TELEBLOCK_MEDIA_PORT' "$TELEBLOCK_MEDIA_PORT" ${DSIP_CONFIG_FILE} -q
    [[ -n "$FLOWROUTE_ACCESS_KEY" ]] && setConfigAttrib 'FLOWROUTE_ACCESS_KEY' "$FLOWROUTE_ACCESS_KEY" ${DSIP_CONFIG_FILE} -q
    [[ -n "$FLOWROUTE_SECRET_KEY" ]] && setConfigAttrib 'FLOWROUTE_SECRET_KEY' "$FLOWROUTE_SECRET_KEY" ${DSIP_CONFIG_FILE} -q
    [[ -n "$FLOWROUTE_API_ROOT_URL" ]] && setConfigAttrib 'FLOWROUTE_API_ROOT_URL' "$FLOWROUTE_API_ROOT_URL" ${DSIP_CONFIG_FILE} -q
    [[ -n "$HOMER_ID" ]] && setConfigAttrib 'HOMER_ID' "$HOMER_ID" ${DSIP_CONFIG_FILE}
    [[ -n "$HOMER_HEP_HOST" ]] && setConfigAttrib 'HOMER_HEP_HOST' "$HOMER_HEP_HOST" ${DSIP_CONFIG_FILE} -q
    [[ -n "$HOMER_HEP_PORT" ]] && setConfigAttrib 'HOMER_HEP_PORT' "$HOMER_HEP_PORT" ${DSIP_CONFIG_FILE}
    [[ -n "$UPLOAD_FOLDER" ]] && setConfigAttrib 'UPLOAD_FOLDER' "$UPLOAD_FOLDER" ${DSIP_CONFIG_FILE} -q
    [[ -n "$MAIL_SERVER" ]] && setConfigAttrib 'MAIL_SERVER' "$MAIL_SERVER" ${DSIP_CONFIG_FILE} -q
    [[ -n "$MAIL_PORT" ]] && setConfigAttrib 'MAIL_PORT' "$MAIL_PORT" ${DSIP_CONFIG_FILE}
    if [[ -n "$MAIL_USE_TLS" ]]; then
        if (( $MAIL_USE_TLS == 0 )); then
            setConfigAttrib 'MAIL_USE_TLS' "False" ${DSIP_CONFIG_FILE}
        else
            setConfigAttrib 'MAIL_USE_TLS' "True" ${DSIP_CONFIG_FILE}
        fi

    fi
    if [[ -n "$MAIL_ASCII_ATTACHMENTS" ]]; then
        if (( $MAIL_ASCII_ATTACHMENTS == 1 )); then
            setConfigAttrib 'MAIL_ASCII_ATTACHMENTS' "True" ${DSIP_CONFIG_FILE}
        else
            setConfigAttrib 'MAIL_ASCII_ATTACHMENTS' "False" ${DSIP_CONFIG_FILE}
        fi
    fi
    [[ -n "$MAIL_USERNAME" ]] && setConfigAttrib 'MAIL_DEFAULT_SENDER' "dSIPRouter $EXTERNAL_FQDN <$MAIL_USERNAME>" ${DSIP_CONFIG_FILE} -q
    [[ -n "$MAIL_DEFAULT_SUBJECT" ]] && setConfigAttrib 'MAIL_DEFAULT_SUBJECT' "$MAIL_DEFAULT_SUBJECT" ${DSIP_CONFIG_FILE} -q
    [[ -n "$CLOUD_PLATFORM" ]] && setConfigAttrib 'CLOUD_PLATFORM' "$CLOUD_PLATFORM" ${DSIP_CONFIG_FILE} -q
    [[ -n "$BACKUPS_DIR" ]] && setConfigAttrib 'BACKUP_FOLDER' "$BACKUPS_DIR" ${DSIP_CONFIG_FILE} -q
    [[ -n "$DID_PREFIX_ALLOWED_CHARS" ]] && setConfigAttrib 'DID_PREFIX_ALLOWED_CHARS' "$DID_PREFIX_ALLOWED_CHARS" ${DSIP_CONFIG_FILE}
    [[ -n "$LOAD_SETTINGS_FROM" ]] && setConfigAttrib 'LOAD_SETTINGS_FROM' "$LOAD_SETTINGS_FROM" ${DSIP_CONFIG_FILE} -q

    # update settings based on values set by setDynamicScriptSettings()
    setConfigAttrib 'NETWORK_MODE' "$NETWORK_MODE" ${DSIP_CONFIG_FILE}
    if (( $IPV6_ENABLED == 1 )); then
        setConfigAttrib 'IPV6_ENABLED' "True" ${DSIP_CONFIG_FILE}
    else
        setConfigAttrib 'IPV6_ENABLED' "False" ${DSIP_CONFIG_FILE}
    fi
    setConfigAttrib 'INTERNAL_IP_ADDR' "$INTERNAL_IP_ADDR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'INTERNAL_IP_NET' "$INTERNAL_IP_NET" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'INTERNAL_IP6_ADDR' "$INTERNAL_IP6_ADDR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'INTERNAL_IP6_NET' "$INTERNAL_IP6_NET" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'INTERNAL_FQDN' "$INTERNAL_FQDN" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'EXTERNAL_IP_ADDR' "$EXTERNAL_IP_ADDR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'EXTERNAL_IP6_ADDR' "$EXTERNAL_IP6_ADDR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'EXTERNAL_FQDN' "$EXTERNAL_FQDN" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'PUBLIC_IFACE' "$PUBLIC_IFACE" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'PRIVATE_IFACE' "$PRIVATE_IFACE" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'UAC_REG_ADDR' "$UAC_REG_ADDR" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'GIT_REPO_URL' "$GIT_REPO_URL" ${DSIP_CONFIG_FILE} -q
    setConfigAttrib 'GIT_RELEASE_URL' "$GIT_RELEASE_URL" ${DSIP_CONFIG_FILE} -q

    # TODO: the following are updated in setCredentials() and the config file should only be updated here
    #		i.e. settings the variables elsewhere is fine but any changes to the config file or DB should be centralised here
    # DSIP_GUI_USER
    # DSIP_GUI_PASS
    # DSIP_API_TOKEN
    # DSIP_MAIL_USER
    # DSIP_MAIL_PASS
    # DSIP_IPC_PASS
    # KAM_DB_USER
    # KAM_DB_PASS
    # KAM_DB_HOST
    # KAM_DB_PORT
    # KAM_DB_NAME
    # ROOT_DB_HOST
    # ROOT_DB_PORT
    # ROOT_DB_USER
    # ROOT_DB_PASS
    # ROOT_DB_NAME
    # DSIP_SESSION_KEY

    # TODO: the following settings are only updatable via the GUI
    # TRANSNEXUS_AUTHSERVICE_ENABLED
    # TRANSNEXUS_AUTHSERVICE_HOST
    # TRANSNEXUS_LICENSE_KEY
    # TRANSNEXUS_VERIFYSERVICE_ENABLED
    # TRANSNEXUS_VERIFYSERVICE_HOST
    # STIR_SHAKEN_ENABLED
    # STIR_SHAKEN_PREFIX_A
    # STIR_SHAKEN_PREFIX_B
    # STIR_SHAKEN_PREFIX_C
    # STIR_SHAKEN_PREFIX_INVALID
    # STIR_SHAKEN_BLOCK_INVALID
    # STIR_SHAKEN_CERT_URL
    # STIR_SHAKEN_KEY_PATH
    # MSTEAMS_DNS_ENDPOINTS
    # MSTEAMS_IP_ENDPOINTS

    # TODO: workaround to update DB settings until next major release (v0.80)
    if [[ "$LOAD_SETTINGS_FROM" == "db" ]]; then
        setConfigAttrib 'LOAD_SETTINGS_FROM' 'file' ${DSIP_CONFIG_FILE} -q
        ${PYTHON_CMD} -c "import os,sys; os.chdir('${DSIP_PROJECT_DIR}/gui'); sys.path.insert(0, '${DSIP_SYSTEM_CONFIG_DIR}/gui'); from dsiprouter import syncSettings; syncSettings();"
        setConfigAttrib 'LOAD_SETTINGS_FROM' 'db' ${DSIP_CONFIG_FILE} -q
    fi

    return 0
}

# TODO: these variables should be ephemeral, set as environment variables when running the service, no need to store them
function updateDsiprouterConfigRuntimeSettings() {
    if (( ${DEBUG} == 1 )); then
        setConfigAttrib 'DEBUG' 'True' ${DSIP_CONFIG_FILE}
    else
        setConfigAttrib 'DEBUG' 'False' ${DSIP_CONFIG_FILE}
    fi
}

function updateDsiprouterStartup {
    local KAM_UPDATE_OPTS=""

    # update dsiprouter configs on reboot
    removeInitCmd "/usr/bin/dsiprouter updatedsipconfig"
    addInitCmd "/usr/bin/dsiprouter updatedsipconfig $KAM_UPDATE_OPTS"

    # make sure dsip-init service runs prior to dsiprouter service
    removeDependsOnInit "dsiprouter.service"
    addDependsOnInit "dsiprouter.service"
}

function renewSSLCert() {
    # Don't try to renew if using wildcard certs
    openssl x509 -in ${DSIP_SSL_CERT} -noout -subject | grep "CN\s\?=\s\?*." &>/dev/null
    if (( $? == 0 )); then
	    printwarn "Wildcard certifcates are being used! LetsEncrypt certifcates can't automatically renew wildcard certificates"
   	    return
    fi

    # Don't renew if a default cert was uploaded
    local DEFAULT_CERT_UPLOADED=$(withKamDB mysql -sN -e "select count(*) from dsip_certificates where domain='default'" 2> /dev/null)
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
        updatePermissions -certs
        # have to restart kamailio due to bug in tls module
        #kamcmd tls.reload
        systemctl restart kamailio
    else
        printerr "Failed Renewing Cert for ${EXTERNAL_FQDN} using LetsEncrypt"
    fi
}

function configureSSL() {
    # Check if certificates already exists.  If so, use them and exit
    if [[ -f "${DSIP_SSL_CERT}" && -f "${DSIP_SSL_KEY}" ]]; then
        printwarn "Using certificates found in ${DSIP_CERTS_DIR}"
        updatePermissions -certs
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
    certbot certonly --standalone --non-interactive --agree-tos -d ${EXTERNAL_FQDN} -m ${DSIP_SSL_EMAIL} \
        --server https://acme-v02.api.letsencrypt.org/directory --force-renewal --preferred-chain "ISRG Root X1"
    if (( $? == 0 )); then
        rm -f ${DSIP_CERTS_DIR}/dsiprouter*
        cp -f /etc/letsencrypt/live/${EXTERNAL_FQDN}/fullchain.pem ${DSIP_SSL_CERT}
        cp -f /etc/letsencrypt/live/${EXTERNAL_FQDN}/privkey.pem ${DSIP_SSL_KEY}
        # Add Nightly Cronjob to renew certs if not already there
        if ! crontab -l | grep -q "/usr/bin/dsiprouter renewsslcert" 2>/dev/null; then
            cronAppend "0 0 * * * /usr/bin/dsiprouter renewsslcert"
        fi
    else
        printwarn "Failed Generating Certs for ${EXTERNAL_FQDN} using LetsEncrypt"

        # Worst case, generate a Self-Signed Certificate
        printdbg "Generating dSIPRouter Self-Signed Certificates"
        openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out ${DSIP_SSL_CERT} -keyout ${DSIP_SSL_KEY} -subj "/C=US/ST=MI/L=Detroit/O=dSIPRouter/CN=${EXTERNAL_FQDN}"
    fi
    updatePermissions -certs

    # Start nginx if dSIP was installed
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
        docker stop dsiprouter-nginx 2>/dev/null
    else
        firewall-cmd --zone=public --remove-port=80/tcp
    fi
}

# updates and settings in kam config that may change
# should be run after changing settings.py or change in network configurations
# TODO: support configuring separate asterisk realtime db conns / clusters (would need separate setting in settings.py)
function updateKamailioConfig() {
    local DSIP_ID=${DSIP_ID:-$(getConfigAttrib 'DSIP_ID' ${DSIP_CONFIG_FILE})}
    local DSIP_CLUSTER_ID=${DSIP_CLUSTER_ID:-$(getConfigAttrib 'DSIP_CLUSTER_ID' ${DSIP_CONFIG_FILE})}
    local DSIP_CLUSTER_SYNC=${DSIP_CLUSTER_SYNC:-$([[ "$(getConfigAttrib 'DSIP_CLUSTER_SYNC' ${DSIP_CONFIG_FILE})" == "True" ]] && echo '1' || echo '0')}
    local DSIP_VERSION=${DSIP_VERSION:-$(getConfigAttrib 'VERSION' ${DSIP_CONFIG_FILE})}
    local HOMER_ID=${HOMER_ID:-$(getConfigAttrib 'HOMER_ID' ${DSIP_CONFIG_FILE})}
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
    local HOMER_HEP_HOST=${HOMER_HEP_HOST:-$(getConfigAttrib 'HOMER_HEP_HOST' ${DSIP_CONFIG_FILE})}
    local HOMER_HEP_PORT=${HOMER_HEP_PORT:-$(getConfigAttrib 'HOMER_HEP_PORT' ${DSIP_CONFIG_FILE})}
    local NETWORK_MODE=${NETWORK_MODE:-$(getConfigAttrib 'NETWORK_MODE' ${DSIP_CONFIG_FILE})}

    # update kamailio config file
    if (( $DEBUG == 1 )); then
        enableKamailioConfigAttrib 'WITH_DEBUG' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_DEBUG' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if (( $SERVERNAT == 1 )); then
        enableKamailioConfigAttrib 'WITH_SERVERNAT' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_SERVERNAT' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if (( $SERVERNAT6 == 1 )); then
        enableKamailioConfigAttrib 'WITH_SERVERNAT6' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_SERVERNAT6' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if (( $IPV6_ENABLED == 1 )); then
        enableKamailioConfigAttrib 'WITH_IPV6' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_IPV6' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if (( $NETWORK_MODE == 2 )); then
        enableKamailioConfigAttrib 'WITH_DMZ' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_DMZ' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if (( $DSIP_CLUSTER_SYNC == 1 )); then
        enableKamailioConfigAttrib 'WITH_DMQ' ${DSIP_KAMAILIO_CONFIG_FILE}
        setKamailioConfigSubst 'DMQ_REPLICATE_ENABLED' '1' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_DMQ' ${DSIP_KAMAILIO_CONFIG_FILE}
        setKamailioConfigSubst 'DMQ_REPLICATE_ENABLED' '0' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if [[ -n "$HOMER_HEP_HOST" ]]; then
        enableKamailioConfigAttrib 'WITH_HOMER' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_HOMER' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if [[ -n "$DSIP_ID" && "$DSIP_ID" != "None" ]]; then
        setKamailioConfigSubst 'DSIP_ID' "$DSIP_ID" ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if [[ -n "$HOMER_ID" && "$HOMER_ID" != "None" ]]; then
        setKamailioConfigSubst 'HOMER_ID' "$HOMER_ID" ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    setKamailioConfigSubst 'DSIP_CLUSTER_ID' "${DSIP_CLUSTER_ID}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'DSIP_VERSION' "${DSIP_VERSION}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'INTERNAL_IP_ADDR' "${INTERNAL_IP_ADDR}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'INTERNAL_IP6_ADDR' "${INTERNAL_IP6_ADDR}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'INTERNAL_IP_NET' "${INTERNAL_IP_NET}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'INTERNAL_IP6_NET' "${INTERNAL_IP_NET6}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'EXTERNAL_IP_ADDR' "${EXTERNAL_IP_ADDR}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'EXTERNAL_IP6_ADDR' "${EXTERNAL_IP6_ADDR}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'INTERNAL_FQDN' "${INTERNAL_FQDN}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'EXTERNAL_FQDN' "${EXTERNAL_FQDN}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'UAC_REG_ADDR' "${UAC_REG_ADDR}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'WSS_PORT' "${KAM_WSS_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'SIP_PORT' "${KAM_SIP_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'SIPS_PORT' "${KAM_SIPS_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'DMQ_PORT' "${KAM_DMQ_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'HOMER_HOST' "${HOMER_HEP_HOST}" ${DSIP_KAMAILIO_CONFIG_FILE}
    setKamailioConfigSubst 'HEP_PORT' "${HOMER_HEP_PORT}" ${DSIP_KAMAILIO_CONFIG_FILE}
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

    # update kamailio TLS config file
#    if (( ${IPV6_ENABLED} == 1 )); then
#        perl -e "\$external_ip='${EXTERNAL_IP_ADDR}'; \$wss_port='${KAM_WSS_PORT}'; "'$ipv6_config=
#            "[server:['"${EXTERNAL_IP6_ADDR}"']:'"${KAM_WSS_PORT}"']\n" .
#            "method = TLSv1.2+\n" .
#            "verify_certificate = no\n" .
#            "require_certificate = no\n" .
#            "private_key = /etc/dsiprouter/certs/dsiprouter-key.pem\n" .
#            "certificate = /etc/dsiprouter/certs/dsiprouter-cert.pem\n" .
#            "ca_list = /etc/dsiprouter/certs/ca-list.pem\n" .
#            "#crl = /etc/dsiprouter/certs/crl.pem\n";' \
#            -0777 -i -pe 's%(#========== webrtc_ipv4_start ==========#.*?\[server:).*?:.*?(\].*#========== webrtc_ipv4_stop ==========#)%\1${external_ip}:${wss_port}\2%s;
#            s%(#========== webrtc_ipv6_start ==========#[\s]+).*(#========== webrtc_ipv6_stop ==========#)%\1${ipv6_config}\2%s;' \
#            ${DSIP_KAMAILIO_TLS_CONFIG_FILE}
#    else
#        perl -e "\$external_ip='${EXTERNAL_IP_ADDR}'; \$wss_port='${KAM_WSS_PORT}';" -0777 -i \
#            -pe 's%(#========== webrtc_ipv4_start ==========#.*?\[server:).*?:.*?(\].*#========== webrtc_ipv4_stop ==========#)%\1${external_ip}:${wss_port}\2%s;
#            s%(#========== webrtc_ipv6_start ==========#[\s]+).*(#========== webrtc_ipv6_stop ==========#)%\1\2%s;' \
#            ${DSIP_KAMAILIO_TLS_CONFIG_FILE}
#    fi

    return 0
}

# update kamailio service startup commands accounting for any changes
function updateKamailioStartup {
    local KAM_UPDATE_OPTS=""

    # update kamailio configs on reboot
    removeInitCmd "/usr/bin/dsiprouter updatekamconfig"
    addInitCmd "/usr/bin/dsiprouter updatekamconfig $KAM_UPDATE_OPTS"

    # make sure dsip-init service runs prior to kamailio service
    removeDependsOnInit "kamailio.service"
    addDependsOnInit "kamailio.service"
}

# updates and settings in rtpengine config that may change
# should be run after reboot or change in network configurations
function updateRtpengineConfig() {
    local INTERFACE=""
    local HOMER_ID=${HOMER_ID:-$(getConfigAttrib 'HOMER_ID' ${DSIP_CONFIG_FILE})}
    local RTP_PORT_MIN=${RTP_PORT_MIN:-$(getRtpengineConfigAttrib 'RTP_PORT_MIN' ${SYSTEM_RTPENGINE_CONFIG_FILE})}
    local RTP_PORT_MAX=${RTP_PORT_MAX:-$(getRtpengineConfigAttrib 'RTP_PORT_MAX' ${SYSTEM_RTPENGINE_CONFIG_FILE})}

    if (( ${NETWORK_MODE} == 2 )); then
        # TODO: ipv6 support broken here
        INTERFACE="public/${EXTERNAL_IP_ADDR}; private/${INTERNAL_IP_ADDR}"
    else
        if (( ${SERVERNAT} == 1 )); then
            INTERFACE="ipv4/${INTERNAL_IP_ADDR}!${EXTERNAL_IP_ADDR}"
        else
            INTERFACE="ipv4/${INTERNAL_IP_ADDR}"
        fi
        if (( ${IPV6_ENABLED} == 1 )); then
            if (( ${SERVERNAT6} == 1 )); then
                INTERFACE="${INTERFACE}; ipv6/${INTERNAL_IP6_ADDR}!${EXTERNAL_IP6_ADDR}"
            else
                INTERFACE="${INTERFACE}; ipv6/${INTERNAL_IP6_ADDR}"
            fi
        fi
    fi

    setRtpengineConfigAttrib 'interface' "$INTERFACE" ${SYSTEM_RTPENGINE_CONFIG_FILE}
    setRtpengineConfigAttrib 'port-min' "$RTP_PORT_MIN" ${SYSTEM_RTPENGINE_CONFIG_FILE}
    setRtpengineConfigAttrib 'port-max' "$RTP_PORT_MAX" ${SYSTEM_RTPENGINE_CONFIG_FILE}

    if [[ -n "$HOMER_HEP_HOST" ]]; then
        enableRtpengineConfigAttrib 'homer' ${SYSTEM_RTPENGINE_CONFIG_FILE}
        enableRtpengineConfigAttrib 'homer-protocol' ${SYSTEM_RTPENGINE_CONFIG_FILE}
        enableRtpengineConfigAttrib 'homer-id' ${SYSTEM_RTPENGINE_CONFIG_FILE}
        setRtpengineConfigAttrib 'homer' "$HOMER_HEP_HOST" ${SYSTEM_RTPENGINE_CONFIG_FILE}
        setRtpengineConfigAttrib 'homer-id' "$HOMER_ID" ${SYSTEM_RTPENGINE_CONFIG_FILE}
    else
        disableRtpengineConfigAttrib 'homer' ${SYSTEM_RTPENGINE_CONFIG_FILE}
        disableRtpengineConfigAttrib 'homer-protocol' ${SYSTEM_RTPENGINE_CONFIG_FILE}
        disableRtpengineConfigAttrib 'homer-id' ${SYSTEM_RTPENGINE_CONFIG_FILE}
    fi

    return 0
}

# update rtpengine service startup commands accounting for any changes
function updateRtpengineStartup() {
    local RTP_UPDATE_OPTS=""

    # update rtpengine configs on reboot
    removeInitCmd "/usr/bin/dsiprouter updatertpconfig"
    addInitCmd "/usr/bin/dsiprouter updatertpconfig $RTP_UPDATE_OPTS"

    # make sure dsip-init service runs prior to rtpengine service
    removeDependsOnInit "rtpengine.service"
    addDependsOnInit "rtpengine.service"
}

# updates DNSmasq configs from DB
function updateDnsConfig() {
    local KAM_DB_HOST=${KAM_DB_HOST:-$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})}
    local KAM_DB_PORT=${KAM_DB_PORT:-$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})}
    local KAM_DB_NAME=${KAM_DB_NAME:-$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})}
    local KAM_DB_USER=${KAM_DB_USER:-$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})}
    local KAM_DB_PASS=${KAM_DB_PASS:-$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})}
    local DSIP_CLUSTER_ID=${DSIP_CLUSTER_ID:-$(getConfigAttrib 'DSIP_CLUSTER_ID' ${DSIP_CONFIG_FILE})}
    local DNS_CONFIG=""

    # grab hosts from db
    # NOTE: we don't add IPV6 addresses here as it is not needed and would only add more traffic to DMQ replication
    local INTERNAL_CLUSTER_HOSTS=(
        $(withKamDB mysql -sN \
            -e "SELECT INTERNAL_IP_ADDR FROM dsip_settings WHERE DSIP_CLUSTER_ID = ${DSIP_CLUSTER_ID};" 2>/dev/null)
    )
    local EXTERNAL_CLUSTER_HOSTS=(
        $(withKamDB mysql -sN \
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
        DNS_CONFIG+="${INTERNAL_IP_ADDR} local.cluster\n"
    fi

    # update hosts file
    perl -e "\$cluster_hosts=\"${DNS_CONFIG}\";" \
        -0777 -i -pe 's|(#+DSIP_CONFIG_START).*?(#+DSIP_CONFIG_END)|\1\n${cluster_hosts}\2|gms' /etc/hosts

    # tell dnsmasq to reload configs
    if [ -f /run/dnsmasq/dnsmasq.pid ]; then
        kill -SIGHUP $(cat /run/dnsmasq/dnsmasq.pid) 2>/dev/null
    elif [ -f /run/dnsmasq.pid ]; then
        kill -SIGHUP $(cat /run/dnsmasq.pid) 2>/dev/null
    else
        kill -SIGHUP $(pidof dnsmasq) 2>/dev/null
    fi

    return 0
}

function updateCACertsDir() {
    awk -v dsip_certs_dir="${DSIP_CERTS_DIR}" \
        'BEGIN {c=0;}
        /BEGIN CERT/{c++} {
            print > dsip_certs_dir "/ca/cert." c ".pem"
        }' <${DSIP_SSL_CA} &&
    openssl rehash ${DSIP_CERTS_DIR}/ca/ &&
    updatePermissions -certs &&
    return 0 ||
    return 1
}
export -f updateCACertsDir

function generateKamailioConfig() {
    # Backup kamcfg, generate fresh config from templates, and link it in where kamailio wants it
    mkdir -p ${BACKUPS_DIR}/kamailio
    cp -f ${SYSTEM_KAMAILIO_CONFIG_DIR}/*.cfg ${BACKUPS_DIR}/kamailio/ 2>/dev/null
    rm -f ${SYSTEM_KAMAILIO_CONFIG_DIR}/*.cfg 2>/dev/null
    cp -f ${PROJECT_KAMAILIO_CONFIG_DIR}/* ${DSIP_SYSTEM_CONFIG_DIR}/kamailio/
    ln -sft ${SYSTEM_KAMAILIO_CONFIG_DIR}/ ${DSIP_SYSTEM_CONFIG_DIR}/kamailio/*

    # version specific settings
    if (( ${KAM_VERSION} >= 52 )); then
        sed -i -r -e 's~#+(modparam\(["'"'"']htable["'"'"'], ?["'"'"']dmq_init_sync["'"'"'], ?[0-9]\))~\1~g' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi

    # Fix the mpath and export $mpath
    fixMPATH

    # non-module features to enable
    # TODO: add check for WITH_TRANSNEXUS
    if (( ${WITH_LCR} == 1 )); then
        enableKamailioConfigAttrib 'WITH_LCR' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_LCR' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi
    if [[ -f ${mpath}/stirshaken.so ]]; then
        enableKamailioConfigAttrib 'WITH_STIRSHAKEN' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        disableKamailioConfigAttrib 'WITH_STIRSHAKEN' ${DSIP_KAMAILIO_CONFIG_FILE}
    fi

    updatePermissions -kamailio
}

function configureKamailioDB() {
    # make sure kamailio user and privileges exist
    if ! checkDBUserExists "${KAM_DB_USER}@localhost"; then
        withRootDBConn mysql \
            -e "CREATE USER '$KAM_DB_USER'@'localhost' IDENTIFIED BY '$KAM_DB_PASS';" \
            -e "GRANT ALL PRIVILEGES ON $KAM_DB_NAME.* TO '$KAM_DB_USER'@'localhost';" \
            -e "FLUSH PRIVILEGES;"
    fi
    if ! checkDBUserExists "${KAM_DB_USER}@%"; then
        withRootDBConn mysql \
            -e "CREATE USER '$KAM_DB_USER'@'%' IDENTIFIED BY '$KAM_DB_PASS';" \
            -e "GRANT ALL PRIVILEGES ON $KAM_DB_NAME.* TO '$KAM_DB_USER'@'%';" \
            -e "FLUSH PRIVILEGES;"
    fi

    # Install schema for drouting module
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        -e "delete from version where table_name in ('dr_gateways','dr_groups','dr_gw_lists','dr_custom_rules','dr_rules')"
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        -e "drop table if exists dr_gateways,dr_groups,dr_gw_lists,dr_custom_rules,dr_rules"
    if [ -e  /usr/share/kamailio/mysql/drouting-create.sql ]; then
        withRootDBConn --db="$KAM_DB_NAME" mysql \
            < /usr/share/kamailio/mysql/drouting-create.sql
    else
        sqlscript=$(find / -name '*drouting-create.sql' | grep 'mysql' | head -1)
        withRootDBConn --db="$KAM_DB_NAME" mysql \
            < $sqlscript
    fi

    # Update schema for dr_gateways table
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dr_gateways.sql

    # Update schema for dr_gw_lists table
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dr_gw_lists.sql

    # Update schema for dr_rules table
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dr_rules.sql

    # Update schema for dispatcher table
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dispatcher.sql

    # Update schema for address table
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/address.sql

    # Update schema for subscribers table
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/subscribers.sql

    # Update schema for uacreg table
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/uacreg.sql

    # Install schema for custom LCR logic
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_lcr.sql

    # Install schema for custom MaintMode logic
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_maintmode.sql

    # Install schema for Call Limit
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_calllimit.sql

    # Install schema for Notifications
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_notification.sql

    # Install schema for dsip_gw2gwgroup
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_gw2gwgroup.sql

    # Install schema for dsip_gwgroup2lb
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_gwgroup2lb.sql

    # Install schema for dsip_cdrinfo
    withRootDBConn --db="$KAM_DB_NAME" mysql \
        < ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_cdrinfo.sql

    # Install schema for dsip_settings
    perl -e "\$hlen='$HASHED_CREDS_ENCODED_MAX_LEN'; \$clen='$AESCTR_CREDS_ENCODED_MAX_LEN';" \
        -pe 's%\@HASHED_CREDS_ENCODED_MAX_LEN%$hlen%g; s%\@AESCTR_CREDS_ENCODED_MAX_LEN%$clen%g;' \
        ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_settings.sql |
        withRootDBConn --db="$KAM_DB_NAME" mysql

    # Install schema for dsip_hardfwd and dsip_failfwd and dsip_prefix_mapping
    sed -e "s|FLT_INBOUND_REPLACE|${FLT_INBOUND}|g" ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_forwarding.sql |
        withRootDBConn --db="$KAM_DB_NAME" mysql

    # TODO: we need to test and re-implement this.
#    # required if tables exist and we are updating
#    function resetIncrementers {
#        SQL_TABLES=$(
#            (for t in "$@"; do printf ",'$t'"; done) | cut -d ',' -f '2-'
#        )
#
#        # reset auto increment for related tables to max btwn the related tables
#        INCREMENT=$(
#            withRootDBConn mysql --skip-column-names -e "\
#                SELECT MAX(AUTO_INCREMENT) FROM INFORMATION_SCHEMA.TABLES \
#                WHERE TABLE_SCHEMA = '$KAM_DB_NAME' \
#                AND TABLE_NAME IN($SQL_TABLES);"
#        )
#        for t in "$@"; do
#            withRootDBConn --db="$KAM_DB_NAME" mysql \
#                -e "ALTER TABLE $t AUTO_INCREMENT=$INCREMENT"
#        done
#    }
#
#    # reset auto incrementers for related tables
#    resetIncrementers "dr_gw_lists"
#    resetIncrementers "uacreg"

    # truncate tables first if kamailio already installed
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
        withRootDBConn --db="$KAM_DB_NAME" mysql \
            -e "TRUNCATE TABLE dr_gw_lists; TRUNCATE TABLE address; TRUNCATE TABLE dr_gateways; TRUNCATE TABLE dr_rules;"
    fi

    # import default carriers and outbound routes
    mkdir -p /tmp/defaults
    # generate defaults subbing in dynamic values
    cp -f ${PROJECT_DSIP_DEFAULTS_DIR}/dr_gw_lists.csv /tmp/defaults/dr_gw_lists.csv
    sed "s/FLT_CARRIER/$FLT_CARRIER/g; s/FLT_PBX/$FLT_PBX/g; s/FLT_MSTEAMS/$FLT_MSTEAMS/g" \
        ${PROJECT_DSIP_DEFAULTS_DIR}/address.csv > /tmp/defaults/address.csv
    sed "s/FLT_CARRIER/$FLT_CARRIER/g; s/FLT_PBX/$FLT_PBX/g; s/FLT_MSTEAMS/$FLT_MSTEAMS/g" \
        ${PROJECT_DSIP_DEFAULTS_DIR}/dr_gateways.csv > /tmp/defaults/dr_gateways.csv
    sed "s/FLT_OUTBOUND/$FLT_OUTBOUND/g; s/FLT_INBOUND/$FLT_INBOUND/g" \
        ${PROJECT_DSIP_DEFAULTS_DIR}/dr_rules.csv > /tmp/defaults/dr_rules.csv

    # import default carriers
    withRootDBConn mysqlimport \
        --fields-terminated-by=';' --ignore-lines=0  -L $KAM_DB_NAME /tmp/defaults/address.csv
    withRootDBConn mysqlimport \
        --fields-terminated-by=';' --ignore-lines=0  -L $KAM_DB_NAME /tmp/defaults/dr_gw_lists.csv
    withRootDBConn mysqlimport \
        --fields-terminated-by=';' --ignore-lines=0  -L $KAM_DB_NAME /tmp/defaults/dr_gateways.csv
    withRootDBConn mysqlimport \
        --fields-terminated-by=';' --ignore-lines=0  -L $KAM_DB_NAME /tmp/defaults/dr_rules.csv

    # cleanup temp files
    rm -rf /tmp/defaults
}

# Try to locate the Kamailio modules directory.  It will use the last modules directory found
function fixMPATH() {
    mpath=$(find /usr/lib{32,64,}/{i386*/*,i386*/kamailio/*,x86_64*/*,x86_64*/kamailio/*,*} -name drouting.so -printf '%h/' -quit 2>/dev/null)

    if [ "$mpath" != '' ]; then
        setKamailioConfigGlobal 'mpath' "${mpath}" ${DSIP_KAMAILIO_CONFIG_FILE}
        printdbg "The Kamailio mpath has been updated to: $mpath"
    else
        printerr "Can't find the module path for Kamailio.  Please ensure Kamailio is installed and try again!"
        exit 1
    fi
}

# Requirements to run this script / any imported functions
function installScriptRequirements() {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.requirementsinstalled" ]; then
        return
    fi

    printdbg 'Installing one-time script requirements'

    if cmdExists 'apt-get'; then
        apt-get update -y &&
        apt-get install -y curl wget gawk perl sed git dnsutils openssl python3 jq xxd coreutils
    elif cmdExists 'dnf'; then
        dnf install -y curl wget gawk perl sed git bind-utils openssl python3 jq vim-common coreutils
    elif cmdExists 'yum'; then
        yum install -y curl wget gawk perl sed git bind-utils openssl python3 jq vim-common coreutils
    fi

    if (( $? != 0 )); then
        printerr 'Could not install script requirements'
        exit 1
    fi

    # initialize the openssl rnd generator
    dd if=/dev/urandom of="${HOME}/.rnd" bs=1024 count=1 2>/dev/null

    printdbg 'One-time script requirements installed'
    touch ${DSIP_SYSTEM_CONFIG_DIR}/.requirementsinstalled
}

# Any setup that needs to be done before the script can run properly
function setupScriptRequiredFiles() {
    # make sure dirs exist required for this script
    mkdir -p ${DSIP_SYSTEM_CONFIG_DIR}{,/gui,/kamailio} ${SRC_DIR} ${DSIP_RUN_DIR} ${DSIP_LIB_DIR} ${DSIP_CERTS_DIR}{,/ca} ${BACKUPS_DIR}

    # only copy the template file over to the DSIP_CONFIG_FILE if it doesn't already exist
    if [[ ! -f "${DSIP_CONFIG_FILE}" ]]; then
        # copy over the template settings.py to be worked on (used throughout this script as well)
        cp -f ${DSIP_PROJECT_DIR}/gui/settings.py ${DSIP_CONFIG_FILE}
    fi

    if cmdExists 'apt-get' && [[ ! -f "$APT_DSIP_CONFIG" ]]; then
        # comment out cdrom in sources as it can halt install
        sed -i -E 's/(^\w.*cdrom.*)/#\1/g' /etc/apt/sources.list
        # make sure we run package installs unattended
        export DEBIAN_FRONTEND="noninteractive"
        export DEBIAN_PRIORITY="critical"
        # default dpkg to noninteractive modes for install
        cat <<'EOF' >${APT_DSIP_CONFIG}
Dpkg::Options {
"--force-confdef";
"--force-confnew";
}
Dpkg::Lock::Timeout "300";
APT::Get::Fix-Missing "1";
EOF
    fi

    # make perl CPAN installs non interactive
    export PERL_MM_USE_DEFAULT=1

    # fix PATH if needed
    # we are using the default install paths but these may change in the future
    if [[ ! -e "$PATH_UPDATE_FILE" ]]; then
        mkdir -p $(dirname ${PATH_UPDATE_FILE})
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

# Configure system repo sources to ensure we get the right package versions
# TODO: dynamic mirror resolution based on RTT
# TODO support multiple mirrors in repo configs
#       - ubuntu refs:
#       https://repogen.simplylinux.ch/
#       https://mirrors.ustc.edu.cn/repogen/
#       https://gist.github.com/rhuancarlos/c4d3c0cf4550db5326dca8edf1e76800
#       - centos refs:
#       https://unix.stackexchange.com/questions/52666/how-do-i-install-the-stock-centos-repositories
#       https://wiki.centos.org/PackageManagement/Yum/Priorities
function configureSystemRepos() {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.reposconfigured" ]; then
        return
    fi

    printdbg 'Configuring system repositories'
    case "$DISTRO" in
        debian|ubuntu)
            apt-get install -y apt-transport-https
            mv -f ${APT_OFFICIAL_SOURCES} ${APT_OFFICIAL_SOURCES_BAK}
            mv -f ${APT_OFFICIAL_PREFS} ${APT_OFFICIAL_PREFS_BAK} 2>/dev/null
            cp -f ${DSIP_PROJECT_DIR}/resources/apt/${DISTRO}/${DISTRO_VER}/official-releases.list ${APT_OFFICIAL_SOURCES}
            envsubst < ${DSIP_PROJECT_DIR}/resources/apt/${DISTRO}/official-releases.pref > ${APT_OFFICIAL_PREFS}
            apt-get update -y
            ;;
        # TODO: create official repo file (rhel/amzn/rocky/alma repo's?)
        # TODO: install yum priorities plugin
        # TODO: set priorities on official repo
        #amzn)
        #    ;;
    esac

    if (( $? == 1 )); then
        printerr 'Could not configure system repositories'
        exit 1
    elif (( $? >= 100 )); then
        printwarn 'Some issues occurred configuring system repositories, attempting to continue...'
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.reposconfigured
    else
        printdbg 'System repositories configured successfully'
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.reposconfigured
    fi
}

# remove dsiprouter system configs
function removeDsipSystemConfig() {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.reposconfigured" ]; then
        case "$DISTRO" in
            debian|ubuntu)
                mv -f ${APT_OFFICIAL_SOURCES_BAK} ${APT_OFFICIAL_SOURCES}
                mv -f ${APT_OFFICIAL_PREFS_BAK} ${APT_OFFICIAL_PREFS} 2>/dev/null
                apt-get update -y
            ;;
        esac
    fi
    if [[ -f "$APT_DSIP_CONFIG" ]]; then
        rm -f "$APT_DSIP_CONFIG"
    fi
    rm -rf ${DSIP_SYSTEM_CONFIG_DIR}
}

# Install and configure mysql server
function installMysql() {
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.mysqlinstalled" ]]; then
        printwarn "MySQL is already installed"
        return
    fi

    printdbg "Attempting to install / configure MySQL..."
    ${DSIP_PROJECT_DIR}/mysql/${DISTRO}/${DISTRO_MAJOR_VER}.sh install

    if (( $? != 0 )); then
        printerr "MySQL install failed"
        exit 1
    fi

    # Restart MySQL with the new configurations
    systemctl restart mariadb
    if systemctl is-active --quiet mariadb; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.mysqlinstalled
        printdbg "------------------------------------"
        pprint "MySQL Installation is complete!"
        printdbg "------------------------------------"
    else
        printerr "MySQL install failed"
        exit 1
    fi
}

# Remove mysql and its configs
function uninstallMysql() {
    if [[ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.mysqlinstalled" ]]; then
        printwarn "MySQL is not installed - skipping removal"
        return
    fi

    printdbg "Attempting to uninstall MySQL..."
    ${DSIP_PROJECT_DIR}/mysql/${DISTRO}/${DISTRO_MAJOR_VER}.sh uninstall

    if (( $? != 0 )); then
        printerr "MySQL uninstall failed"
        exit 1
    fi

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.mysqlinstalled
    printdbg "MySQL was uninstalled"
}

# Install and configure nginx server
function installNginx() {
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.nginxinstalled" ]]; then
        printwarn "nginx is already installed"
        return
    fi

    printdbg "Attempting to install / configure nginx..."
    ${DSIP_PROJECT_DIR}/nginx/${DISTRO}/${DISTRO_MAJOR_VER}.sh install

    if (( $? != 0 )); then
        printerr "nginx install failed"
        exit 1
    fi

    # Restart nginx with the new configurations
    systemctl restart nginx
    if systemctl is-active --quiet nginx; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.nginxinstalled
        printdbg "------------------------------------"
        pprint "nginx Installation is complete!"
        printdbg "------------------------------------"
    else
        printerr "nginx install failed"
        exit 1
    fi
}

# Remove nginx and its configs
function uninstallNginx() {
    if [[ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.nginxinstalled" ]]; then
        printwarn "nginx is not installed - skipping removal"
        return
    fi

    printdbg "Attempting to uninstall nginx..."
    ${DSIP_PROJECT_DIR}/nginx/${DISTRO}/${DISTRO_MAJOR_VER}.sh uninstall

    if (( $? != 0 )); then
        printerr "nginx uninstall failed"
        exit 1
    fi

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.nginxinstalled
    printdbg "nginx was uninstalled"
}

# Install the RTPEngine from sipwise
function installRTPEngine() {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]; then
        printwarn "RTPEngine is already installed"
        return
    fi

    printdbg "Attempting to install RTPEngine..."
    ${DSIP_PROJECT_DIR}/rtpengine/${DISTRO}/install.sh install
    if (( $? != 0 )); then
        printerr "RTPEngine install failed"
        exit 1
    fi

    # config updates that are the same across all OS
    updateRtpengineConfig
    # add the config updates to dsip-init service
    updateRtpengineStartup

    # restart RTPEngine with the new configurations
    systemctl restart rtpengine
    # did the service actually start with the changes?
    if ! systemctl is-active --quiet rtpengine; then
        printerr "RTPEngine install failed"
        exit 1
    fi
    # sanity check, did the new kernel module load?
    if ! lsmod | grep -q 'xt_RTPENGINE' 2>/dev/null; then
        printwarn "RTPEngine setup in userspace forwarding mode"
        printwarn "you may need to reboot the system to load the new kernel"
    fi
    # if we got here we know everything installed properly, update kamailio to use rtpengine
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
        enableKamailioConfigAttrib 'WITH_RTPENGINE' ${DSIP_KAMAILIO_CONFIG_FILE}
        systemctl restart kamailio
    fi

    touch ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled
    printdbg "------------------------------------"
    pprint "RTPEngine Installation is complete!"
    printdbg "------------------------------------"
}

# Remove RTPEngine
function uninstallRTPEngine() {
    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]; then
        printwarn "RTPEngine is not installed! - uninstalling anyway to be safe"
    fi

    printdbg "Attempting to uninstall RTPEngine..."
    ${DSIP_PROJECT_DIR}/rtpengine/${DISTRO}/install.sh uninstall

    if (( $? == 0 )); then
        if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
            disableKamailioConfigAttrib 'WITH_RTPENGINE' ${DSIP_KAMAILIO_CONFIG_FILE}
            systemctl restart kamailio
        fi
    else
        printerr "RTPEngine uninstall failed"
        exit 1
    fi

    # remove rtpengine service dependencies
    removeInitCmd "/usr/bin/dsiprouter updatertpconfig"
    removeDependsOnInit "rtpengine.service"

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled

    printdbg "RTPEngine was uninstalled"
}

function installDsiprouterCli() {
    local MAN_PROGS_DIR="/usr/share/man/man1"

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiproutercliinstalled" ]; then
        printwarn "dSIPRouter CLI is already installed"
        return
    else
        printdbg "Installing dSIPRouter CLI"
    fi

    # add dsiprouter CLI command to the path
    ln -sf ${DSIP_PROJECT_DIR}/dsiprouter.sh /usr/bin/dsiprouter
    # enable bash command line completion if not already
    if [[ -f /etc/bash.bashrc ]]; then
        perl -i -0777 -pe 's%#(if ! shopt -oq posix; then\n)#([ \t]+if \[ -f /usr/share/bash-completion/bash_completion \]; then\n)#(.*?\n)#(.*?\n)#(.*?\n)#(.*?\n)#(.*?\n)%\1\2\3\4\5\6\7%s' /etc/bash.bashrc
    fi
    # add command line completion for dsiprouter CLI
    cp -f ${DSIP_PROJECT_DIR}/dsiprouter/dsip_completion.sh /etc/bash_completion.d/dsiprouter
    # TODO: has no effect when executing script, user has to log out and log in for changes to take effect
    #. /etc/bash_completion

    # add specific commands to sudoers that dsiprouter can run with escalated privileges
    cp -f ${DSIP_PROJECT_DIR}/dsiprouter/sudoers.d/99-dsiprouter ${DSIP_SUDOERS_FILE}

    printdbg "installing dSIPRouter manpages"
    if cmdExists 'apt-get'; then
        apt-get install -y manpages man-db
    elif cmdExists 'dnf'; then
        dnf install -y man-pages man-db man
    elif cmdExists 'yum'; then
        yum install -y man-pages man-db man
    else
        ( exit 1; )
    fi

    # if manpages fail it is not a critical error
    if (( $? != 0 )); then
        printwarn 'failed installing manpages'
    else
        cp -f ${DSIP_PROJECT_DIR}/resources/man/dsiprouter.1 ${MAN_PROGS_DIR}/ &&
        gzip -f ${MAN_PROGS_DIR}/dsiprouter.1 &&
        mandb &&
        printdbg "dSIPRouter manpage installed" ||
        printwarn 'failed installing manpages'
    fi

    touch "${DSIP_SYSTEM_CONFIG_DIR}/.dsiproutercliinstalled"
    printdbg "dSIPRouter CLI installed"
}

function uninstallDsiprouterCli() {
    local MAN_PROGS_DIR="/usr/share/man/man1"

    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiproutercliinstalled" ]; then
        printwarn "dSIPRouter CLI is not installed, skipping..."
        return
    else
        printdbg "Uninstalling dSIPRouter CLI"
    fi

    # remove dsiprouter and dsiprouterd commands from the path
    rm -f /usr/bin/dsiprouter
    # remove command line completion for dsiprouter.sh
    rm -f /etc/bash_completion.d/dsiprouter

    # remove dsiprouter sudoers file
    rm -f ${DSIP_SUDOERS_FILE}

    printdbg "uninstalling dsiprouter manpages"
    rm -f ${MAN_PROGS_DIR}/dsiprouter.1
    rm -f ${MAN_PROGS_DIR}/dsiprouter.1.gz
    mandb
    printdbg "dsiprouter manpages uninstalled"

    rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiproutercliinstalled"
    printdbg "dSIPRouter CLI uninstalled"
}

# TODO: move documentation generation into its own separate function
# TODO: allow password changes on cloud instances (remove password reset after image creation)
# we should be starting the web server as root and dropping root privilege after
# this is standard practice, but we would have to consider file permissions
# it would be easier to manage if we moved dsiprouter configs to /etc/dsiprouter
function installDsiprouter() {
    local DSIP_CURRENT_PYTHON_VER

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]; then
        printwarn "dSIPRouter is already installed"
        return
    fi

    printdbg "Attempting to install dSIPRouter..."
    ${DSIP_PROJECT_DIR}/dsiprouter/${DISTRO}/${DISTRO_MAJOR_VER}.sh install

    if (( $? != 0 )); then
        printerr "dSIPRouter install failed - OS install script failure"
        exit 1
    fi

    # extra check to ensure the OS specific script gave us the required python version
    # this just needs to be true for the virtual environment so may be different than
    # the system python version installed
    DSIP_CURRENT_PYTHON_VER=$(${PYTHON_CMD} -V | cut -d ' ' -f 2)
    versionCompare $DSIP_CURRENT_PYTHON_VER gteq $DSIP_MIN_PYTHON_VER
    if (( $? != 0 )); then
        printerr "dSIPRouter install failed - minimum python version not installed"
        exit 1
    fi

    printdbg "Configuring dSIPRouter settings"
    if [[ ! -f "$DSIP_CONFIG_FILE" ]]; then
        generateDsiprouterConfig
    fi

    # configure dsiprouter modules
    installModules

    updateDsiprouterConfig
    updateDsiprouterStartup

    # Set dsip private key (used for encryption across services) by following precedence:
    # 1:    set via cmdline arg
    # 2:    set prior to externally
    # 3:    generate new key
    # TODO: create bash-native equivalent function for creating the private key
    if [[ -n ${SET_DSIP_PRIV_KEY+set} ]]; then
        printf '%s' "${SET_DSIP_PRIV_KEY}" > ${DSIP_PRIV_KEY}
    elif [ -f "${DSIP_PRIV_KEY}" ]; then
        :
    elif (( ${RUNNING_UPGRADE:-0} == 0 )); then
        # only generate if running a fresh install
        ${PYTHON_CMD} -c "import os,sys; os.chdir('${DSIP_PROJECT_DIR}/gui'); sys.path.insert(0, '${DSIP_SYSTEM_CONFIG_DIR}/gui'); from util.security import AES_CTR; AES_CTR.genKey()"
    fi

    # Set credentials for our services, will either use credentials from CLI or generate them
    if [[ -z ${SET_DSIP_GUI_PASS+set} ]] && (( ${RUNNING_UPGRADE:-0} == 0 )); then
        if (( ${IMAGE_BUILD} == 1 || ${RESET_FORCE_INSTANCE_ID:-0} == 1 )); then
            if [[ -z "$CLOUD_PLATFORM" ]]; then
                printerr "Cloud Instance password generation requested, but Cloud Platform is unsupported or not found"
                exit 1
            fi
            SET_DSIP_GUI_PASS=$(getInstanceID)
        else
            SET_DSIP_GUI_PASS=$(urandomChars 64)
        fi
    fi
    if [[ -z ${SET_DSIP_API_TOKEN+set} ]] && (( ${RUNNING_UPGRADE:-0} == 0 )); then
        SET_DSIP_API_TOKEN=$(urandomChars 64)
    fi
    if [[ -z ${SET_DSIP_IPC_TOKEN+set} ]] && (( ${RUNNING_UPGRADE:-0} == 0 )); then
        SET_DSIP_IPC_TOKEN=$(urandomChars 64)
    fi
    if [[ -z ${SET_KAM_DB_PASS+set} ]] && (( ${RUNNING_UPGRADE:-0} == 0 )); then
        SET_KAM_DB_PASS=$(urandomChars 64)
    fi
    SET_DSIP_SESSION_KEY=${SET_DSIP_SESSION_KEY:-$(decryptConfigAttrib 'DSIP_SESSION_KEY' ${DSIP_CONFIG_FILE})}
    if [[ "$SET_DSIP_SESSION_KEY" == "None" ]] || [[ -z "$SET_DSIP_SESSION_KEY" ]]; then
        SET_DSIP_SESSION_KEY=$(urandomChars 32)
    fi

    # pass the variables on to setCredentials()
    setCredentials

    # NOTE: some of the previous files/dirs get updated here to allow dsiprouter access
    updatePermissions -certs -kamailio -dsiprouter

    # for cloud images the instance-id may change (could be a clone)
    # add to cloud-init startup process a password reset to ensure its set correctly
    # this is only for cloud image builds and will run when the instance is initialized or the instance-id is changed
    if (( $IMAGE_BUILD == 1 )) && (( $AWS_ENABLED == 1 || $DO_ENABLED == 1 || $GCE_ENABLED == 1 || $AZURE_ENABLED == 1 || $VULTR_ENABLED == 1 )); then
        (cat << EOF
#!/usr/bin/env bash

# reset admin user password
/usr/bin/dsiprouter resetpassword -q -fid

exit 0
EOF
        ) >/var/lib/cloud/scripts/per-instance/99-dsip-reset-guiadminpass.sh
        chmod +x /var/lib/cloud/scripts/per-instance/99-dsip-reset-guiadminpass.sh

        # Required changes for Debian-based images
        case "$DISTRO" in
            debian|ubuntu)
                # Remove debian-sys-maint password for initial image scan
                sed -i "s/password =.*/password = /g" /etc/mysql/debian.cnf

                # Change default password for debian-sys-maint to instance-id at next boot
                # we must also change the corresponding password in /etc/mysql/debian.cnf
                # to comply with AWS AMI image standards
                # this must run at startup as well so create temp script and add to dsip-init
                (cat << EOF
#!/usr/bin/env bash

# declare imported functions from library
$(declare -f isInstanceAMI)
$(declare -f isInstanceDO)
$(declare -f isInstanceGCE)
$(declare -f isInstanceAZURE)
$(declare -f isInstanceVULTR)
$(declare -f getInstanceID)

# wait for mysql to start
while ! systemctl is-active --quiet mariadb; do
    sleep 2
done

# reset debian user password
INSTANCE_ID=\$(getInstanceID)
mysql -e "DROP USER 'debian-sys-maint'@'localhost';
    CREATE USER 'debian-sys-maint'@'localhost' IDENTIFIED BY '\${INSTANCE_ID}';
    GRANT ALL ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '\${INSTANCE_ID}';
    FLUSH PRIVILEGES;"

sed -i "s|password =.*|password = \${INSTANCE_ID}|g" /etc/mysql/debian.cnf

exit 0
EOF
                ) >/var/lib/cloud/scripts/per-instance/99-dsip-reset-debsysuser.sh
                chmod +x /var/lib/cloud/scripts/per-instance/99-dsip-reset-debsysuser.sh
                ;;
        esac
    fi

    # generate documentation for the GUI
    # TODO: we should fix these errors instead of masking them
    # TODO: we should move generated docs to DSIP_LIB_DIR to keep clean repo
    (
        cd ${DSIP_PROJECT_DIR}/docs &&
        make -j $(nproc) html >/dev/null 2>&1
    )

    # Restart dSIPRouter / nginx / Kamailio with new configurations
    if [[ -f ${DSIP_SYSTEM_CONFIG_DIR}/.nginxinstalled ]]; then
        systemctl restart nginx
    fi
    if [[ -f ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled ]]; then
        systemctl restart kamailio
    fi
    systemctl restart dsiprouter
    if systemctl is-active --quiet dsiprouter; then
        # custom dsiprouter MOTD banner for ssh logins
        # only update on successful install so we don't confuse user
        updateBanner

        touch ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled
        printdbg "-------------------------------------"
        pprint "dSIPRouter Installation is complete! "
        printdbg "-------------------------------------"
    else
        printerr "dSIPRouter install failed"
        exit 1
    fi
}

function uninstallDsiprouter() {
    cd ${DSIP_PROJECT_DIR}

    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]; then
        printwarn "dSIPRouter is not installed or failed during install - uninstalling anyway to be safe"
    fi

    # stop the process
    systemctl stop dsiprouter

    printdbg "Attempting to uninstall dSIPRouter UI..."
    ${DSIP_PROJECT_DIR}/dsiprouter/${DISTRO}/${DISTRO_MAJOR_VER}.sh uninstall

    if [ $? -ne 0 ]; then
        printerr "dsiprouter uninstall failed"
        exit 1
    fi

    # Remove dsiprouter crontab entries
    printdbg "Removing dsiprouter crontab entries"
    cronRemove 'dsiprouter_cron.py'

    # Remove dsip private key
    rm -f ${DSIP_PRIV_KEY}

    # revert to previous MOTD ssh login banner
    revertBanner

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled

    printdbg "dSIPRouter was uninstalled"
}

function installKamailio() {
    local KAMDB_DATABASE_BACKUP_FILE="${CURR_BACKUP_DIR}/db.sql"
    local KAMDB_USER_BACKUP_FILE="${CURR_BACKUP_DIR}/user.sql"

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
        printwarn "kamailio is already installed"
        return
    else
        printdbg "Attempting to install Kamailio..."
    fi

    # backup and drop kam db if it exists already
    mkdir -p ${CURR_BACKUP_DIR}

    if cmdExists 'mysql'; then
        if checkDB "$KAM_DB_NAME"; then
            printdbg "Backing up kamailio DB to ${KAMDB_DATABASE_BACKUP_FILE} before fresh install"
            dumpDB "$KAM_DB_NAME" > ${KAMDB_DATABASE_BACKUP_FILE}
            withRootDBConn mysql -e "DROP DATABASE $KAM_DB_NAME;"
            printdbg "Backing up kamailio DB Users to ${KAMDB_USER_BACKUP_FILE} before fresh install"
            dumpDBUser "${KAM_DB_USER}@${KAM_DB_NAME}" > ${KAMDB_USER_BACKUP_FILE}
            withRootDBConn mysql -e "DROP USER IF EXISTS '$KAM_DB_USER'@'%'; DROP USER IF EXISTS '$KAM_DB_USER'@'localhost';"
        fi
    fi

    ${DSIP_PROJECT_DIR}/kamailio/${DISTRO}/${DISTRO_MAJOR_VER}.sh install
    if (( $? == 0 )); then
        configureSSL
        configureKamailioDB
        if [[ ! -f "$DSIP_KAMAILIO_CONFIG_FILE" ]]; then
            generateKamailioConfig
        fi
        updateKamailioConfig
        updateKamailioStartup
    else
        printerr "kamailio install failed"
        exit 1
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
        exit 1
    fi
}

function uninstallKamailio() {
    cd ${DSIP_PROJECT_DIR}

    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]; then
        printwarn "kamailio is not installed or failed during install - uninstalling anyway to be safe"
    fi

    # stop the process
    systemctl stop kamailio

    printdbg "Attempting to uninstall Kamailio..."
    ${DSIP_PROJECT_DIR}/kamailio/${DISTRO}/${DISTRO_MAJOR_VER}.sh uninstall

    if [ $? -ne 0 ]; then
        printerr "kamailio uninstall failed"
        exit 1
    fi

    # remove kam service dependencies
    removeInitCmd "/usr/bin/dsiprouter updatekamconfig"
    removeDependsOnInit "kamailio.service"

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled

    printdbg "kamailio was uninstalled"
}


function installModules() {
    # Remove any previous dsiprouter cronjobs
    cronRemove 'dsiprouter_cron.py'

    # Install / Uninstall dSIPModules
    for dir in ${DSIP_PROJECT_DIR}/gui/modules/*; do
        if [[ -e ${dir}/install.sh ]]; then
            ${dir}/install.sh
        fi
    done
}

function installCron() {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.croninstalled" ]; then
        printwarn "cron is already installed"
        return
    else
        printdbg "Attempting to install cron"
    fi

    if cmdExists 'apt-get'; then
        apt-get install -y cron
    elif cmdExists 'dnf'; then
        dnf install -y cronie
    elif cmdExists 'yum'; then
        yum install -y cronie
    fi

    if (( $? != 0 )); then
        printerr "cron install failed"
        exit 1
    fi

    pprint "cron was installed"
    touch ${DSIP_SYSTEM_CONFIG_DIR}/.croninstalled
}

# Install Sipsak
# Used for testing and troubleshooting
function installSipsak() {
    local NPROC

    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.sipsakinstalled" ]; then
        printwarn "SipSak is already installed"
        return
    else
        printdbg "Attempting to install SipSak"
    fi

    # Install sipsak requirements
    if cmdExists 'apt-get'; then
        apt-get install -y make gcc g++ automake autoconf openssl check git dirmngr pkg-config dh-autoreconf
    elif cmdExists 'dnf'; then
        dnf install -y make gcc gcc-c++ automake autoconf openssl check git perl-core
    elif cmdExists 'yum'; then
        yum install -y make gcc gcc-c++ automake autoconf openssl check git perl-core
    fi

    if (( $? != 0 )); then
        printwarn "SipSak install failed.. continuing without it"
        return 0
    fi

    NPROC=$(nproc)

    # Install cpanm and perl deps (faster than cpan)
    curl -L http://cpanmin.us | perl - --self-upgrade
    cpanm URI::Escape

    # compile and install from src
    if [[ ! -d ${SRC_DIR}/sipsak ]]; then
        git clone https://github.com/nils-ohlmeier/sipsak.git ${SRC_DIR}/sipsak
    fi
    (
        cd ${SRC_DIR}/sipsak &&
        autoreconf -i &&
        ./configure &&
        make -j $NPROC &&
        make -j $NPROC install &&
        exit 0 || exit 1
    )

    if (( $? == 0 )); then
        pprint "SipSak was installed"
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.sipsakinstalled
    else
        printwarn "SipSak install failed.. continuing without it"
    fi
}

# Remove Sipsak from the machine completely
function uninstallSipsak() {
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
# - used by kamailio dmq replication
function installDnsmasq() {
    if [ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled" ]; then
        printwarn "DNSmasq is already installed"
        return
    fi

    # create dnsmasq user and group
    # output removed, some cloud providers (DO) use caching and output is misleading
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel dnsmasq &>/dev/null; groupdel dnsmasq &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "DNSmasq DNS Resolver" dnsmasq &>/dev/null

    printdbg "Attempting to install DNSmasq..."
    if (( ${DISTRO_VER} == 12 )); then
        ${DSIP_PROJECT_DIR}/dnsmasq/${DISTRO}/${DISTRO_VER}.sh install
    else
        ${DSIP_PROJECT_DIR}/dnsmasq/${DISTRO}/install.sh install
    fi

    if (( $? != 0 )); then
        printerr "DNSmasq install failed - OS install script failure"
        exit 1
    fi

    # make sure run dir is created with correct permissions
    updatePermissions -dnsmasq

    # setup hosts in cluster node is resolvable
    # cron and kam service will configure these dynamically
    if grep -q 'DSIP_CONFIG_START' /etc/hosts 2>/dev/null; then
        perl -e "\$int_ip='${INTERNAL_IP_ADDR}'; \$ext_ip='${EXTERNAL_IP_ADDR}'; \$int_fqdn='${INTERNAL_FQDN}'; \$ext_fqdn='${EXTERNAL_FQDN}';" \
            -0777 -i -pe 's|(#+DSIP_CONFIG_START).*?(#+DSIP_CONFIG_END)|\1\n${int_ip} ${int_fqdn} local.cluster\n${ext_ip} ${ext_fqdn} local.cluster\n\2|gms' /etc/hosts
    else
        printf '\n%s\n%s\n%s\n%s\n' \
            '#####DSIP_CONFIG_START' \
            "${INTERNAL_IP_ADDR} ${INTERNAL_FQDN} local.cluster" \
            "${EXTERNAL_IP_ADDR} ${EXTERNAL_FQDN} local.cluster" \
            '#####DSIP_CONFIG_END' >>/etc/hosts
    fi

    # update DNS hosts prior to dSIPRouter startup
    addInitCmd "/usr/bin/dsiprouter updatednsconfig"
    # update DNS hosts every minute
    if ! crontab -l 2>/dev/null | grep -q "/usr/bin/dsiprouter updatednsconfig"; then
        cronAppend "0 * * * * /usr/bin/dsiprouter updatednsconfig"
    fi

    systemctl restart dnsmasq
    if systemctl is-active --quiet dnsmasq; then
        touch ${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled
        pprint "DNSmasq was installed"
    else
        printerr "DNSmasq install failed"
        exit 1
    fi

    return 0
}

function uninstallDnsmasq() {
    if [ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled" ]; then
        printwarn "DNSmasq is not installed or failed during install - uninstalling anyway to be safe"
    fi

    printdbg "Attempting to uninstall DNSmasq..."
    ${DSIP_PROJECT_DIR}/dnsmasq/${DISTRO}/install.sh uninstall

    if (( $? != 0 )); then
        printerr "DNSmasq uninstall failed - OS install script failure"
        exit 1
    fi

    # remove dnsmasq configuration
    rm -f /etc/dnsmasq.conf /etc/dnsmasq.conf.bak 2>/dev/null

    # remove localhost from name servers
    sed -ir -e '/#+DSIP_CONFIG_START/,/#+DSIP_CONFIG_END/d' /etc/dhcp/dhclient.conf
    sed -i -e '/nameserver 127.0.0.1/d' /etc/resolv.conf

    # remove cluster hosts from /etc/hosts
    sed -ir -e '/#+DSIP_CONFIG_START/,/#+DSIP_CONFIG_END/d' /etc/hosts

    # remove cron job and init command
    removeInitCmd "/usr/bin/dsiprouter updatednsconfig"
    cronRemove "/usr/bin/dsiprouter updatednsconfig"

    # Remove the hidden installed file, which denotes if it's installed or not
    rm -f ${DSIP_SYSTEM_CONFIG_DIR}/.dnsmasqinstalled
    printdbg "DNSmasq was uninstalled"

    return 0
}

function start() {
    local START_DSIPROUTER=${START_DSIPROUTER:-1}
    local START_KAMAILIO=${START_KAMAILIO:-0}
    local START_RTPENGINE=${START_RTPENGINE:-0}

    # Start Kamailio if told to and installed
    if (( $START_KAMAILIO == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled ]; then
        systemctl start kamailio
        # Make sure process is still running
        if ! systemctl is-active --quiet kamailio; then
            printerr "Unable to start Kamailio"
            exit 1
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
            exit 1
        else
            pprint "RTPEngine was started"
        fi
    fi

    # Start dSIPRouter if told to and installed
    if (( $START_DSIPROUTER == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled ]; then
        # update runtime settings from CLI args
        updateDsiprouterConfigRuntimeSettings

        if (( $DEBUG == 1 )); then
            # start the reverse proxy first
            systemctl start nginx
            # perform pre-startup commands systemd would normally do in dsiprouter.service
            updatePermissions -dsiprouter
            # keep dSIPRouter in the foreground, only used for debugging issues (blocking)
            sudo -u dsiprouter -g dsiprouter ${PYTHON_CMD} ${DSIP_PROJECT_DIR}/gui/dsiprouter.py
            exit $?
        else
            # start the reverse proxy first
            systemctl start nginx
            # normal startup, fork dSIPRouter as background process
            systemctl start dsiprouter
            # Make sure process is still running
            if ! systemctl is-active --quiet dsiprouter || ! systemctl is-active --quiet nginx; then
                printerr "Unable to start dSIPRouter"
                exit 1
            else
                pprint "dSIPRouter was started"
            fi
        fi
    fi
}

function stop() {
    local STOP_DSIPROUTER=${STOP_DSIPROUTER:-1}
    local STOP_KAMAILIO=${STOP_KAMAILIO:-0}
    local STOP_RTPENGINE=${STOP_RTPENGINE:-0}

    # Stop Kamailio if told to and installed
    if (( $STOP_KAMAILIO == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled ]; then
        systemctl stop kamailio
        # Make sure process is not running
        if systemctl is-active --quiet kamailio; then
            printerr "Unable to stop Kamailio"
            exit 1
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
            exit 1
        else
            pprint "RTPEngine was stopped"
        fi
    fi

    # Stop the dSIPRouter if told to and installed
    if (( $STOP_DSIPROUTER == 1 )) && [ -e ${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled ]; then
        systemctl stop nginx
        # if started in debug mode we have to manually kill the process
        if ! systemctl is-active --quiet dsiprouter; then
            pkill -SIGTERM -f dsiprouter.py
            if pgrep -f 'nginx|dsiprouter.py' &>/dev/null; then
                printerr "Unable to stop dSIPRouter"
                exit 1
            else
                pprint "dSIPRouter was stopped"
            fi
        else
            systemctl stop nginx
            systemctl stop dsiprouter
            if systemctl is-active --quiet dsiprouter || systemctl is-active --quiet nginx; then
                printerr "Unable to stop dSIPRouter"
                exit 1
            else
                pprint "dSIPRouter was stopped"
            fi
        fi
    fi
}

function restart() {
    # escape the systemd control group if told to daemonize
    if (( $RESTART_DAEMONIZE == 1 )); then
        systemd-run --unit='dsip-daemon' --collect --slice=user.slice $0 ${RESTART_ARGS[@]}
        exit 0
    fi

    stop
    start
}

function displayLoginInfo() {
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
    pprint "Domain Name: ${DSIP_PROTO}://${EXTERNAL_FQDN}:${DSIP_PORT}"
    if [ "$EXTERNAL_IP_ADDR" != "$INTERNAL_IP_ADDR" ];then
        pprint "External IP: ${DSIP_PROTO}://${EXTERNAL_IP_ADDR}:${DSIP_PORT}"
        pprint "Internal IP: ${DSIP_PROTO}://${INTERNAL_IP_ADDR}:${DSIP_PORT}"
    else
        pprint "IP Address: ${DSIP_PROTO}://${EXTERNAL_IP_ADDR}:${DSIP_PORT}"
    fi
    echo -ne '\n'

    printdbg "You can access the dSIPRouter REST API here"
    if [ "$EXTERNAL_IP_ADDR" != "$INTERNAL_IP_ADDR" ];then
        pprint "External IP: ${DSIP_API_PROTO}://${EXTERNAL_IP_ADDR}:${DSIP_PORT}"
        pprint "Internal IP: ${DSIP_API_PROTO}://${INTERNAL_IP_ADDR}:${DSIP_PORT}"
    else
        pprint "IP Address: ${DSIP_API_PROTO}://${EXTERNAL_IP_ADDR}:${DSIP_PORT}"
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

# updates credentials in dsip / kam config files / kam db
# also exports credentials to variables for latter commands
# note: updating KAM_DB_HOST will implicitly update ROOT_DB_HOST if not set
# TODO: currently there is no way to set values to the empty string
function setCredentials() {
    printdbg 'Setting credentials'

    # variables that can be set prior to running
    # SET_DSIP_GUI_USER
    # SET_DSIP_GUI_PASS
    # SET_DSIP_API_TOKEN
    # SET_DSIP_MAIL_USER
    # SET_DSIP_MAIL_PASS
    # SET_DSIP_IPC_TOKEN
    # SET_KAM_DB_USER
    # SET_KAM_DB_PASS
    # SET_KAM_DB_HOST
    # SET_KAM_DB_PORT
    # SET_KAM_DB_NAME
    # SET_ROOT_DB_USER
    # SET_ROOT_DB_PASS
    # SET_ROOT_DB_HOST
    # SET_ROOT_DB_PORT
    # SET_ROOT_DB_NAME
    # SET_DSIP_SESSION_KEY
    if [[ -z ${SET_ROOT_DB_HOST+unset} && -n ${SET_KAM_DB_HOST+set} ]]; then
        SET_ROOT_DB_HOST="$SET_KAM_DB_HOST"
    fi

    local LOAD_SETTINGS_FROM=${LOAD_SETTINGS_FROM:-$(getConfigAttrib 'LOAD_SETTINGS_FROM' ${DSIP_CONFIG_FILE})}
    local DSIP_ID=${DSIP_ID:-$(getConfigAttrib 'DSIP_ID' ${DSIP_CONFIG_FILE})}
    local DSIP_CLUSTER_ID=${DSIP_CLUSTER_ID:-$(getConfigAttrib 'DSIP_CLUSTER_ID' ${DSIP_CONFIG_FILE})}
    local DSIP_CLUSTER_SYNC=${DSIP_CLUSTER_SYNC:-$([[ "$(getConfigAttrib 'DSIP_CLUSTER_SYNC' ${DSIP_CONFIG_FILE})" == "True" ]] && echo '1' || echo '0')}
    # the commands to execute for these updates
    local SHELL_CMDS=() SQL_STATEMENTS=() DEFERRED_SQL_STATEMENTS=()
    # how settings will be propagated to live systems
    # 0 == no reload required, 1 == hot reload required, 2 == service reload required
    # note that parsing variables for higher numbered reloading should take precedence
    local DSIP_RELOAD_TYPE=1 KAM_RELOAD_TYPE=0 MYSQL_RELOAD_TYPE=0
    # whether or not we will be running logic to update settings on the DB
    local RUN_SQL_STATEMENTS=1
    local TMP_VAL

    # sanity check, can we connect to the DB as the root user?
    # we determine if user already changed DB creds (and just want dsiprouter to store them accordingly)
    if withGivenDB --user="$ROOT_DB_USER" --pass="$ROOT_DB_PASS" --host="$ROOT_DB_HOST" --port="$ROOT_DB_PORT" \
    mysql -e 'SELECT VERSION();' &>/dev/null; then
        :
    elif withGivenDB --user="${SET_ROOT_DB_USER:-$ROOT_DB_USER}" --pass="${SET_ROOT_DB_PASS:-$ROOT_DB_PASS}" \
    --host="${SET_ROOT_DB_HOST:-$ROOT_DB_HOST}" --port="${SET_ROOT_DB_PORT:-$ROOT_DB_PORT}" \
    --db="${SET_ROOT_DB_NAME:-$ROOT_DB_NAME}" mysql -e 'SELECT VERSION();' &>/dev/null; then
        ROOT_DB_HOST=${SET_ROOT_DB_HOST:-$ROOT_DB_HOST}
        ROOT_DB_PORT=${SET_ROOT_DB_PORT:-$ROOT_DB_PORT}
        ROOT_DB_USER=${SET_ROOT_DB_USER:-$ROOT_DB_USER}
        ROOT_DB_PASS=${SET_ROOT_DB_PASS:-$ROOT_DB_PASS}
        ROOT_DB_NAME=${SET_ROOT_DB_NAME:-$ROOT_DB_NAME}
    else
        # allow for updating settings prior to mysql being started but make sure it would be a valid update
        # no update that requires the DB access will work if we reached here so we validate or exit
        if [[ "$LOAD_SETTINGS_FROM" == "db" ]] ||
        [[ -n ${SET_KAM_DB_USER+set} ]] ||
        [[ -n ${SET_KAM_DB_PASS+set} ]] ||
        [[ -n ${SET_KAM_DB_HOST+set} ]] ||
        [[ -n ${SET_KAM_DB_PORT+set} ]] ||
        [[ -n ${SET_KAM_DB_NAME+set} ]] ||
        [[ -n ${SET_ROOT_DB_USER+set} ]] ||
        [[ -n ${SET_ROOT_DB_PASS+set} ]] ||
        [[ -n ${SET_ROOT_DB_HOST+set} ]] ||
        [[ -n ${SET_ROOT_DB_PORT+set} ]] ||
        [[ -n ${SET_ROOT_DB_NAME+set} ]]; then
            printerr 'Connection to DB failed'
            exit 1
        fi
        # no DB updates necessary
        RUN_SQL_STATEMENTS=0
    fi

    # update non-encrypted settings locally and gather statements for updating DB
    if [[ -n ${SET_DSIP_GUI_USER+set} ]]; then
        SQL_STATEMENTS+=("update kamailio.dsip_settings SET DSIP_USERNAME='$SET_DSIP_GUI_USER' WHERE DSIP_ID='$DSIP_ID';")
        if (( $DSIP_CLUSTER_SYNC == 1 )); then
            SQL_STATEMENTS+=("update kamailio.dsip_settings SET DSIP_USERNAME='$SET_DSIP_GUI_USER' WHERE DSIP_CLUSTER_ID='$DSIP_CLUSTER_ID' AND DSIP_CLUSTER_SYNC='1' AND DSIP_ID!='$DSIP_ID';")
        fi
        SHELL_CMDS+=("setConfigAttrib 'DSIP_USERNAME' '$SET_DSIP_GUI_USER' ${DSIP_CONFIG_FILE} -q;")
    fi
    if [[ -n ${SET_DSIP_GUI_PASS+set} ]]; then
        TMP_VAL=$(hashCreds "$SET_DSIP_GUI_PASS")
        SQL_STATEMENTS+=("update kamailio.dsip_settings SET DSIP_PASSWORD='$TMP_VAL' WHERE DSIP_ID='$DSIP_ID';")
        if (( $DSIP_CLUSTER_SYNC == 1 )); then
            SQL_STATEMENTS+=("update kamailio.dsip_settings SET DSIP_PASSWORD='$TMP_VAL' WHERE DSIP_CLUSTER_ID='$DSIP_CLUSTER_ID' AND DSIP_CLUSTER_SYNC='1' AND DSIP_ID!='$DSIP_ID';")
        fi
        SHELL_CMDS+=("setConfigAttrib 'DSIP_PASSWORD' '$TMP_VAL' ${DSIP_CONFIG_FILE} -qb;")
    fi

    if [[ -n ${SET_DSIP_MAIL_USER+set} ]]; then
        SQL_STATEMENTS+=("update kamailio.dsip_settings SET MAIL_USERNAME='$SET_DSIP_MAIL_USER' WHERE DSIP_ID='$DSIP_ID';")
        if (( $DSIP_CLUSTER_SYNC == 1 )); then
            SQL_STATEMENTS+=("update kamailio.dsip_settings SET MAIL_USERNAME='$SET_DSIP_MAIL_USER' WHERE DSIP_CLUSTER_ID='$DSIP_CLUSTER_ID' AND DSIP_CLUSTER_SYNC='1' AND DSIP_ID!='$DSIP_ID';")
        fi
        SHELL_CMDS+=("setConfigAttrib 'MAIL_USERNAME' '$SET_DSIP_MAIL_USER' ${DSIP_CONFIG_FILE} -q;")
    fi
    if [[ -n ${SET_DSIP_MAIL_PASS+set} ]]; then
        TMP_VAL=$(encryptCreds "$SET_DSIP_MAIL_PASS")
        SQL_STATEMENTS+=("update kamailio.dsip_settings SET MAIL_PASSWORD='$TMP_VAL' WHERE DSIP_ID='$DSIP_ID';")
        if (( $DSIP_CLUSTER_SYNC == 1 )); then
            SQL_STATEMENTS+=("update kamailio.dsip_settings SET MAIL_PASSWORD='$TMP_VAL' WHERE DSIP_CLUSTER_ID='$DSIP_CLUSTER_ID' AND DSIP_CLUSTER_SYNC='1' AND DSIP_ID!='$DSIP_ID';")
        fi
        SHELL_CMDS+=("setConfigAttrib 'MAIL_PASSWORD' '$TMP_VAL' ${DSIP_CONFIG_FILE} -q;")
    fi
    if [[ -n ${SET_DSIP_API_TOKEN+set} ]]; then
        TMP_VAL=$(encryptCreds "$SET_DSIP_API_TOKEN")
        SQL_STATEMENTS+=("update kamailio.dsip_settings SET DSIP_API_TOKEN='$TMP_VAL' WHERE DSIP_ID='$DSIP_ID';")
        if (( $DSIP_CLUSTER_SYNC == 1 )); then
            SQL_STATEMENTS+=("update kamailio.dsip_settings SET DSIP_API_TOKEN='$TMP_VAL' WHERE DSIP_CLUSTER_ID='$DSIP_CLUSTER_ID' AND DSIP_CLUSTER_SYNC='1' AND DSIP_ID!='$DSIP_ID';")
        fi
        SHELL_CMDS+=("setConfigAttrib 'DSIP_API_TOKEN' '$TMP_VAL' ${DSIP_CONFIG_FILE} -qb;")

        KAM_RELOAD_TYPE=1
    fi
    if [[ -n ${SET_DSIP_IPC_TOKEN+set} ]]; then
        TMP_VAL=$(encryptCreds "$SET_DSIP_IPC_TOKEN")
        SQL_STATEMENTS+=("update kamailio.dsip_settings SET DSIP_IPC_PASS='$TMP_VAL' WHERE DSIP_ID='$DSIP_ID';")
        if (( $DSIP_CLUSTER_SYNC == 1 )); then
            SQL_STATEMENTS+=("update kamailio.dsip_settings SET DSIP_IPC_PASS='$TMP_VAL' WHERE DSIP_CLUSTER_ID='$DSIP_CLUSTER_ID' AND DSIP_CLUSTER_SYNC='1' AND DSIP_ID!='$DSIP_ID';")
        fi
        SHELL_CMDS+=("setConfigAttrib 'DSIP_IPC_PASS' '$TMP_VAL' ${DSIP_CONFIG_FILE} -qb;")

        DSIP_RELOAD_TYPE=2
    fi
    if [[ -n ${SET_KAM_DB_USER+set} ]]; then
        DEFERRED_SQL_STATEMENTS+=("DROP USER IF EXISTS '$KAM_DB_USER'@'localhost';")
        DEFERRED_SQL_STATEMENTS+=("DROP USER IF EXISTS '$KAM_DB_USER'@'%';")
        DEFERRED_SQL_STATEMENTS+=("DROP USER IF EXISTS '$SET_KAM_DB_USER'@'localhost';")
        DEFERRED_SQL_STATEMENTS+=("DROP USER IF EXISTS '$SET_KAM_DB_USER'@'%';")
        DEFERRED_SQL_STATEMENTS+=("CREATE USER '$SET_KAM_DB_USER'@'localhost' IDENTIFIED BY '${SET_KAM_DB_PASS:-$KAM_DB_PASS}';")
        DEFERRED_SQL_STATEMENTS+=("GRANT ALL PRIVILEGES ON $KAM_DB_NAME.* TO '$SET_KAM_DB_USER'@'localhost';")
        DEFERRED_SQL_STATEMENTS+=("CREATE USER '$SET_KAM_DB_USER'@'%' IDENTIFIED BY '${SET_KAM_DB_PASS:-$KAM_DB_PASS}';")
        DEFERRED_SQL_STATEMENTS+=("GRANT ALL PRIVILEGES ON $KAM_DB_NAME.* TO '$SET_KAM_DB_USER'@'%';")

        SQL_STATEMENTS+=("UPDATE kamailio.dsip_settings SET KAM_DB_USER='$SET_KAM_DB_USER' WHERE DSIP_ID='$DSIP_ID';")
        if (( $DSIP_CLUSTER_SYNC == 1 )); then
            SQL_STATEMENTS+=("UPDATE kamailio.dsip_settings SET KAM_DB_USER='$SET_KAM_DB_USER' WHERE DSIP_CLUSTER_ID='$DSIP_CLUSTER_ID' AND DSIP_CLUSTER_SYNC='1' AND DSIP_ID!='$DSIP_ID';")
        fi
        SHELL_CMDS+=("setConfigAttrib 'KAM_DB_USER' '$SET_KAM_DB_USER' ${DSIP_CONFIG_FILE} -q;")

        DSIP_RELOAD_TYPE=2
        KAM_RELOAD_TYPE=2
    fi
    if [[ -n ${SET_KAM_DB_PASS+set} ]]; then
        DEFERRED_SQL_STATEMENTS+=("SET PASSWORD FOR '${SET_KAM_DB_USER:-$KAM_DB_USER}'@'localhost' = PASSWORD('$SET_KAM_DB_PASS');")
        DEFERRED_SQL_STATEMENTS+=("SET PASSWORD FOR '${SET_KAM_DB_USER:-$KAM_DB_USER}'@'%' = PASSWORD('$SET_KAM_DB_PASS');")

        TMP_VAL=$(encryptCreds "$SET_KAM_DB_PASS")
        SQL_STATEMENTS+=("update kamailio.dsip_settings SET KAM_DB_PASS='$TMP_VAL' WHERE DSIP_ID='$DSIP_ID';")
        if (( $DSIP_CLUSTER_SYNC == 1 )); then
            SQL_STATEMENTS+=("update kamailio.dsip_settings SET KAM_DB_PASS='$TMP_VAL' WHERE DSIP_CLUSTER_ID='$DSIP_CLUSTER_ID' AND DSIP_CLUSTER_SYNC='1' AND DSIP_ID!='$DSIP_ID';")
        fi
        SHELL_CMDS+=("setConfigAttrib 'KAM_DB_PASS' '$TMP_VAL' ${DSIP_CONFIG_FILE} -qb;")

        DSIP_RELOAD_TYPE=2
        KAM_RELOAD_TYPE=2
    fi
    # NOTE: since the host is required in the DB URI when parsing args we also check if it actually changed to determine if we need to run this logic
    if [[ -n ${SET_KAM_DB_HOST+set} ]]; then
        SHELL_CMDS+=("setConfigAttrib 'KAM_DB_HOST' '$SET_KAM_DB_HOST' ${DSIP_CONFIG_FILE} -q;")

        if [[ "${SET_KAM_DB_HOST}" != "${KAM_DB_HOST}" ]]; then
            reconfigureMysqlSystemdService
            MYSQL_RELOAD_TYPE=2
        fi

        DSIP_RELOAD_TYPE=2
        KAM_RELOAD_TYPE=2
    fi
    if [[ -n ${SET_KAM_DB_PORT+set} ]]; then
        SHELL_CMDS+=("setConfigAttrib 'KAM_DB_PORT' '$SET_KAM_DB_PORT' ${DSIP_CONFIG_FILE} -q;")

        DSIP_RELOAD_TYPE=2
        KAM_RELOAD_TYPE=2
    fi
    # TODO: allow changing live database name
    if [[ -n ${SET_KAM_DB_NAME+set} ]]; then
        SHELL_CMDS+=("setConfigAttrib 'KAM_DB_NAME' '$SET_KAM_DB_NAME' ${DSIP_CONFIG_FILE} -q;")

        DSIP_RELOAD_TYPE=2
        KAM_RELOAD_TYPE=2
    fi
    if [[ -n ${SET_ROOT_DB_USER+set} ]]; then
        DEFERRED_SQL_STATEMENTS+=("RENAME USER '${ROOT_DB_USER}'@'localhost' TO '${SET_ROOT_DB_USER}'@'localhost';")
        if checkDBUserExists "${ROOT_DB_USER}@%"; then
            DEFERRED_SQL_STATEMENTS+=("RENAME USER '${ROOT_DB_USER}'@'%' TO '${SET_ROOT_DB_USER}'@'localhost';")
        fi

        SHELL_CMDS+=("setConfigAttrib 'ROOT_DB_USER' '$SET_ROOT_DB_USER' ${DSIP_CONFIG_FILE} -q;")
    fi
    if [[ -n ${SET_ROOT_DB_PASS+set} ]]; then
        if [[ -n ${SET_ROOT_DB_USER+set} ]]; then
            DEFERRED_SQL_STATEMENTS+=("SET PASSWORD FOR '$SET_ROOT_DB_USER'@'localhost' = PASSWORD('$SET_ROOT_DB_PASS');")
            if checkDBUserExists "${SET_ROOT_DB_USER}@%"; then
                DEFERRED_SQL_STATEMENTS+=("SET PASSWORD FOR '$SET_ROOT_DB_USER'@'%' = PASSWORD('$SET_ROOT_DB_PASS');")
            fi
        else
            DEFERRED_SQL_STATEMENTS+=("SET PASSWORD FOR '$ROOT_DB_USER'@'localhost' = PASSWORD('$SET_ROOT_DB_PASS');")
            if checkDBUserExists "${ROOT_DB_USER}@%"; then
                DEFERRED_SQL_STATEMENTS+=("SET PASSWORD FOR '$ROOT_DB_USER'@'%' = PASSWORD('$SET_ROOT_DB_PASS');")
            fi
        fi

        TMP_VAL=$(encryptCreds "$SET_ROOT_DB_PASS")
        SHELL_CMDS+=("setConfigAttrib 'ROOT_DB_PASS' '$TMP_VAL' ${DSIP_CONFIG_FILE} -qb;")
    fi
    if [[ -n ${SET_ROOT_DB_HOST+set} ]]; then
        SHELL_CMDS+=("setConfigAttrib 'ROOT_DB_HOST' '$SET_ROOT_DB_HOST' ${DSIP_CONFIG_FILE} -q;")
    fi
    if [[ -n ${SET_ROOT_DB_PORT+set} ]]; then
        SHELL_CMDS+=("setConfigAttrib 'ROOT_DB_PORT' '$ROOT_KAM_DB_PORT' ${DSIP_CONFIG_FILE} -q;")
    fi
    if [[ -n ${SET_ROOT_DB_NAME+set} ]]; then
        SHELL_CMDS+=("setConfigAttrib 'ROOT_DB_NAME' '$SET_ROOT_DB_NAME' ${DSIP_CONFIG_FILE} -q;")
    fi
    if [[ -n ${SET_DSIP_SESSION_KEY+set} ]]; then
        TMP_VAL=$(encryptCreds "$SET_DSIP_SESSION_KEY")
        SHELL_CMDS+=("setConfigAttrib 'DSIP_SESSION_KEY' '$TMP_VAL' ${DSIP_CONFIG_FILE} -q;")

        DSIP_RELOAD_TYPE=2
    fi
    DEFERRED_SQL_STATEMENTS+=("flush privileges;")

    # allow settings that don't require DB to be running to be updated (we verified at the start of this func whether we needed DB)
    if (( ${RUN_SQL_STATEMENTS} == 1 )); then
        # update non-encrypted settings on DB
        sqlAsTransaction --user="$ROOT_DB_USER" --pass="$ROOT_DB_PASS" --host="$ROOT_DB_HOST" --port="$ROOT_DB_PORT" "${SQL_STATEMENTS[@]}"
        if (( $? != 0 )); then
            printerr 'Failed setting credentials on DB'
            exit 1
        fi

        # update live DB settings (DB user passwords, privileges, etc..)
        sqlAsTransaction --user="$ROOT_DB_USER" --pass="$ROOT_DB_PASS" --host="$ROOT_DB_HOST" --port="$ROOT_DB_PORT" "${DEFERRED_SQL_STATEMENTS[@]}"
        if (( $? != 0 )); then
            printerr 'Failed setting credentials on DB'
            exit 1
        fi
    fi

    # finally update the local config files
    eval "${SHELL_CMDS[@]}"

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
    export ROOT_DB_HOST=${SET_ROOT_DB_HOST:-$ROOT_DB_HOST}
    export ROOT_DB_PORT=${SET_ROOT_DB_PORT:-$ROOT_DB_PORT}
    export ROOT_DB_NAME=${SET_ROOT_DB_NAME:-$ROOT_DB_NAME}

    # reload/synchronize settings for each service
    # note: we reload the service only if it is currently running (otherwise it messes with boot ordering)
    # note: updateKamailioConfig() combines configuring kam config and hot reloading in the same function
    if (( ${MYSQL_RELOAD_TYPE} == 2 )); then
        if systemctl is-active --quiet mariadb; then
            systemctl restart mariadb
        fi
    fi
    if (( ${KAM_RELOAD_TYPE} > 0 )); then
        updateKamailioConfig
    fi
    if (( ${KAM_RELOAD_TYPE} == 2 )); then
        if systemctl is-active --quiet kamailio; then
            systemctl restart kamailio
        fi
    fi
    if (( ${DSIP_RELOAD_TYPE} == 1 )); then
        # synchronize settings (between local disk, DB, and cluster)
        systemctl kill -s SIGUSR1 dsiprouter
    elif (( ${DSIP_RELOAD_TYPE} == 2 )); then
        if systemctl is-active --quiet dsiprouter; then
            systemctl restart dsiprouter
        fi
    fi

    printdbg 'Credentials have been updated'
}

# update MOTD banner for ssh login
function updateBanner() {
    # don't write multiple times
    if [ -f /etc/update-motd.d/00-dsiprouter ]; then
        return
    fi

    # move old banner files
    mkdir -p /etc/update-motd.d
    cp -f /etc/motd ${BACKUPS_DIR}/motd.bak
    truncate -s 0 /etc/motd
    chmod -x /etc/update-motd.d/* 2>/dev/null

    # add our custom banner script (dynamically updates MOTD banner)
    (cat << EOF
#!/usr/bin/env bash

# redefine variables and functions here
ESC_SEQ="$ESC_SEQ"
ANSI_NONE="$ANSI_NONE"
ANSI_GREEN="$ANSI_GREEN"
GOOGLE_DNS_IPV4="$GOOGLE_DNS_IPV4"
GOOGLE_DNS_IPV6="$GOOGLE_DNS_IPV6"
IPV6_ENABLED=${IPV6_ENABLED:-0}
$(declare -f printdbg)
$(declare -f cmdExists)
$(declare -f getConfigAttrib)
$(declare -f displayLogo)
$(declare -f checkConn)
$(declare -f ipv4Test)
$(declare -f ipv6Test)
$(declare -f getInternalIP)
$(declare -f getExternalIP)

# updated variables on login
INTERNAL_IP_ADDR=\$(getInternalIP)
EXTERNAL_IP_ADDR=\$(getExternalIP)
if [[ -z "\$EXTERNAL_IP_ADDR" ]]; then
    EXTERNAL_IP_ADDR="\$INTERNAL_IP_ADDR"
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
printdbg "External IP: \${DSIP_GUI_PROTOCOL}://\${EXTERNAL_IP_ADDR}:\${DSIP_PORT}"
if [ "\$EXTERNAL_IP_ADDR" != "\$INTERNAL_IP_ADDR" ];then
    printdbg "Internal IP: \${DSIP_GUI_PROTOCOL}://\${INTERNAL_IP_ADDR}:\${DSIP_PORT}"
fi
printf '\n'

exit 0
EOF
    ) > /etc/update-motd.d/00-dsiprouter

    chmod +x /etc/update-motd.d/00-dsiprouter

    # debian-based distro's will update it automatically
    # for rhel-based distro's we simply update it via cronjob
    case "$DISTRO" in
        amzn|rhel|almalinux|rocky)
            /etc/update-motd.d/00-dsiprouter > /etc/motd
            if ! crontab -l | grep -q "/etc/update-motd.d/00-dsiprouter" 2>/dev/null; then
                cronAppend "*/5 * * * *  /etc/update-motd.d/00-dsiprouter >/etc/motd"
            fi
            ;;
    esac
}

# revert to old MOTD banner for ssh logins
function revertBanner() {
    mv -f ${BACKUPS_DIR}/motd.bak /etc/motd
    rm -f /etc/update-motd.d/00-dsiprouter
    chmod +x /etc/update-motd.d/* 2>/dev/null

    # remove cron entry for rhel-based distros
    case "$DISTRO" in
        amzn|rhel|almalinux|rocky)
            cronRemove '/etc/update-motd.d/00-dsiprouter'
            ;;
    esac
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
# TODO: replace this with a systemd target instead (dsip-init.target)
function createInitService() {
    # imported from dsip_lib.sh
    local DSIP_INIT_FILE="$DSIP_INIT_FILE"

    # only create if it doesn't exist
    if [[ -f "$DSIP_INIT_FILE" ]]; then
        printwarn "dsip-init service already exists"
        return
    else
        printdbg "creating dsip-init service"
    fi

    # configure cloud-init to work with alongside our init services
    if [[ -n "$CLOUD_PLATFORM" ]]; then
        cp -f ${DSIP_PROJECT_DIR}/cloud/cloud-init/configs/${CLOUD_PLATFORM}.cfg /etc/cloud/cloud.cfg.d/99-dsip-init.cfg
        cp -f ${DSIP_PROJECT_DIR}/cloud/cloud-init/templates/hosts.${DISTRO}.tmpl /etc/cloud/templates/hosts.tmpl

        # patch for cloud-init.service circular ordering dependency
        # TODO: commit this upstream to cloud-init project
        case "$DISTRO" in
            debian|ubuntu)
                perl -i -pe 's%(Before\=sysinit\.target)%#\1%' /lib/systemd/system/cloud-init.service
                systemctl daemon-reload
                ;;
        esac
    fi

    case "$DISTRO" in
        amzn|rhel|almalinux|rocky)
            # TODO: this should be moved to a separate install dir called syslog
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

    (cat << EOF
[Unit]
Description=dSIPRouter Init Service
DefaultDependencies=no
Requires=basic.target network.target
Wants=rsyslog.service mariadb.service dnsmasq.service nginx.service
After=network.target network-online.target systemd-journald.socket basic.target cloud-init.target
After=rsyslog.service mariadb.service dnsmasq.service nginx.service
Before=

[Service]
Type=oneshot
ExecStart=/usr/bin/true
RemainAfterExit=true
TimeoutSec=0

[Install]
WantedBy=multi-user.target
EOF
    ) > ${DSIP_INIT_FILE}

    # set default permissions
    chmod 0644 ${DSIP_INIT_FILE}

    # enable dsip-init service on boot
    systemctl daemon-reload
    systemctl enable dsip-init
}

function removeInitService() {
    # imported from dsip_lib.sh
    local DSIP_INIT_FILE="$DSIP_INIT_FILE"

    # remove our custom cloud-init configs
    rm -f /etc/cloud/cloud.cfg.d/99-dsip-init.cfg

    systemctl stop dsip-init
    systemctl disable dsip-init
    rm -f $DSIP_INIT_FILE
    systemctl daemon-reload

    printdbg "dsip-init service removed"
}

function upgrade() {
    local UPGRADE_VER CURRENT_VERSION UPGRADE_DEPENDS
    local REPO_URL=${UPGRADE_REPO:-"$GIT_REPO_URL"}
    REPO_URL=${REPO_URL:-https://github.com/dOpensource/dsiprouter.git}
    local TAG_NAME="${UPGRADE_RELEASE}-rel"
    export NEW_PROJECT_DIR=/tmp/dsiprouter
    export RUNNING_UPGRADE=1

    # make sure mask is reset to be more permissive
    # repo must be created with permissions set in the remote repo
    # and we want to keep permissions from backup files as well
    umask 022

    printdbg 'downloading new dSIPRouter project files'
    rm -rf "$NEW_PROJECT_DIR" 2>/dev/null
    git clone --depth 1 -c advice.detachedHead=false -b "$TAG_NAME" "$REPO_URL" "$NEW_PROJECT_DIR" || {
        printerr 'failed downloading new project files'
        exit 1
    }

    printdbg 'verifying version requirements'
    UPGRADE_VER=$(jq -r -e '.version' <"${NEW_PROJECT_DIR}/resources/upgrade/${UPGRADE_RELEASE}/settings.json")
    CURRENT_VERSION=$(getConfigAttrib "VERSION" "${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py")
    UPGRADE_DEPENDS=( $(jq -r -e '.depends[]' <"${NEW_PROJECT_DIR}/resources/upgrade/${UPGRADE_RELEASE}/settings.json") )
    (
        for VER in ${UPGRADE_DEPENDS[@]}; do
            if [[ "$CURRENT_VERSION" == "$VER" ]]; then
                exit 0
            fi
        done
        exit 1
    ) || {
        printerr "unsupported upgrade scenario ($CURRENT_VERSION -> $UPGRADE_VER)"
        exit 1
    }

    if (( $RUN_FROM_GUI == 0 )); then
        # check shared memory
        if [[ $(${PYTHON_CMD} -c "
import os
os.chdir('${DSIP_PROJECT_DIR}/gui')
from util.ipc import STATE_SHMEM_NAME, getSharedMemoryDict
print(getSharedMemoryDict(STATE_SHMEM_NAME)['core_license_status'])
        ") != "3" ]]; then
            printerr 'dSPIRouter core license is not valid'
            exit 1
        fi
    else
        # manually grab license status
        if [[ $(${PYTHON_CMD} -c "
import os, sys
os.chdir('${DSIP_PROJECT_DIR}/gui')
sys.path.insert(0, '${DSIP_SYSTEM_CONFIG_DIR}/gui')
from modules.api.licensemanager.functions import licenseToGlobalStateVariable
import settings
print(licenseToGlobalStateVariable(settings.DSIP_CORE_LICENSE))
        ") != "3" ]]; then
            printerr 'dSPIRouter core license is not valid'
            exit 1
        fi
    fi

    printdbg 'backing up configs just in case the upgrade fails'
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
    cp -af /etc/default/{kamailio,rtpengine}.conf ${CURR_BACKUP_DIR}/etc/default/
    printdbg "files were backed up here: ${CURR_BACKUP_DIR}/"

    printdbg "starting migration from $CURRENT_VERSION to $UPGRADE_VER"
    ${NEW_PROJECT_DIR}/resources/upgrade/${UPGRADE_RELEASE}/scripts/migrate.sh
    return $?
}

# TODO: deprecated code requiring review, marked for review in v0.80
#    DSIP_CLUSTER_ID=${DSIP_CLUSTER_ID:-$(getConfigAttrib 'DSIP_CLUSTER_ID' ${DSIP_CONFIG_FILE})}
#
#    CURRENT_RELEASE=$(getConfigAttrib 'VERSION' ${DSIP_CONFIG_FILE})
#
#    # Check if already upgraded
#    #rel = $((`echo "$CURRENT_RELEASE" == "$UPGRADE_RELEASE" | bc`))
#    #if [ $rel -eq 1 ]; then
#
#
#    #    pprint "dSIPRouter is already updated to $UPGRADE_RELEASE!"
#    #    return
#
#    #fi
#
#    # Return an error if the release doesn't exist
#   if ! git branch -a --format='%(refname:short)' | grep -qE "^${UPGRADE_RELEASE}\$" 2>/dev/null; then
#        printdbg "The $UPGRADE_RELEASE release doesn't exist. Please select another release"
#        return 1
#   fi
#
#    BACKUP_DIR="/var/backups"
#    CURR_BACKUP_DIR="${BACKUP_DIR}/$(date '+%Y-%m-%d')"
#    mkdir -p ${BACKUP_DIR} ${CURR_BACKUP_DIR}
#    mkdir -p ${CURR_BACKUP_DIR}/{etc,var/lib,${HOME},$(dirname "$DSIP_PROJECT_DIR")}
#
#    cp -r ${DSIP_PROJECT_DIR} ${CURR_BACKUP_DIR}/${DSIP_PROJECT_DIR}
#    cp -r ${SYSTEM_KAMAILIO_CONFIG_DIR} ${CURR_BACKUP_DIR}/${SYSTEM_KAMAILIO_CONFIG_DIR}
#
#    #Stash any changes so that GUI will allow us to pull down a new release
#    #git stash
#    #git checkout $UPGRADE_RELEASE
#    #git stash apply
#
#    generateKamailioConfig
#    updateKamailioConfig
#    updateKamailioStartup
#
#    if (( $? == 0 )); then
#        # Upgrade the version
#       setConfigAttrib 'VERSION' "$UPGRADE_RELEASE" ${DSIP_CONFIG_FILE} -q
#
#        # Restart Kamailio
#        systemctl restart kamailio
#        systemctl restart dsiprouter
#    fi

# TODO: this is unfinished
#function upgradeOld {
#    # TODO: set / handle parsed args
#    UPGRADE_RELEASE="v0.51"
#
#    BACKUP_DIR="/var/backups"
#    CURR_BACKUP_DIR="${BACKUP_DIR}/$(date '+%Y-%m-%d')"
#    mkdir -p ${BACKUP_DIR} ${CURR_BACKUP_DIR}
#    mkdir -p ${CURR_BACKUP_DIR}/{etc,var/lib,${HOME},$(dirname "$DSIP_PROJECT_DIR")}
#
#    # TODO: more cross platform / cloud RDBMS friendly dump, such as the following:
##    VIEWS=$(mysql --skip-column-names --batch -D information_schema -e 'select table_name from tables where table_schema="kamailio" and table_type="VIEW"' | perl -0777 -pe 's/\n(?!\Z)/|/g')
##    mysqldump -B kamailio --routines --triggers --hex-blob | sed -e 's|DEFINER=`[a-z0-9A-Z]*`@`[a-z0-9A-Z]*`||g' | perl -0777 -pe 's|(CREATE TABLE `?(?:'"${VIEWS}"')`?.*?)ENGINE=\w+|\1|sgm' > kamdump.sql
#
#    mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges \
#        --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$ROOT_DB_HOST" --port="$ROOT_DB_PORT" > ${CURR_BACKUP_DIR}/mysql_full.sql
#    mysqldump --single-transaction --skip-triggers --skip-add-drop-table --insert-ignore \
#        --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$ROOT_DB_HOST" --port="$ROOT_DB_PORT" ${KAM_DB_NAME} \
#        | perl -0777 -pi -e 's/CREATE TABLE (`(.+?)`.+?;)/CREATE TABLE IF NOT EXISTS \1\n\nTRUNCATE TABLE `\2`;\n/gs' \
#        > ${CURR_BACKUP_DIR}/kamdb_merge.sql
#
#    systemctl stop rtpengine
#    systemctl stop kamailio
#    systemctl stop dsiprouter
#    systemctl stop mariadb
#
#    mv -f ${DSIP_PROJECT_DIR} ${CURR_BACKUP_DIR}/${DSIP_PROJECT_DIR}
#    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR} ${CURR_BACKUP_DIR}/${SYSTEM_KAMAILIO_CONFIG_DIR}
#    # in case mysqldumps failed silently, backup mysql binary data
#    mv -f /var/lib/mysql ${CURR_BACKUP_DIR}/var/lib/
#    cp -f /etc/my.cnf* ${CURR_BACKUP_DIR}/etc/
#    cp -rf /etc/my.cnf* ${CURR_BACKUP_DIR}/etc/
#    cp -rf /etc/mysql ${CURR_BACKUP_DIR}/etc/
#    cp -f ${HOME}/.my.cnf* ${CURR_BACKUP_DIR}/${HOME}/
#
#    iptables-save > ${CURR_BACKUP_DIR}/iptables.dump
#    ip6tables-save > ${CURR_BACKUP_DIR}/ip6tables.dump
#
#    git clone https://github.com/dOpensource/dsiprouter.git --branch="$UPGRADE_RELEASE" ${DSIP_PROJECT_DIR}
#    cd ${DSIP_PROJECT_DIR}
#
#    # TODO: figure out what settings they installed with previously
#    # or we can simply store them in a text file (./installed)
#    # after a succesfull install completes
#    ./dsiprouter.sh uninstall
#    ./dsiprouter.sh install
#
#    mysql --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$ROOT_DB_HOST" --port="$ROOT_DB_PORT" ${KAM_DB_NAME} < ${CURR_BACKUP_DIR}/kamdb_merge.sql
#
#    # TODO: fix any conflicts that would arise from our new modules / tables in KAMDB
#
#    # TODO: print backup location info to user
#
#    # TODO: transfer / merge backup configs to new configs
#    # kam configs
#    # dsip configs
#    # iptables configs
#    # mysql configs
#
#    # TODO: restart services, check for good startup
#}

# TODO: add bash cmd completion for new options provided by gitwrapper.sh
# TODO: move installing of testing dependencies here
function configGitDevEnv() {
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

function cleanGitDevEnv() {
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
#       or we could check for install and decrypt/store creds before replacing key and re-encrypting
# TODO: add support for calling various cluster scripts in HA directory
# TODO: on new cluster install the 2nd / tertiary DBs don't exist when updating dsip_settings, so the credentials don't match
#       kamailio db settings should not be synced in cluster sync mode (since config settings are stored there it would break the cluster)
# TODO: handle re-running cluster install after failure (must reset GUI pass and probably should reset configs)
function clusterInstall() { (
    local i j
    local USER PASS HOST PORT SSH_REMOTE_HOST
    local CLUSTER_GUI_USER CLUSTER_GUI_PASS CLUSTER_API_TOKEN CLUSTER_MAIL_USER CLUSTER_MAIL_PASS CLUSTER_IPC_TOKEN
    local CLUSTER_KAM_DB_USER CLUSTER_KAM_DB_PASS CLUSTER_KAM_DB_NAME CLUSTER_ROOT_DB_USER CLUSTER_ROOT_DB_PASS CLUSTER_ROOT_DB_NAME
    local SSH_CMD=() RSYNC_CMD=()
    local TMP_PRIV_KEY="/tmp/dsip_privkey"
    local CLUSTER_SYNC=0
    # default ssh options
    local SSH_OPTS=(-o StrictHostKeyChecking=no -o CheckHostIp=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=5 -o ServerAliveCountMax=2 -x)
    local RSYNC_OPTS=()
    # allow local project to be located anywhere
    local LOCAL_PROJECT_DIR="$DSIP_PROJECT_DIR"
    DSIP_PROJECT_DIR="/opt/dsiprouter"

    if ! cmdExists 'ssh' || ! cmdExists 'rsync' || ! cmdExists 'sshpass'; then
        printdbg 'Installing local requirements for cluster install'
        if cmdExists 'apt-get'; then
            sudo apt-get install -y openssh-client sshpass rsync
        elif cmdExists 'dnf'; then
            sudo dnf install --enablerepo=epel -y openssh-clients sshpass rsync
        elif cmdExists 'yum'; then
            sudo yum install --enablerepo=epel -y openssh-clients sshpass rsync
        else
            printerr "Your local OS is currently not supported"
            exit 1
        fi
    fi

    # sanity check
    if (( $? != 0 )); then
        printerr 'Could not install requirements for cluster install'
        exit 1
    fi

    # we need to know if cluster sync will be enabled beforehand
    j=0
    while (( $j < ${#SSH_SYNC_ARGS[@]} )); do
        case "${SSH_SYNC_ARGS[$j]}" in
            -dsipcsync|--dsip-clustersync=*)
                if grep -q '=' 2>/dev/null <<<"${SSH_SYNC_ARGS[$j]}"; then
                    CLUSTER_SYNC=$(cut -d '=' -f 2 <<<"${SSH_SYNC_ARGS[$j]}")
                else
                    CLUSTER_SYNC="${SSH_SYNC_ARGS[$((j + 1))]}"
                fi
                break
                ;;
        esac
        j=$((j + 1))
    done

    # if installing in cluster sync mode GUI pass must generate it beforehand (can't undo the hash later)
    # can still be overwritten by user provided args (probably not wise though)
    if (( $CLUSTER_SYNC == 1 )); then
        CLUSTER_GUI_PASS=$(urandomChars 64)
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
    i=0
    while (( $i < ${#SSH_SYNC_NODES[@]} )); do
        # parse node info
        USER=$(printf '%s' "${SSH_SYNC_NODES[$i]}" | cut -s -d '@' -f -1 | cut -d ':' -f -1)
        PASS=$(printf '%s' "${SSH_SYNC_NODES[$i]}" | cut -s -d '@' -f -1 | cut -s -d ':' -f 2-)
        HOST=$(printf '%s' "${SSH_SYNC_NODES[$i]}" | cut -d '@' -f 2- | cut -d ':' -f -1)
        PORT=$(printf '%s' "${SSH_SYNC_NODES[$i]}" | cut -d '@' -f 2- | cut -s -d ':' -f 2-)

        # default user is root for ssh
        USER=${USER:-root}
        # default port is 22 for ssh
        PORT=${PORT:-22}
        # host is required per node
        if [[ -z "$HOST" ]]; then
            printerr "Node [${SSH_SYNC_NODES[$i]}] does not contain a host"
            usageOptions
            exit 1
        fi
        SSH_REMOTE_HOST="${USER}@${HOST}"

        # select auth method and set vars accordingly
        if [[ -n "$PASS" ]]; then
            export SSHPASS="${PASS}"
            SSH_CMD=(sshpass -e ssh)
            RSYNC_CMD=(sshpass -e rsync)
            SSH_OPTS+=(-o PreferredAuthentications=password)
        else
            SSH_CMD=(ssh)
            RSYNC_CMD=(rsync)
            if [[ -n "$SSH_KEY_FILE" ]]; then
                SSH_OPTS+=(-o PreferredAuthentications=publickey -i $SSH_KEY_FILE)
            else
                SSH_OPTS+=(-o PreferredAuthentications=publickey)
            fi
        fi

        # finalize options
        RSYNC_OPTS+=(--port=${PORT} -z --exclude=".*")
        SSH_OPTS+=(-p ${PORT})

#        printdbg "Validating tcp connection to ${HOST}"
#        if ! checkConn ${HOST} ${PORT}; then
#            printerr "Could not establish connection to host [${HOST}] on port [${PORT}]"
#            exit 1
#        fi

        printdbg "Validating unattended ssh connection to ${HOST}"
        if ! checkSSH ${SSH_CMD[@]} ${SSH_OPTS[@]} ${SSH_REMOTE_HOST}; then
            printerr "Could not establish unattended ssh connection to [${SSH_REMOTE_HOST}] on port [${PORT}]"
            exit 1
        fi

        printdbg "Installing remote requirements for cluster install"
        ${SSH_CMD[@]} ${SSH_OPTS[@]} ${SSH_REMOTE_HOST} bash 2>&1 <<- EOSSH
            $(typeset -f cmdExists)

            if cmdExists 'apt-get'; then
                apt-get install -y rsync
            elif cmdExists 'dnf'; then
                dnf install -y rsync
            elif cmdExists 'yum'; then
                yum install -y rsync
            else
                exit 1
            fi
            exit 0
EOSSH

        if (( $? != 0 )); then
            printerr "Failed installing requirements on remote node ${HOST_LIST[$i]}"
            exit 1
        fi

        printdbg "Starting remote install on ${HOST}"
        # password used by ssh/scp
        if [[ -n "$PASS" ]]; then
            export SSHPASS="$PASS"
        fi

        printdbg "Copying project files to ${HOST}"
        ${RSYNC_CMD[@]} ${RSYNC_OPTS[@]} --rsh="ssh ${SSH_OPTS[*]} -o IPQoS=throughput" -a ${LOCAL_PROJECT_DIR}/ ${SSH_REMOTE_HOST}:/tmp/dsiprouter/ 2>&1 &&
        ${RSYNC_CMD[@]} ${RSYNC_OPTS[@]} --rsh="ssh ${SSH_OPTS[*]} -o IPQoS=throughput" ${TMP_PRIV_KEY} ${SSH_REMOTE_HOST}:${TMP_PRIV_KEY} 2>&1
        if (( $? != 0 )); then
            printerr "Copying files to ${HOST} failed"
            exit 1
        fi

        printdbg "Running remote install on ${HOST}"
        ${SSH_CMD[@]} ${SSH_OPTS[@]} ${SSH_REMOTE_HOST} bash 2>&1 <<- EOSSH
            # debug the remote commands
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

            # export any settings we wish to change in the install script
            export SET_DSIP_GUI_USER="$CLUSTER_GUI_USER"
            export SET_DSIP_GUI_PASS="$CLUSTER_GUI_PASS"
            export SET_DSIP_API_TOKEN="$CLUSTER_API_TOKEN"
            export SET_DSIP_MAIL_USER="$CLUSTER_MAIL_USER"
            export SET_DSIP_MAIL_PASS="$CLUSTER_MAIL_PASS"
            export SET_DSIP_IPC_TOKEN="$CLUSTER_IPC_TOKEN"
            export SET_KAM_DB_USER="$CLUSTER_KAM_DB_USER"
            export SET_KAM_DB_PASS="$CLUSTER_KAM_DB_PASS"
            export SET_KAM_DB_NAME="$CLUSTER_KAM_DB_NAME"
            export SET_ROOT_DB_USER="$CLUSTER_ROOT_DB_USER"
            export SET_ROOT_DB_PASS="$CLUSTER_ROOT_DB_PASS"
            export SET_ROOT_DB_NAME="$CLUSTER_ROOT_DB_NAME"

            # run script command
            ${DSIP_PROJECT_DIR}/dsiprouter.sh install ${SSH_SYNC_ARGS[@]}
EOSSH

        # sanity check, was the install script successful?
        if (( $? != 0 )); then
            printerr "Remote install on ${HOST} failed (install script failed)"
            exit 1
        fi

        # if installing in cluster sync mode reuse the credentials set on the first node
        # can still be overwritten by user provided args (probably not wise though)
        if (( $i == 0 )) && (( $CLUSTER_SYNC == 1 )); then
            . <(
                ${SSH_CMD[@]} ${SSH_OPTS[@]} ${SSH_REMOTE_HOST} bash 2>/dev/null <<- EOSSH
                    DSIP_PROJECT_DIR="$DSIP_PROJECT_DIR"
                    DSIP_SYSTEM_CONFIG_DIR="$DSIP_SYSTEM_CONFIG_DIR"
                    $(typeset -f getConfigAttrib)
                    $(typeset -f decryptConfigAttrib)
                    echo "CLUSTER_GUI_USER='\$(getConfigAttrib DSIP_USERNAME ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_API_TOKEN='\$(decryptConfigAttrib DSIP_API_TOKEN ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_MAIL_USER='\$(getConfigAttrib MAIL_USERNAME ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_MAIL_PASS='\$(decryptConfigAttrib MAIL_PASSWORD ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_IPC_TOKEN='\$(decryptConfigAttrib DSIP_IPC_PASS ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_KAM_DB_USER='\$(getConfigAttrib KAM_DB_USER ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_KAM_DB_PASS='\$(decryptConfigAttrib KAM_DB_PASS ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_KAM_DB_NAME='\$(getConfigAttrib KAM_DB_NAME ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_ROOT_DB_USER='\$(getConfigAttrib ROOT_DB_USER ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_ROOT_DB_PASS='\$(decryptConfigAttrib ROOT_DB_PASS ${DSIP_CONFIG_FILE})'"
                    echo "CLUSTER_ROOT_DB_NAME='\$(getConfigAttrib ROOT_DB_NAME ${DSIP_CONFIG_FILE})'"
EOSSH
            )

            # sanity check, were we able to get the settings from the remote node?
            if [[ -z "$CLUSTER_GUI_USER$CLUSTER_API_TOKEN" ]]; then
                printerr "Remote install on ${HOST} failed (could not get cluster credentials)"
                exit 1
            fi
        fi

        i=$((i + 1))
    done
); exit $?; }

# $@ == subset of permissions to update
# TODO: update systemd ExecStartPre commands to use this logic instead
function updatePermissions() {
    local OPT=""

    # set permissions on the X509 certs used by dsiprouter and kamailio
    # [special use case]: testing kamailio service startup
    # in this case kamailio needs access before dsiprouter user is created
    setCertPerms() {
        if id -u dsiprouter &>/dev/null; then
            # dsiprouter needs to have control over the certs to allow changes
            # note that nginx should never have write access
            chown -R dsiprouter:kamailio ${DSIP_CERTS_DIR}
        else
            # dsiprouter user does not yet exist so make sure kamailio user has access
            chown -R root:kamailio ${DSIP_CERTS_DIR}
        fi
        find ${DSIP_CERTS_DIR}/ -type f -exec chmod 640 {} +
    }
    # set permissions for files/dirs used by dnsmasq
    setDnsmasqPerms() {
        mkdir -p /run/dnsmasq
        chown -R dnsmasq:dnsmasq /run/dnsmasq
        chown dnsmasq:root /run/dnsmasq
        chmod 771 /run/dnsmasq
    }
    # set permissions for files/dirs used by nginx
    setNginxPerms() {
        mkdir -p /run/nginx
        chown -R nginx:nginx /run/nginx
        chown nginx:root /run/nginx
        chmod 771 /run/nginx
    }
    # set permissions for files/dirs used by kamailio
    setKamailioPerms() {
        mkdir -p /run/kamailio
        chown -R kamailio:kamailio /run/kamailio
        chown kamailio:root /run/kamailio
        chmod 771 /run/kamailio

        # dsiprouter needs to have control over the kamailio dir
        # this allows dsiprouter to update kamailio dynamically
        # kamailio configs will contain plaintext passwords / tokens
        # in the case where the dsiprouter user does not yet exist we set stricter permissions
        if id -u dsiprouter &>/dev/null; then
            chown -R dsiprouter:kamailio ${DSIP_SYSTEM_CONFIG_DIR}/kamailio/
        else
            chown -R root:kamailio ${DSIP_SYSTEM_CONFIG_DIR}/kamailio/
        fi
        find ${DSIP_SYSTEM_CONFIG_DIR}/kamailio/ -type f -exec chmod 640 {} +
    }
    # set permissions for files/dirs used by dsiprouter
    setDsiprouterPerms() {
        mkdir -p ${DSIP_RUN_DIR}
        chown -R dsiprouter:dsiprouter ${DSIP_RUN_DIR}
        chown dsiprouter:root ${DSIP_RUN_DIR}
        chmod 771 ${DSIP_RUN_DIR}

        # dsiprouter user is the only one making backups
        chown -R dsiprouter:root ${BACKUPS_DIR}
        # dsiprouter private key only readable by dsiprouter
        chown dsiprouter:root ${DSIP_PRIV_KEY}
        chmod 400 ${DSIP_PRIV_KEY}
        # dsiprouter gui files readable and writable only by dsiprouter
        chown -R dsiprouter:root ${DSIP_SYSTEM_CONFIG_DIR}/gui/
        find ${DSIP_SYSTEM_CONFIG_DIR}/gui/ -type f -exec chmod 600 {} +

        # files that should be executable
        chmod +x ${DSIP_PROJECT_DIR}/dsiprouter.sh
        chmod +x ${DSIP_PROJECT_DIR}/resources/upgrade/*/scripts/migrate.sh
    }
    # set permissions for files/dirs used by rtpengine
    setRtpenginePerms() {
        mkdir -p /run/rtpengine
        chown -R rtpengine:rtpengine /run/rtpengine
        chown rtpengine:root /run/rtpengine
        chmod 771 /run/rtpengine
    }

    # no args given set permissions for all services
    if (( $# == 0 )); then
        setDnsmasqPerms
        setNginxPerms
        setKamailioPerms
        setDsiprouterPerms
        setRtpenginePerms
        setCertPerms
        return 0
    fi

    # parse args and select subset of permissions to set
    while (( $# > 0 )); do
        OPT="$1"
        shift
        case "$OPT" in
            -certs)
                setCertPerms
                ;;
            -dnsmasq)
                setDnsmasqPerms
                ;;
            -nginx)
                setNginxPerms
                ;;
            -kamailio)
                setKamailioPerms
                ;;
            -dsiprouter)
                setDsiprouterPerms
                ;;
            -rtpengine)
                setRtpenginePerms
                ;;
            *)
                printerr "$0(): Invalid argument [$ARG]"
                return 1
                ;;
        esac
    done

    return 0
}
export -f updatePermissions

# really only useful on systems with limited RAM (where we usually test)
function createSwapFile() {
    local SWAP_FILE="${DSIP_LIB_DIR}/swap"

    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.memupdatescomplete" ]]; then
        return
    fi

    # only create if system has less than 2GB RAM and no existing swap files
    if (( $(awk '/^MemTotal/ {print int($2/1000000)}' /proc/meminfo) < 2 )) && [[ -z "$(swapon --show=SIZE --noheadings)" ]]; then
        printdbg 'memory constraints require swapfile, creating now..'

        # 1GB of swap space
        dd if=/dev/zero of=${SWAP_FILE} bs=64M count=16 &&
        chmod 600 ${SWAP_FILE} &&
        mkswap ${SWAP_FILE} &&
        swapon ${SWAP_FILE} &&
        echo "${SWAP_FILE} none swap sw 0 0" >>/etc/fstab &&
        printdbg 'swapfile created successfully'
    fi

    touch "${DSIP_SYSTEM_CONFIG_DIR}/.memupdatescomplete"
}

function removeSwapFile() {
    local SWAP_FILE="${DSIP_LIB_DIR}/swap"

    if [[ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.memupdatescomplete" ]]; then
        return
    fi
    if [[ ! -e "$SWAP_FILE" ]]; then
        return
    fi

    swapoff ${SWAP_FILE} &&
    echo perl -i -pe "s%^${SWAP_FILE}[ \t].*\n%%" /etc/fstab &&
    printdbg 'swapfile removed'

    rm -f "${DSIP_SYSTEM_CONFIG_DIR}/.memupdatescomplete"
}

function usageOptions() {
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
    printf "%-30s %s\n%-30s %s\n%-30s %s\n%-30s %s\n%-30s %s\n" \
        "install" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine|" \
        " " "-dmz <pub iface>,<priv iface>|--dmz=<pub iface>,<priv iface>|-netm <mode>|--network-mode=<mode>|-homer <homerhost[:heplifyport]>|" \
        " " "-db <[user[:pass]@]dbhost[:port][/dbname]>|--database=<[user[:pass]@]dbhost[:port][/dbname]>|-dsipcid <num>|--dsip-clusterid=<num>|" \
        " " "-dbadmin <[user[:pass]@]dbhost[:port][/dbname]>|--database-admin=<[user[:pass]@]dbhost[:port][/dbname]>|-dsipcsync <num>|" \
        " " "--dsip-clustersync=<num>|-dsipkey <32 chars>|--dsip-privkey=<32 chars>|-with_lcr|--with_lcr=<num>|-with_dev|--with_dev=<num>]"
    printf "%-30s %s\n" \
        "uninstall" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine]"
    printf "%-30s %s\n" \
        "clusterinstall" "[-debug] [-i <ssh key file>] <[user1[:pass1]@]node1[:port1]> <[user2[:pass2]@]node2[:port2]> ... -- [INSTALL OPTIONS]"
    printf "%-30s %s\n" \
        "upgrade" "[-debug|-dsipcid <num>|--dsip-clusterid=<num>|-url <repo url>|--repo-url=<repo url>] <-rel <release number>|--release=<release number>>"
    printf "%-30s %s\n" \
        "start" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine]"
    printf "%-30s %s\n" \
        "stop" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine]"
    printf "%-30s %s\n" \
        "restart" "[-debug|-all|--all|-kam|--kamailio|-dsip|--dsiprouter|-rtp|--rtpengine]"
    printf "%-30s %s\n" \
        "chown" "[-debug|-certs|-dnsmasq|-nginx|-kamailio|-dsiprouter|-rtpengine]"
    printf "%-30s %s\n" \
        "configurekam" "[-debug]"
    printf "%-30s %s\n" \
        "configuredsip" "[-debug]"
    printf "%-30s %s\n" \
        "renewsslcert" "[-debug]"
    printf "%-30s %s\n" \
        "configuresslcert" "[-debug|-f|--force]"
    printf "%-30s %s\n" \
        "installmodules" "[-debug]"
    printf "%-30s %s\n" \
        "resetpassword" "[-debug|-q|--quiet|-all|--all|-dc|--dsip-creds|-ac|--api-creds|-kc|--kam-creds|-ic|--ipc-creds|-fid|--force-instance-id]"
    printf "%-30s %s\n%-30s %s\n%-30s %s\n%-30s %s\n%-30s %s\n" \
        "setcredentials" "[-debug|-dc <[user][:pass]>|--dsip-creds=<[user][:pass]>|-ac <token>|--api-creds=<token>|" \
        " " "-kc <[user[:pass]@]dbhost[:port][/dbname]>|--kam-creds=<[user[:pass]@]dbhost[:port][/dbname]>|" \
        " " "-mc <[user][:pass]>|--mail-creds=<[user][:pass]>|-ic <token>|--ipc-creds=<token>]|" \
        " " "-dac <[user[:pass]@]dbhost[:port][/dbname]>|--db-admin-creds=<[user[:pass]@]dbhost[:port][/dbname]>|" \
        " " "-sc <key>|--session-creds=<key>]"
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
        "This script is used for installing, uninstalling, managing, and configuring dSIPRouter and the various services it manages." \
        "That includes starting/stopping/executing the Web GUI, manaing the Nginx reverse proxy, managing Kamailio, manaing RTPEngine and much more." \
        "This script can also be used to sync service settings with dSIPRouter, install new modules, renew TLS certs, and configure a cluster."

    linebreak
    printf '\n%s\n%s\n%s\n%s\n%s\n\n' \
        "$(pprint -n MORE INFO:)" \
        "The full documentation available locally on your system: ${DSIP_PROTO}://${EXTERNAL_FQDN}:${DSIP_PORT}/docs/index.html" \
        "We also provide the documentation online for your convenience: https://dsiprouter.readthedocs.io" \
        "Drop by the project website for the latest information on the project: https://dsiprouter.org/" \
        "Support is available from dOpenSource. Visit us at https://dopensource.com/dsiprouter or call us at 888-907-2085"

    linebreak
    printf '\n%s\n%s\n%s\n\n' \
        "$(pprint -n PROVIDED BY:)" \
        "dOpenSource | A Flyball Company" \
        "Made in Detroit, MI USA"

    linebreak
}

# make the output a little cleaner
function setVerbosityLevel() {
#    if [[ "$*" != *"-debug"* ]]; then
#        # quiet pkg managers when not debugging
#        if cmdExists 'apt-get'; then
#            function apt-get() {
#                command apt-get -qq "$@"
#            }
#            export -f apt-get
#        fi
#        if cmdExists 'yum'; then
#            function yum() {
#                command yum -q -e 0 "$@"
#            }
#            export -f yum
#        fi
#        if cmdExists 'dnf'; then
#            function dnf() {
#                command dnf -q -e 0 "$@"
#            }
#            export -f dnf
#        fi
#        # quiet make when not debugging
#        function make() {
#            command make -s "$@"
#        }
#        export -f make
#    fi
    return
}

# prep before processing command
function preprocessCMD() {
    # Display usage options if no command is specified
    if (( $# == 0 )); then
        usageOptions
        exit 1
    fi

    # Do not run the extra prep on these commands
    # we only need a portion of the script settings
    case "$1" in
        chown|exec|clusterinstall|version|-v|--version|help|-h|--help)
            setStaticScriptSettings
            ;;
        *)
            initialChecks "$@"
            setVerbosityLevel "$@"
            ;;
    esac
}

# process the commands to be executed
# TODO: add help options for each command (with subsection usage info for that command)
# TODO: move cli arg parsing to start of dsiprouter.sh (split out into its own file)
# TODO: separate settings.py generation/config/update
# TODO: move cli arg/option definitions to separate shared JSON file
function processCMD() {
    # pre-processing / initial checks
    preprocessCMD "$@"

    # use options to add commands in any order needed
    # 1 == defaults on, 0 == defaults off
    local DISPLAY_LOGIN_INFO=0
    # for install / uninstall, if no selections are chosen use some sane defaults
    local DEFAULT_SERVICES=1

    # process all options before running commands
    declare -a RUN_COMMANDS
    local ARG="$1" OPT="" RETVAL=0
    case $ARG in
        install)
            # always add official repo's, set platform, and create init service
            RUN_COMMANDS+=(configureSystemRepos setCloudPlatform createInitService createSwapFile installDsiprouterCli)
            shift

            local NEW_ROOT_DB_USER="" NEW_ROOT_DB_PASS="" NEW_ROOT_DB_NAME="" DB_CONN_URI="" TMP_ARG=""

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
                        RUN_COMMANDS+=(installSipsak installCron installDnsmasq installMysql installKamailio)
                        shift
                        ;;
                    -dsip|--dsiprouter)
                        DEFAULT_SERVICES=0
                        DISPLAY_LOGIN_INFO=1
                        RUN_COMMANDS+=(installSipsak installCron installMysql installNginx installDsiprouter)
                        shift
                        ;;
                    -rtp|--rtpengine)
                        DEFAULT_SERVICES=0
                        RUN_COMMANDS+=(installCron installRTPEngine)
                        shift
                        ;;
                    -all|--all)
                        DEFAULT_SERVICES=0
                        DISPLAY_LOGIN_INFO=1
                        RUN_COMMANDS+=(installSipsak installCron installDnsmasq installMysql installKamailio installNginx installDsiprouter installRTPEngine)
                        shift
                        ;;
                    # DEPRECATED: marked for removal in v0.80
                    -dmz|--dmz=*)
                        NETWORK_MODE=2

                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            TMP=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            TMP="$1"
                            shift
                        fi

                        PUBLIC_IFACE=$(echo "$TMP" | cut -d ',' -f 1)
                        PRIVATE_IFACE=$(echo "$TMP" | cut -d ',' -f 2)
                        ;;
                    -netm|--network-mode=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            NETWORK_MODE=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            NETWORK_MODE="$1"
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

                        TMP_VAL=$(parseDBConnURI -user "$DB_CONN_URI") && export SET_KAM_DB_USER="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -pass "$DB_CONN_URI") && export SET_KAM_DB_PASS="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -host "$DB_CONN_URI") && export SET_KAM_DB_HOST="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -port "$DB_CONN_URI") && export SET_KAM_DB_PORT="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -name "$DB_CONN_URI") && export SET_KAM_DB_NAME="$TMP_VAL"
                        ;;
                    -dsipcid|--dsip-clusterid=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            DSIP_CLUSTER_ID="$(echo "$1" | cut -d '=' -f 2)"
                            shift
                        else
                            shift
                            DSIP_CLUSTER_ID="$1"
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

                        TMP_VAL=$(parseDBConnURI -user "$DB_CONN_URI") && export ROOT_DB_USER="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -pass "$DB_CONN_URI") && export ROOT_DB_PASS="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -host "$DB_CONN_URI") && export ROOT_DB_HOST="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -port "$DB_CONN_URI") && export ROOT_DB_PORT="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -name "$DB_CONN_URI") && export ROOT_DB_NAME="$TMP_VAL"
                        ;;
                    -dsipcsync|--dsip-clustersync=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            DSIP_CLUSTER_SYNC="$(echo "$1" | cut -d '=' -f 2)"
                            shift
                        else
                            shift
                            DSIP_CLUSTER_SYNC="$1"
                            shift
                        fi

                        # sanity check value for cluster sync
                        case "$DSIP_CLUSTER_SYNC" in
                            0|1)
                                :
                                ;;
                            *)
                                printerr 'Invalid value for setting DSIP_CLUSTER_SYNC'
                                exit 1
                                ;;
                        esac

                        # change default for loading settings to db
                        LOAD_SETTINGS_FROM='db'
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
                            exit 1
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
                        export HOMER_HEP_HOST=$(printf '%s' "$1" | cut -d ':' -f -1)
                        TMP_ARG="$(printf '%s' "$1" | cut -s -d ':' -f 2)"
                        [[ -n "$TMP_ARG" ]] && export HOMER_HEP_PORT="$TMP_ARG"
                        shift
                        # sanity check
                        if [[ -z "$HOMER_HEP_HOST" ]]; then
                            printerr 'Missing required argument <homer_host> to option -homer'
                            exit 1
                        fi
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        exit 1
                        shift
                        ;;
                esac
            done

            # only use defaults if no discrete services specified
            if (( ${DEFAULT_SERVICES} == 1 )); then
                DISPLAY_LOGIN_INFO=1
                RUN_COMMANDS+=(installSipsak installDnsmasq installMysql installKamailio installNginx installDsiprouter)
            fi

            # add displaying logo and login info to deferred commands
            RUN_COMMANDS+=(displayLogo)
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
                        RUN_COMMANDS+=(uninstallDsiprouter uninstallNginx)
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
                        RUN_COMMANDS+=(uninstallRTPEngine uninstallDsiprouter uninstallNginx uninstallKamailio uninstallMysql uninstallDnsmasq uninstallSipsak uninstallDsiprouterCli removeSwapFile removeInitService removeDsipSystemConfig)
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        exit 1
                        shift
                        ;;
                esac
            done

            # only use defaults if no discrete services specified
            if (( ${DEFAULT_SERVICES} == 1 )); then
                RUN_COMMANDS+=(uninstallDsiprouter uninstallNginx uninstallKamailio uninstallMysql uninstallDnsmasq uninstallSipsak uninstallDsiprouterCli removeSwapFile removeInitService)
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
                        # scrap the --
                        shift
                        break
                        ;;
                    -debug)
                        export DEBUG=1
                        shift
                        ;;
                    -i)
                        shift
                        SSH_KEY_FILE="$1"
                        shift
                        ;;
                    *)  # add to list of nodes
                        SSH_SYNC_NODES+=( "$ARG" )
                        shift
                        ;;
                esac
            done

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
                            SET_DSIP_PRIV_KEY="$1"
                            shift
                        fi
                        # sanity check
                        if (( $(printf '%s' "${SET_DSIP_PRIV_KEY}" | wc -c) != 32 )); then
                            printerr 'dSIPRouter private key must be 32 bytes'
                            exit 1
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
                exit 1
            fi
            ;;
        upgrade)
            # upgrade dsiprouter version
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
                            DSIP_CLUSTER_ID="$(echo "$1" | cut -d '=' -f 2)"
                            shift
                        else
                            shift
                            DSIP_CLUSTER_ID="$1"
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
                            printerr "Invalid upgrade release specified"
                            usageOptions
                            exit 1
                        fi

                        # format as per branch name if given as version number
                        if [[ "${UPGRADE_RELEASE:0:1}" != "v" ]]; then
                            UPGRADE_RELEASE="v${UPGRADE_RELEASE}"
                        fi
                        ;;
                    -url|--repo-url=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            export UPGRADE_REPO="$(echo "$1" | cut -d '=' -f 2)"
                            shift
                        else
                            shift
                            export UPGRADE_REPO="$1"
                            shift
                        fi
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        exit 1
                        shift
                        ;;
                esac
            done

            # repo we are upgrading from could have been provided on the CLI
            if [[ -n "$UPGRADE_REPO" ]]; then
                UPGRADE_RELEASE_URL="https://api.github.com/repos/$(rev <<<"$UPGRADE_REPO" | cut -d '/' -f -2 | cut -d '.' -f 2- | rev)/releases"
            else
                UPGRADE_RELEASE_URL="$GIT_RELEASE_URL"
            fi

            # use latest release if none specified
            if [[ -z "$UPGRADE_RELEASE" ]]; then
                TMP=$(curl -s "$UPGRADE_RELEASE_URL") &&
                TMP=$(jq -e -r  '.[].tag_name | gsub("^v(?<tag>[0-9]+\\.[0-9]+).*?$"; "\(.tag)")' <<<"$TMP") &&
                UPGRADE_RELEASE=$(sort -gur <<<"$TMP" | head -1) || {
                    printerr "Could not retrieve latest release candidate"
                    exit 1
                }
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
                        exit 1
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
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        restart)
            RESTART_ARGS=(restart)
            RESTART_DAEMONIZE=0

            # restart installed services
            RUN_COMMANDS+=(restart)
            shift

            # process debug option before parsing others
            if [[ "$1" == "-debug" ]]; then
                export DEBUG=1
                RESTART_ARGS+=("$1")
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
                        RESTART_ARGS+=("$1")
                        shift
                        ;;
                    -dsip|--dsiprouter)
                        STOP_DSIPROUTER=1
                        START_DSIPROUTER=1
                        RESTART_ARGS+=("$1")
                        shift
                        ;;
                    -kam|--kamailio)
                        STOP_KAMAILIO=1
                        START_KAMAILIO=1
                        RESTART_ARGS+=("$1")
                        shift
                        ;;
                    -rtp|--rtpengine)
                        STOP_RTPENGINE=1
                        START_RTPENGINE=1
                        RESTART_ARGS+=("$1")
                        shift
                        ;;
                    # internal usage only, no need for user to be calling with this option
                    -daemonize)
                        RESTART_DAEMONIZE=1
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        # internal command, replace this process with the GUI server immediately
        exec)
            exec ${PYTHON_CMD} ${DSIP_PROJECT_DIR}/gui/dsiprouter.py
            ;;
        chown)
            shift

            # handle the debug option here
            for OPT in "$@"; do
                shift
                case $OPT in
                    -debug)
                        export DEBUG=1
                        set -x
                        continue
                        ;;
                esac
                set -- "$@" "$OPT"
            done

            # pass the rest of the user args to the local function
            # TODO: figure out how to pass variables into staged commands
            updatePermissions "$@"
            exit $?
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
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        configuredsip)
            # reconfigure dsiprouter configs
            RUN_COMMANDS+=(generateDsiprouterConfig updateDsiprouterConfig updateDsiprouterStartup)
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
                        exit 1
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
                        exit 1
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
                        exit 1
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
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        resetpassword)
            # reset secure credentials
            RUN_COMMANDS+=(setCloudPlatform setCredentials)
            shift

            # by default we display the new login information
            DISPLAY_LOGIN_INFO=1

            # we default to resetting only the dsip gui password
            # otherwise only the credentials specified are reset
            while (( $# > 0 )); do
                OPT="$1"
                case $OPT in
                    -debug)
                        export DEBUG=1
                        set -x
                        shift
                        ;;
                    -q|--quiet)
                        DISPLAY_LOGIN_INFO=0
                        shift
                        ;;
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
                        RESET_DSIP_GUI_PASS=${RESET_DSIP_GUI_PASS:-0}
                        shift
                        ;;
                    -kc|--kam-creds)
                        RESET_KAM_DB_PASS=1
                        RESET_DSIP_GUI_PASS=${RESET_DSIP_GUI_PASS:-0}
                        shift
                        ;;
                    -ic|--ipc-creds)
                        RESET_DSIP_IPC_TOKEN=1
                        RESET_DSIP_GUI_PASS=${RESET_DSIP_GUI_PASS:-0}
                        shift
                        ;;
                    -fid|--force-instance-id)
                        RESET_FORCE_INSTANCE_ID=1
                        shift
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        exit 1
                        shift
                        ;;
                esac
            done

            # preconditions checks and setting variables to pass to setCredentials()
            if (( ${RESET_DSIP_GUI_PASS:-1} == 1 )); then
                if (( ${IMAGE_BUILD} == 1 || ${RESET_FORCE_INSTANCE_ID:-0} == 1 )); then
                    SET_DSIP_GUI_PASS=$(getInstanceID)
                    if [[ -z "$SET_DSIP_GUI_PASS" ]]; then
                        printerr "Could not retrieve the instance ID for password reset"
                        exit 1
                    fi
                else
                    SET_DSIP_GUI_PASS=$(urandomChars 64)
                fi
            fi
            if (( ${RESET_DSIP_API_TOKEN:-0} == 1 )); then
                SET_DSIP_API_TOKEN=$(urandomChars 64)
            fi
            if (( ${RESET_DSIP_IPC_TOKEN:-0} == 1 )); then
                SET_DSIP_IPC_TOKEN=$(urandomChars 64)
            fi
            if (( ${RESET_KAM_DB_PASS:-0} == 1 )); then
                export SET_KAM_DB_PASS=$(urandomChars 64)
            fi

            # display if not in quiet mode
            if (( ${DISPLAY_LOGIN_INFO} == 1 )); then
                RUN_COMMANDS+=(displayLoginInfo)
            fi
            ;;
        setcredentials)
            # set secure credentials to fixed values
            RUN_COMMANDS+=(setCredentials)
            shift

            local TMP_VAL=''

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
                            exit 1
                        fi

                        TMP_VAL=$(parseDBConnURI -user "$DB_CONN_URI") && export SET_KAM_DB_USER="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -pass "$DB_CONN_URI") && export SET_KAM_DB_PASS="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -host "$DB_CONN_URI") && export SET_KAM_DB_HOST="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -port "$DB_CONN_URI") && export SET_KAM_DB_PORT="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -name "$DB_CONN_URI") && export SET_KAM_DB_NAME="$TMP_VAL"
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
                            exit 1
                        fi

                        TMP_VAL=$(parseDBConnURI -user "$DB_CONN_URI") && export SET_ROOT_DB_USER="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -pass "$DB_CONN_URI") && export SET_ROOT_DB_PASS="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -host "$DB_CONN_URI") && export SET_ROOT_DB_HOST="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -port "$DB_CONN_URI") && export SET_ROOT_DB_PORT="$TMP_VAL"
                        TMP_VAL=$(parseDBConnURI -name "$DB_CONN_URI") && export SET_ROOT_DB_NAME="$TMP_VAL"
                        ;;
                    -sc|--session-creds=*)
                        if echo "$1" | grep -q '=' 2>/dev/null; then
                            SET_DSIP_SESSION_KEY=$(echo "$1" | cut -d '=' -f 2)
                            shift
                        else
                            shift
                            SET_DSIP_SESSION_KEY="$1"
                            shift
                        fi
                        ;;
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        # DEPRECATED: in favor of using configurekam command, marked for removal in v0.80
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
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        # internal command, update kamailio config dynamically
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
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        # internal command, update dsiprouter config dynamically
        updatedsipconfig)
            # update kamailio config
            RUN_COMMANDS+=(updateDsiprouterConfig)
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
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        # internal command, update rtpengine config dynamically
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
                    *)  # fail on unknown option
                        printerr "Invalid option [$OPT] for command [$ARG]"
                        usageOptions
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        # internal command, update dnsmasq config dynamically
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
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        # internal command, generate CA dir from CA bundle file
        updatecacertsdir)
            # update dnsmasq config
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
                        exit 1
                        shift
                        ;;
                esac
            done
            ;;
        version|-v|--version)
            printf '%s\n' "$(getConfigAttrib 'VERSION' ${DSIP_CONFIG_FILE})"
            exit 1
            ;;
        help|-h|--help)
            usageOptions
            exit 1
            ;;
        *)
            printerr "Invalid command [$ARG]"
            usageOptions
            exit 1
            ;;
    esac

    # remove duplicate commands, while preserving order
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
        RETVAL=$((RETVAL + $?))
    done
    exit $RETVAL
} #end of processCMD

processCMD "$@"
