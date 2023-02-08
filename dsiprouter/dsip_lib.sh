#!/usr/bin/env bash

# NOTES:
# contains utility functions and shared variables
# should be sourced by an external script
# exporting upon import removes need to import again in sub-processes

######################
# Imported Constants #
######################

# Ansi Colors
export ESC_SEQ="\033["
export ANSI_NONE="${ESC_SEQ}39;49;00m" # Reset colors
export ANSI_RED="${ESC_SEQ}1;31m"
export ANSI_GREEN="${ESC_SEQ}1;32m"
export ANSI_YELLOW="${ESC_SEQ}1;33m"
export ANSI_CYAN="${ESC_SEQ}1;36m"

# public IP's us for testing / DNS lookups in scripts
export GOOGLE_DNS_IPV4="8.8.8.8"
export GOOGLE_DNS_IPV6="2001:4860:4860::8888"

# Constants for imported functions
export DSIP_INIT_FILE=${DSIP_INIT_FILE:-"/lib/systemd/system/dsip-init.service"}
export DSIP_SYSTEM_CONFIG_DIR=${DSIP_SYSTEM_CONFIG_DIR:-"/etc/dsiprouter"}
DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(dirname $(dirname $(readlink -f "$BASH_SOURCE")))}

# reuse credential settings from python files (exported for later usage)
SALT_LEN=$(grep -m 1 -oP 'SALT_LEN[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)
DK_LEN_DEFAULT=$(grep -m 1 -oP 'DK_LEN_DEFAULT[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)
CREDS_MAX_LEN=$(grep -m 1 -oP 'CREDS_MAX_LEN[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)
HASH_ITERATIONS=$(grep -m 1 -oP 'HASH_ITERATIONS[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)
export HASHED_CREDS_ENCODED_MAX_LEN=$(grep -m 1 -oP 'HASHED_CREDS_ENCODED_MAX_LEN[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)
export AESCTR_CREDS_ENCODED_MAX_LEN=$(grep -m 1 -oP 'AESCTR_CREDS_ENCODED_MAX_LEN[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)

# Flag denoting that these functions have been imported (verifiable in sub-processes)
export DSIP_LIB_IMPORTED=1

##############################################
# Printing functions and String Manipulation #
##############################################

function printerr() {
    if [[ "$1" == "-n" ]]; then
        shift; printf "%b%s%b" "${ANSI_RED}" "$*" "${ANSI_NONE}"
    else
        printf "%b%s%b\n" "${ANSI_RED}" "$*" "${ANSI_NONE}"
    fi
}
export -f printerr

function printwarn() {
    if [[ "$1" == "-n" ]]; then
        shift; printf "%b%s%b" "${ANSI_YELLOW}" "$*" "${ANSI_NONE}"
    else
        printf "%b%s%b\n" "${ANSI_YELLOW}" "$*" "${ANSI_NONE}"
    fi
}
export -f printwarn

function printdbg() {
    if [[ "$1" == "-n" ]]; then
        shift; printf "%b%s%b" "${ANSI_GREEN}" "$*" "${ANSI_NONE}"
    else
        printf "%b%s%b\n" "${ANSI_GREEN}" "$*" "${ANSI_NONE}"
    fi
}
export -f printdbg

function pprint() {
    if [[ "$1" == "-n" ]]; then
        shift; printf "%b%s%b" "${ANSI_CYAN}" "$*" "${ANSI_NONE}"
    else
        printf "%b%s%b\n" "${ANSI_CYAN}" "$*" "${ANSI_NONE}"
    fi
}
export -f pprint

function tolower() {
    if [[ -t 0 ]]; then
        printf '%s' "$1" | tr '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]' '[abcdefghijklmnopqrstuvwxyz]'
    else
        tr '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]' '[abcdefghijklmnopqrstuvwxyz]' </dev/stdin
    fi
}
export -f tolower

function toupper() {
    if [[ -t 0 ]]; then
        printf '%s' "$1" | tr '[abcdefghijklmnopqrstuvwxyz]' '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]'
    else
        tr '[abcdefghijklmnopqrstuvwxyz]' '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]' </dev/stdin
    fi
}
export -f toupper

function hextoint() {
	if [[ -t 0 ]]; then
		printf '%d' "0x$1" 2>/dev/null
	else
		printf '%d' "0x$(</dev/stdin)" 2>/dev/null
	fi
}
rxport -f hextoint

######################################
# Traceback / Debug helper functions #
######################################

function backtrace() {
    local DEPTN=${#FUNCNAME[@]}

    for ((i=1; i < ${DEPTN}; i++)); do
        local FUNC="${FUNCNAME[$i]}"
        local LINE="${BASH_LINENO[$((i-1))]}"
        local SRC="${BASH_SOURCE[$((i-1))]}"
        printf '%*s' $i '' # indent
        printerr "[ERROR]: ${FUNC}(), ${SRC}, line: ${LINE}"
    done
}
export -f backtrace

function setErrorTracing() {
    set -o errtrace
    trap 'backtrace' ERR
}
export -f setErrorTracing

#######################################
# Reusable / Shared Utility functions #
#######################################

# TODO: we need to change the config getter/setter functions to use options parsing:
# - when the value to set variable to is the empty string our functions error out
# - ordering of filename and other options can be easily mistaken, which can set wrong values in config
# - input validation would also be much easier if we switched added option parsing

# $1 == attribute name
# $2 == attribute value
# $3 == python config file
# $4 == -q (quote string) | -qb (quote byte string)
function setConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    if (( $# >= 4 )); then
        if [[ "$4" == "-q" ]]; then
            VALUE="'${VALUE}'"
        elif [[ "$4" == "-qb" ]]; then
            VALUE="b'${VALUE}'"
        fi
    fi
    sed -i -r -e "s|$NAME[ \t]*=[ \t]*.*|$NAME = $VALUE|g" ${CONFIG_FILE}
}
export -f setConfigAttrib

# $1 == attribute name
# $2 == python config file
# output: attribute value
function getConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    local VALUE=$(grep -oP '^(?!#)(?:'${NAME}')[ \t]*=[ \t]*\K(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|b?""".*"""[ \t]*$|'"b?'''.*'''"'[ \v]*$|b?".*"[ \t]*$|'"b?'.*'"')' ${CONFIG_FILE})
    printf '%s' "${VALUE}" | perl -0777 -pe 's~^b?["'"'"']+(.*?)["'"'"']+$|(.*)~\1\2~g'
}
export -f getConfigAttrib

# TODO: openssl native version
# $1 == attribute name
# $2 == python config file
# output: attribute value decrypted
# notes: if value is not encrypted the value is output instead
function decryptConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"
    local PYTHON=${PYTHON_CMD:-python3}

    local VALUE=$(grep -oP '^(?!#)(?:'${NAME}')[ \t]*=[ \t]*\K(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|b?""".*"""[ \t]*$|'"b?'''.*'''"'[ \v]*$|b?".*"[ \t]*$|'"b?'.*'"')' ${CONFIG_FILE})
    # if value is not a byte literal it isn't encrypted
    if ! printf '%s' "${VALUE}" | grep -q -oP '(b""".*"""|'"b'''.*'''"'|b".*"|'"b'.*')"; then
        printf '%s' "${VALUE}" | perl -0777 -pe 's~^b?["'"'"']+(.*?)["'"'"']+$|(.*)~\1\2~g'
    else
        ${PYTHON} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); import sys; sys.path.insert(0, '${DSIP_SYSTEM_CONFIG_DIR}/gui'); import settings; from util.security import AES_CTR; print(AES_CTR.decrypt(settings.${NAME}).decode('utf-8'), end='')"
    fi
}
export -f decryptConfigAttrib

# TODO: openssl native version
# $1 == attribute name
# $2 == kamailio config file
function enableKamailioConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s~#+(!(define|trydef|redefine)[[:space:]]? $NAME)~#\1~g" ${CONFIG_FILE}
}
export -f enableKamailioConfigAttrib

# $1 == attribute name
# $2 == kamailio config file
function disableKamailioConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s~#+(!(define|trydef|redefine)[[:space:]]? $NAME)~##\1~g" ${CONFIG_FILE}
}
export -f disableKamailioConfigAttrib

# $1 == name of defined url to change
# $2 == value to change url to
# $3 == kamailio config file
# notes: will skip any cluster url attributes
function setKamailioConfigDburl() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    perl -e "\$dburl='${VALUE}';" \
        -0777 -i -pe 's~(#!(define|trydef|redefine)\s+?'"${NAME}"'\s+)['"'"'"](?!cluster\:).*['"'"'"]~\1"${dburl}"~g' ${CONFIG_FILE}
}
export -f setKamailioConfigDburl

# $1 == name of subst/substdef/substdefs to change
# $2 == value to change subst/substdef/substdefs to
# $3 == kamailio config file
function setKamailioConfigSubst() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    perl -e "\$name='$NAME'; \$value='$VALUE';" \
        -i -pe 's~(#!subst(?:def|defs)?.*!${name}!).*(!.*)~\1${value}\2~g' ${CONFIG_FILE}
}
export -f setKamailioConfigSubst

# $1 == name of global variable to change
# $2 == value to change variable to
# $3 == kamailio config file
function setKamailioConfigGlobal() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"
    local REPLACE_TOKEN='__ABCDEFGHIJKLMNOPQRSTUVWXYZ__'

    perl -pi -e "s~^(${NAME}\s?=\s?)(?:(\"|')(.*?)(\"|')|\d+)(\sdesc\s(?:\"|').*?(?:\"|'))?~\1\2${REPLACE_TOKEN}\4\5~g" ${CONFIG_FILE}
    sed -i -e "s%${REPLACE_TOKEN}%${VALUE}%g" ${CONFIG_FILE}
}
export -f setKamailioConfigGlobal

# $1 == attribute name
# $2 == rtpengine config file
function enableRtpengineConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s~^#+(${NAME}[ \t]*=[ \t]*.*)~\1~g" ${CONFIG_FILE}
}
export -f enableRtpengineConfigAttrib

# $1 == attribute name
# $2 == rtpengine config file
function disableRtpengineConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s~^#*(${NAME}[ \t]*=[ \t]*.*)~#\1~g" ${CONFIG_FILE}
}
export -f disableRtpengineConfigAttrib

# $1 == attribute name
# $2 == rtpengine config file
function getRtpengineConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    grep -oP '^(?!#)('${NAME}'[ \t]*=[ \t]*\K.*)' ${CONFIG_FILE}
}
export -f getRtpengineConfigAttrib

# $1 == attribute name
# $2 == value of attribute
# $3 == rtpengine config file
function setRtpengineConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    perl -e "\$name='$NAME'; \$value='$VALUE';" \
        -i -pe 's%^(?!#)(${name}[ \t]*=[ \t]*.*)%${name} = ${value}%g' ${CONFIG_FILE}
}
export -f setRtpengineConfigAttrib

# output: Linux Distro name
function getDistroName() {
    grep '^ID=' /etc/os-release 2>/dev/null | cut -d '=' -f 2 | cut -d '"' -f 2
}
export -f getDistroName

# output: Linux Distro version
function getDistroVer() {
    grep '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d '=' -f 2 | cut -d '"' -f 2
}
export -f getDistroVer

# $1 == command to test
# returns: 0 == true, 1 == false
function cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
export -f cmdExists

# $1 == directory to check for in PATH
# returns: 0 == found, 1 == not found
function pathCheck() {
    case ":${PATH-}:" in
        *:"$1":*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
export -f pathCheck

# returns: 0 == success, otherwise failure
# notes: try to access the AWS metadata URL to determine if this is an AMI instance
function isInstanceAMI() {
    curl -s -f --connect-timeout 2 http://169.254.169.254/latest/dynamic/instance-identity/ &>/dev/null
    return $?
}
export -f isInstanceAMI

# returns: 0 == success, otherwise failure
# notes: try to access the DO metadata URL to determine if this is an Digital Ocean instance
function isInstanceDO() {
    curl -s -f --connect-timeout 2 http://169.254.169.254/metadata/v1/id &>/dev/null
    return $?
}
export -f isInstanceDO

# returns: 0 == success, otherwise failure
# notes: try to access the GCE metadata URL to determine if this is an Google instance
function isInstanceGCE() {
    curl -s -f --connect-timeout 2 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/id &>/dev/null
    return $?
}
export -f isInstanceGCE

# returns: 0 == success, otherwise failure
# notes: try to access the MS Azure metadata URL to determine if this is an Azure instance
function isInstanceAZURE() {
    curl -s -f --connect-timeout 2 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2018-10-01" &>/dev/null
    return $?
}
export -f isInstanceAZURE

# returns: 0 == success, otherwise failure
# notes: try to access the DO metadata URL to determine if this is an VULTR instance
function isInstanceVULTR() {
    curl -s -f --connect-timeout 2 http://169.254.169.254/v1/instanceid &>/dev/null
    return $?
}
export -f isInstanceDO

# output: instance ID || blank string
# notes: we try checking for exported instance variable avoid querying again
function getInstanceID() {
    if (( ${AWS_ENABLED:-0} == 1)); then
        curl -s -f http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null ||
        ec2-metadata -i 2>/dev/null | awk '{print $2}'
    elif (( ${DO_ENABLED:-0} == 1 )); then
        curl -s -f http://169.254.169.254/metadata/v1/id 2>/dev/null
    elif (( ${GCE_ENABLED:-0} == 1 )); then
        curl -s -f -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id 2>/dev/null
    elif (( ${AZURE_ENABLED:-0} == 1 )); then
        curl -s -f -H "Metadata: true" "http://169.254.169.254/metadata/instance/compute/vmId?api-version=2018-10-01" 2>/dev/null
    elif (( ${VULTR_ENABLED:-0} == 1 )); then
        curl -s -f http://169.254.169.254/v1/instanceid 2>/dev/null
    else
        if isInstanceAMI; then
            curl -s -f http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null ||
            ec2-metadata -i 2>/dev/null | awk '{print $2}'
        elif isInstanceDO; then
            curl -s -f http://169.254.169.254/metadata/v1/id 2>/dev/null
        elif isInstanceGCE; then
            curl -s -f -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id 2>/dev/null
        elif isInstanceAZURE; then
            curl -s -f -H "Metadata: true" "http://169.254.169.254/metadata/instance/compute/vmId?api-version=2018-10-01" 2>/dev/null
        elif isInstanceVULTR; then
            curl -s -f http://169.254.169.254/v1/instanceid 2>/dev/null
        fi
    fi
}
export -f getInstanceID

# $1 == crontab entry to append
function cronAppend() {
    local ENTRY="$1"
    crontab -l 2>/dev/null | { cat; echo "$ENTRY"; } | crontab -
}
export -f cronAppend

# $1 == crontab entry to remove
function cronRemove() {
    local ENTRY="$1"
    crontab -l 2>/dev/null | grep -v -F -w "$ENTRY" | crontab -
}
export -f cronRemove

# $1 == ip to test
# returns: 0 == success, 1 == failure
# notes: regex credit to <https://helloacm.com>
function ipv4Test() {
    local IP="$1"

    if [[ $IP =~ ^([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
        return 0
    fi
    return 1
}
export -f ipv4Test

# $1 == ip to test
# returns: 0 == success, 1 == failure
# notes: regex credit to <https://helloacm.com>
function ipv6Test() {
    local IP="$1"

    if [[ $IP =~ ^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$ ]]; then
        return 0
    fi
    return 1
}
export -f ipv6Test


# $1 == [-4|-6] to force specific IP version
# output: the internal IP for this system
# notes: prints internal ip, or empty string if not available
# notes: tries ipv4 first then ipv6
# TODO: currently we only check for the internal IP associated with the default interface/default route
#       this will fail if the internal IP is not assigned to the default interface/default route
#       not sure what networking scenarios that would be useful for, the community should provide us feedback on this
function getInternalIP() {
    local INTERNAL_IP=""

    case "$1" in
        -4)
            local IPV4_ENABLED=1
            local IPV6_ENABLED=0
            ;;
        -6)
            local IPV4_ENABLED=0
            local IPV6_ENABLED=1
            ;;
        *)
            local IPV4_ENABLED=1
            local IPV6_ENABLED=${IPV6_ENABLED:-0}
            ;;
    esac
	    
    if (( ${IPV6_ENABLED} == 1 )); then
	INTERFACE=$(ip -br -6 a| grep UP | head -1 | awk {'print $1'})
    else
	INTERFACE=$(ip -4 route show default | awk '{print $5}')
    fi

    # Get the ip address without depending on DNS
    if (( ${IPV4_ENABLED} == 1 )); then
	
        # Marked for removal because it depends on DNS
	#INTERNAL_IP=$(ip -4 route get $GOOGLE_DNS_IPV4 2>/dev/null | head -1 | grep -oP 'src \K([^\s]+)')
	INTERNAL_IP=$(ip addr show $INTERFACE | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | head -1)
    fi

    if (( ${IPV6_ENABLED} == 1 )) && [[ -z "$INTERNAL_IP" ]]; then
        # Marked for removal because it depends on DNS
        #INTERNAL_IP=$(ip -6 route get $GOOGLE_DNS_IPV6 2>/dev/null | head -1 | grep -oP 'src \K([^\s]+)')
	INTERNAL_IP=$(ip addr show $INTERFACE | grep 'inet6 ' | awk '{print $2}' | cut -f1 -d'/' | head -1)
    fi

    printf '%s' "$INTERNAL_IP"
}
export -f getInternalIP

# $1 == [-4|-6] to force specific IP version
# $2 == network interface 
# output: the internal IP for this system
# notes: prints ip, or empty string if not available
# notes: tries ipv4 first then ipv6
# TODO: currently we only check for the internal IP associated with the default interface/default route
#       this will fail if the internal IP is not assigned to the default interface/default route
#       not sure what networking scenarios that would be useful for, the community should provide us feedback on this
function getIP() {
    local IP=""

    case "$1" in
        -4)
            local IPV4_ENABLED=1
            local IPV6_ENABLED=0
            ;;
        -6)
            local IPV4_ENABLED=0
            local IPV6_ENABLED=1
            ;;
        *)
            local IPV4_ENABLED=1
            local IPV6_ENABLED=${IPV6_ENABLED:-0}
            ;;
    esac

    # Use the provided interface or get the first interface - other then lo
    if ! [ -z $2 ]; then
	    INTERFACE=$2
    else
	    if (( ${IPV6_ENABLED} == 1 )); then
		INTERFACE=$(ip -br -6 a| grep UP | head -1 | awk {'print $1'})
	    else
	    	INTERFACE=$(ip -4 route show default | awk '{print $5}')
	    fi
    fi

   
    # Get the ip address without depending on DNS
    if (( ${IPV4_ENABLED} == 1 )); then
	
        # Marked for removal because it depends on DNS
	#INTERNAL_IP=$(ip -4 route get $GOOGLE_DNS_IPV4 2>/dev/null | head -1 | grep -oP 'src \K([^\s]+)')
	IP=$(ip addr show $INTERFACE | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/' | head -1)
    fi

    if (( ${IPV6_ENABLED} == 1 )) && [[ -z "$INTERNAL_IP" ]]; then
        # Marked for removal because it depends on DNS
        #INTERNAL_IP=$(ip -6 route get $GOOGLE_DNS_IPV6 2>/dev/null | head -1 | grep -oP 'src \K([^\s]+)')
	IP=$(ip addr show $INTERFACE | grep 'inet6 ' | awk '{print $2}' | cut -f1 -d'/' | head -1)
    fi

    printf '%s' "$IP"
}
export -f getIP

# TODO: run requests in parallel and grab first good one (start ipv4 first)
#       this is what we are already doing in gui/util/networking.py
#       this would be much faster bcuz DNS exceptions take a while to handle
#       GNU parallel should not be used bcuz package support is not very good
#       this should instead use a pure bash version of GNU parallel, refs:
#       https://stackoverflow.com/questions/10909685/run-parallel-multiple-commands-at-once-in-the-same-terminal
#       https://www.cyberciti.biz/faq/how-to-run-command-or-code-in-parallel-in-bash-shell-under-linux-or-unix/
#       https://unix.stackexchange.com/questions/305039/pausing-a-bash-script-until-previous-commands-are-finished
#       https://unix.stackexchange.com/questions/497614/bash-execute-background-process-whilst-reading-output
#       https://stackoverflow.com/questions/3338030/multiple-bash-traps-for-the-same-signal
# $1 == [-4|-6] to force specific IP version
# output: the external IP for this system
# notes: prints external ip, or empty string if not available
# notes: below we have measurements for average time of each service
#        over 10 non-cached requests, in seconds, round trip
#
# |          External Service         | Mean RTT | IP Protocol |
# |:---------------------------------:|:--------:|:-----------:|
# | https://icanhazip.com             | 0.38080  | IPV4        |
# | https://ipecho.net/plain          | 0.39810  | IPV4        |
# | https://myexternalip.com/raw      | 0.51850  | IPV4        |
# | https://api.ipify.org             | 0.64860  | IPV4        |
# | https://bot.whatismyipaddress.com | 0.69640  | IPV4        |
# | https://icanhazip.com             | 0.40190  | IPV6        |
# | https://bot.whatismyipaddress.com | 0.72490  | IPV6        |
# | https://ifconfig.co               | 0.80290  | IPV6        |
# | https://ident.me                  | 0.97620  | IPV6        |
# | https://api6.ipify.org            | 1.08510  | IPV6        |
#
function getExternalIP() {
    local EXTERNAL_IP="" TIMEOUT=5
    local IPV4_URLS=(
        "https://icanhazip.com"
        "https://ipecho.net/plain"
        "https://myexternalip.com/raw"
        "https://api.ipify.org"
        "https://bot.whatismyipaddress.com"
    )
    local IPV6_URLS=(
        "https://icanhazip.com"
        "https://bot.whatismyipaddress.com"
        "https://ifconfig.co"
        "https://ident.me"
        "https://api6.ipify.org"
    )

    case "$1" in
        -4)
            local IPV4_ENABLED=1
            local IPV6_ENABLED=0
            ;;
        -6)
            local IPV4_ENABLED=0
            local IPV6_ENABLED=1
            ;;
        *)
            local IPV4_ENABLED=1
            local IPV6_ENABLED=${IPV6_ENABLED:-0}
            ;;
    esac

    if (( ${IPV4_ENABLED} == 1 )); then
        for URL in ${IPV4_URLS[@]}; do
            EXTERNAL_IP=$(curl -4 -s --connect-timeout $TIMEOUT $URL 2>/dev/null)
            ipv4Test "$EXTERNAL_IP" && { printf '%s' "$EXTERNAL_IP"; return 0; }
        done
    fi

    if (( ${IPV6_ENABLED} == 1 )) && [[ -z "$EXTERNAL_IP" ]]; then
        for URL in ${IPV6_URLS[@]}; do
            EXTERNAL_IP=$(curl -6 -s --connect-timeout $TIMEOUT $URL 2>/dev/null)
            ipv6Test "$EXTERNAL_IP" && { printf '%s' "$EXTERNAL_IP"; return 0; }
        done
    fi

    return 1
}
export -f getExternalIP

# output: the internal FQDN for this system
# notes: prints internal FQDN, or empty string if not available
function getInternalFQDN() {
    printf '%s' "$(hostname -f 2>/dev/null || hostname 2>/dev/null)"
}
export -f getInternalFQDN

# output: the external FQDN for this system
# notes: prints external FQDN, or empty string if not available
# notes: will use EXTERNAL_IP if available or look it up dynamically
# notes: tries ipv4 first then ipv6
function getExternalFQDN() {
    local EXTERNAL_FQDN=$(dig @${GOOGLE_DNS_IPV4} +short -x ${EXTERNAL_IP:-$(getExternalIP -4)} 2>/dev/null | head -1 | sed 's/\.$//')
    if (( ${IPV6_ENABLED:-0} == 1 )) && [[ -z "$EXTERNAL_FQDN" ]]; then
          EXTERNAL_FQDN=$(dig @${GOOGLE_DNS_IPV6} +short -x ${EXTERNAL_IP6:-$(getExternalIP -6)} 2>/dev/null | head -1 | sed 's/\.$//')
    fi
    printf '%s' "$EXTERNAL_FQDN"
}
export -f getExternalFQDN

# $1 == [-4|-6] to force specific IP version
# $2 == interface
# output: the internal IP CIDR for this system
# notes: prints internal CIDR address, or empty string if not available
# notes: tries ipv4 first then ipv6
function getInternalCIDR() {
    local PREFIX_LEN="" DEF_IFACE="" INTERNAL_IP=""
    #local IP=$(ip -4 route get $GOOGLE_DNS_IPV4 2>/dev/null | head -1 | grep -oP 'src \K([^\s]+)')

    case "$1" in
        -4)
            local IPV4_ENABLED=1
            local IPV6_ENABLED=0
            ;;
        -6)
            local IPV4_ENABLED=0
            local IPV6_ENABLED=1
            ;;
        *)
            local IPV4_ENABLED=1
            local IPV6_ENABLED=${IPV6_ENABLED:-0}
            ;;
    esac
    
    if ! [ -z $2 ]; then
	    INTERFACE=$2
    fi

    if (( ${IPV4_ENABLED} == 1 )); then
        INTERNAL_IP=$(getIP -4 "$INTERFACE")
        if [[ -n "$INTERNAL_IP" ]]; then
		if [[ -n "$INTERFACE" ]]; then
			DEF_IFACE=$INTERFACE
		else
            		DEF_IFACE=$(ip -4 route list scope global  2>/dev/null | perl -e 'while (<>) { if (s%^(?:0\.0\.0\.0|default).*dev (\w+).*$%\1%) { print; exit; } }')
            	fi
		PREFIX_LEN=$(ip -4 route list | grep "$INTERNAL_IP" | perl -e 'while (<>) { if (s%^(?!0\.0\.0\.0|default).*/(\d+) .*src [\w/.]*.*$%\1%) { print; exit; } }')
        fi
    fi

    if (( ${IPV6_ENABLED} == 1 )) && [[ -z "$INTERNAL_IP" ]]; then
        INTERNAL_IP=$(getInternalIP -6)
        if [[ -n "$INTERNAL_IP" ]]; then
            DEF_IFACE=$(ip -6 route list scope global 2>/dev/null | perl -e 'while (<>) { if (s%^(?:::/0|default).*dev (\w+).*$%\1%) { print; exit; } }')
            PREFIX_LEN=$(ip -6 route list 2>/dev/null | grep "dev $DEF_IFACE" | perl -e 'while (<>) { if (s%^(?!::/0|default).*/(\d+) .*via [\w:/.]*.*$%\1%) { print; exit; } }')
        fi
    fi

    # make sure output is empty if error occurred
    if [[ -n "$INTERNAL_IP" && -n "$PREFIX_LEN" ]]; then
        printf '%s/%s' "$INTERNAL_IP" "$PREFIX_LEN"
    fi
}
export -f getInternalCIDR

# $1 == cmd as executed in systemd (by ExecStart=)
# notes: take precaution when adding long running functions as they will block startup in boot order
# notes: adding init commands on an AMI instance must not be long running processes, otherwise they will fail
function addInitCmd() {
    local CMD=$(printf '%s' "$1" | sed -e 's|[\/&]|\\&|g') # escape string
    local TMP_FILE="${DSIP_INIT_FILE}.tmp"

    # sanity check, does the entry already exist?
    grep -q -oP "^ExecStart\=.*${CMD}.*" 2>/dev/null ${DSIP_INIT_FILE} && return 0

    tac ${DSIP_INIT_FILE} | sed -r "0,\|^ExecStart\=.*|{s|^ExecStart\=.*|ExecStart=${CMD}\n&|}" | tac > ${TMP_FILE}
    mv -f ${TMP_FILE} ${DSIP_INIT_FILE}

    systemctl daemon-reload
}
export -f addInitCmd

# $1 == string to match for removal (after ExecStart=)
function removeInitCmd() {
    local STR=$(printf '%s' "$1" | sed -e 's|[\/&]|\\&|g') # escape string

    sed -i -r "\|^ExecStart\=.*${STR}.*|d" ${DSIP_INIT_FILE}
    systemctl daemon-reload
}
export -f removeInitCmd

# $1 == service name (full name with target) to add dependency on dsip-init service
# notes: only adds startup ordering dependency (service continues if init fails)
# notes: the Before= section of init will link to an After= dependency on daemon-reload
function addDependsOnInit() {
    local SERVICE="$1"

    # sanity check, does the entry already exist?
    grep -q -oP "^(Before\=|Wants\=).*${SERVICE}.*" 2>/dev/null ${DSIP_INIT_FILE} && return 0

    perl -i -e "\$service='$SERVICE';" -pe 's%^(Before\=|Wants\=)(.*)%length($2)==0 ? "${1}${service}" : "${1}${2} ${service}"%ge;' ${DSIP_INIT_FILE}
    systemctl daemon-reload
}
export -f addDependsOnInit

# $1 == service name (full name with target) to remove dependency on dsip-init service
function removeDependsOnInit() {
    local SERVICE="$1"

    perl -i -e "\$service='$SERVICE';" -pe 's%^((?:Before\=|Wants\=).*?)( ${service}|${service} |${service})(.*)%\1\3%g;' ${DSIP_INIT_FILE}
    systemctl daemon-reload
}
export -f removeDependsOnInit

# $1 == ip or hostname
# $2 == port (optional)
# returns: 0 == connection good, 1 == connection bad
# NOTE: if port is not given a ping test will be used instead
function checkConn() {
    local TIMEOUT=3 IP_ADDR="" PING_V6_SELECTOR=""

    if (( $# == 2 )); then
        timeout $TIMEOUT bash -c "< /dev/tcp/$1/$2" &>/dev/null; return $?
    else
        # NOTE: older versions of ping don't automatically detect IP address version
        IP_ADDR=$(getent hosts "$1" 2>/dev/null | awk '{ print $1 ; exit }')
        if ipv6Test "$IP_ADDR"; then
            PING_V6_SELECTOR="-6"
        fi
        ping $PING_V6_SELECTOR -q -W $TIMEOUT -c 3 "$1" &>/dev/null; return $?
    fi
}
export -f checkConn

# $@ == ssh command to test
# returns: 0 == ssh connected, 1 == ssh could not connect
function checkSSH() {
    local SSH_CMD="$@ -o ConnectTimeout=5 -q 'exit 0'"
    bash -c "${SSH_CMD}" 2>&1 > /dev/null; return $?
}
export -f checkSSH

# usage: checkDB [options] <database>
# options:  --user=<mysql user>
#           --pass=<mysql password>
#           --host=<mysql host>
#           --port=<mysql port>
# returns:  0 if DB exists, 1 otherwise
function checkDB() {
    local MYSQL_DBNAME=""
    local MYSQL_USER=${MYSQL_USER:-root}
    local MYSQL_PASS=${MYSQL_PASS:-}
    local MYSQL_HOST=${MYSQL_HOST:-localhost}
    local MYSQL_PORT=${MYSQL_PORT:-3306}

    while (( $# > 0 )); do
        # last arg is database
        if (( $# == 1 )); then
            MYSQL_DBNAME="$1"
            shift
            break
        fi

        case "$1" in
            --user*)
                MYSQL_USER=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --pass*)
                MYSQL_PASS=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --host*)
                MYSQL_HOST=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --port*)
                MYSQL_PORT=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            *)  # not valid option skip
                shift
                ;;
        esac
    done

    local CHECK=$(mysql -sN --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" \
        -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$MYSQL_DBNAME';" 2>/dev/null)
    if [[ -n "$CHECK" ]]; then
        return 0
    fi
    return 1
}
export -f checkDB

# usage: checkDBUserExists [options] <user>@<host>
# options:  --user=<mysql user>
#           --pass=<mysql password>
#           --host=<mysql host>
#           --port=<mysql port>
# notes: make sure to test for proper DB connection
# returns: 0 if user exists, 1 on DB connection failure, 2 if user does not exist
function checkDBUserExists() {
    local MYSQL_CHECK_USER=""
    local MYSQL_CHECK_HOST=""
    local MYSQL_USER=${MYSQL_USER:-root}
    local MYSQL_PASS=${MYSQL_PASS:-}
    local MYSQL_HOST=${MYSQL_HOST:-localhost}
    local MYSQL_PORT=${MYSQL_PORT:-3306}

    while (( $# > 0 )); do
        # last arg is user and database
        if (( $# == 1 )); then
            MYSQL_CHECK_USER=$(printf '%s' "$1" | cut -d '@' -f 1)
            MYSQL_CHECK_HOST=$(printf '%s' "$1" | cut -d '@' -f 2)
            shift
            break
        fi

        case "$1" in
            --user*)
                MYSQL_USER=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --pass*)
                MYSQL_PASS=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --host*)
                MYSQL_HOST=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --port*)
                MYSQL_PORT=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            *)  # not valid option skip
                shift
                ;;
        esac
    done

    return $(mysql -sN -A --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" \
        -e "SELECT IF(EXISTS(SELECT 1 FROM mysql.user WHERE User='${MYSQL_CHECK_USER}' AND Host='${MYSQL_CHECK_HOST}'),0,2);" 2>/dev/null)
}
export -f checkDBUserExists

# usage: dumpDB [options] <database>
# options:  --user=<mysql user>
#           --pass=<mysql password>
#           --host=<mysql host>
#           --port=<mysql port>
# output: dumped database as sql (redirect as needed)
# returns: 0 on success, non zero otherwise
function dumpDB() {
    local MYSQL_DBNAME=""
    local MYSQL_USER=${MYSQL_USER:-root}
    local MYSQL_PASS=${MYSQL_PASS:-}
    local MYSQL_HOST=${MYSQL_HOST:-localhost}
    local MYSQL_PORT=${MYSQL_PORT:-3306}

    while (( $# > 0 )); do
        # last arg is database
        if (( $# == 1 )); then
            MYSQL_DBNAME="$1"
            shift
            break
        fi

        case "$1" in
            --user*)
                MYSQL_USER=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --pass*)
                MYSQL_PASS=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --host*)
                MYSQL_HOST=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --port*)
                MYSQL_PORT=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            *)  # not valid option skip
                shift
                ;;
        esac
    done

    (mysqldump --single-transaction --opt --routines --triggers --hex-blob \
        --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" --databases ${MYSQL_DBNAME} 2>/dev/null \
        | sed -r -e 's|DEFINER=[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']@[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']||g' -e 's|ENGINE=MyISAM|ENGINE=InnoDB|g';
        exit ${PIPESTATUS[0]}; ) 2>/dev/null
    return $?
}
export -f dumpDB

# usage: dumpDBUser [options] <user>@<database>
# options:  --user=<mysql user>
#           --pass=<mysql password>
#           --host=<mysql host>
#           --port=<mysql port>
# output: dumped database user as sql (redirect as needed)
# returns: 0 on success, non zero otherwise
function dumpDBUser() {
    local MYSQL_DBNAME=""
    local MYSQL_DBUSER=""
    local MYSQL_USER=${MYSQL_USER:-root}
    local MYSQL_PASS=${MYSQL_PASS:-}
    local MYSQL_HOST=${MYSQL_HOST:-localhost}
    local MYSQL_PORT=${MYSQL_PORT:-3306}

    while (( $# > 0 )); do
        # last arg is user and database
        if (( $# == 1 )); then
            MYSQL_DBUSER=$(printf '%s' "$1" | cut -d '@' -f 1)
            MYSQL_DBNAME=$(printf '%s' "$1" | cut -d '@' -f 2)
            shift
            break
        fi

        case "$1" in
            --user*)
                MYSQL_USER=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --pass*)
                MYSQL_PASS=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --host*)
                MYSQL_HOST=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --port*)
                MYSQL_PORT=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            *)  # not valid option skip
                shift
                ;;
        esac
    done

    (mysql -sN -A --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" \
        -e "SELECT DISTINCT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user='${MYSQL_DBUSER}'" 2>/dev/null \
        | mysql -sN -A --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" 2>/dev/null \
        | sed 's/$/;/g' \
        | awk '!x[$0]++' &&
        printf '%s\n' 'FLUSH PRIVILEGES;';
        exit ${PIPESTATUS[0]}; ) 2>/dev/null
    return $?
}
export -f dumpDBUser

# usage: sqlAsTransaction [options] <database>
# options:  --user=<mysql user>
#           --pass=<mysql password>
#           --host=<mysql host>
#           --port=<mysql port>
#           --db=<mysql database name>
# returns:  0 if DB exists, 1 otherwise
function sqlAsTransaction() {
    local MYSQL_DBNAME
    local MYSQL_USER=${MYSQL_USER:-root}
    local MYSQL_PASS=${MYSQL_PASS:-}
    local MYSQL_HOST=${MYSQL_HOST:-localhost}
    local MYSQL_PORT=${MYSQL_PORT:-3306}
    local SQL_STATEMENTS=()

    while (( $# > 0 )); do
        case "$1" in
            --user*)
                MYSQL_USER=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --pass*)
                MYSQL_PASS=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --host*)
                MYSQL_HOST=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --port*)
                MYSQL_PORT=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            --db*)
                MYSQL_DBNAME=$(printf '%s' "$1" | cut -d '=' -f 2-)
                shift
                ;;
            *)  # all positional args are part of SQL query
                SQL_STATEMENTS+=("$1")
                shift
                ;;
        esac
    done

    # creating the procedure will fail if we don't select a database
    MYSQL_DBNAME=${MYSQL_DBNAME:-mysql}

    # if query was piped to stdin use that instead of positional args
    if [[ ! -t 0 ]]; then
        SQL_STATEMENTS=( $(</dev/stdin) )
    fi

    local STATUS=$(mysql -sN --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" ${MYSQL_DBNAME} 2>/dev/null << EOF
DROP PROCEDURE IF EXISTS tryStatements;
DELIMITER //
CREATE PROCEDURE tryStatements(OUT ret BOOL)
BEGIN
    DECLARE error_occurred BOOL DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET error_occurred = 1;
    START TRANSACTION;

    ${SQL_STATEMENTS[@]}

    IF error_occurred THEN
        ROLLBACK;
    ELSE
        COMMIT;
    END IF;

    set ret = error_occurred;
END //
DELIMITER ;

CALL tryStatements(@ret);
DROP PROCEDURE tryStatements;

select @ret;
EOF
    )

    # in case we had an error connecting
    STATUS=$((STATUS + $?))

    return $STATUS
}
export -f sqlAsTransaction

# usage: parseDBConnURI <field> <connection uri>
# field:    -user
#           -pass
#           -host
#           -port
#           -name
# output: the selected field of the connection uri
# returns: 0 on success, non zero otherwise
function parseDBConnURI() {
    # parse based on
    case "$1" in
        -user)
            shift
            perl -pe 's%(?:([^:@\t\r\n\v\f]*)(?::([^@\t\r\n\v\f]*))?@)?([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\1%' <<<"$1"
            ;;
        -pass)
            shift
            perl -pe 's%(?:([^:@\t\r\n\v\f]*)(?::([^@\t\r\n\v\f]*))?@)?([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\2%' <<<"$1"
            ;;
        -host)
            shift
            perl -pe 's%(?:([^:@\t\r\n\v\f]*)(?::([^@\t\r\n\v\f]*))?@)?([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\3%' <<<"$1"
            ;;
        -port)
            shift
            perl -pe 's%(?:([^:@\t\r\n\v\f]*)(?::([^@\t\r\n\v\f]*))?@)?([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\4%' <<<"$1"
            ;;
        -name)
            shift
            perl -pe 's%(?:([^:@\t\r\n\v\f]*)(?::([^@\t\r\n\v\f]*))?@)?([^:/\t\r\n\v\f]+)(?::([^/\t\r\n\v\f]*))?(?:/(.+))?%\5%' <<<"$1"
            ;;
        *)  # not valid field
            return 1
            ;;
    esac

    # valid field selected
    return 0
}
export -f parseDBConnURI

# $1 == number of characters to get
# output: string of random printable characters
function urandomChars() {
	local LEN=32 FILTER="a-zA-Z0-9"

    while (( $# > 0 )); do
    	# last arg is length
        if (( $# == 1 )) && [[ -z "$CREDS" ]]; then
			LEN="$1"
			shift
            break
        fi

        case "$1" in
        	# user defined salt
            -f)
                shift
                FILTER="$1"
                shift
                ;;
			# not valid option skip
            *)
                shift
                ;;
        esac
    done

    tr -dc "$FILTER" </dev/urandom | dd if=/dev/stdin of=/dev/stdout bs=1 count="$LEN" 2>/dev/null
}
export -f urandomChars

# $1 == prefix for each arg
# $2 == delimiter between args
# $3 == suffix for each arg
# $@ == args to join
function joinwith() {
    local START="$1" IFS="$2" END="$3" ARR=()
    shift;shift;shift

    for VAR in "$@"; do
        ARR+=("${START}${VAR}${END}")
    done

    echo "${ARR[*]}"
}
export -f joinwith

# $1 == rpc command
# $@ == rpc args
# output: output returned from kamailio
# returns: curl return code (ref: man 1 curl)
# note: curl will timeout after 3 seconds
function sendKamCmd() {
    local CMD="$1" PARAMS="" KAM_API_URL='http://127.0.0.1:5060/api/kamailio'
    shift
    local ARGS=("$@")

    if [[ "$CMD" == "cfg.seti" ]]; then
        local LAST_ARG="${ARGS[$#-1]}"
        unset "ARGS[$#-1]"
        PARAMS='['$(joinwith '"' ',' '"' "${ARGS[@]}")",${LAST_ARG}"']'
    else
        PARAMS='['$(joinwith '"' ',' '"' "$@")']'
    fi

    curl -s -m 3 -X GET -d '{"method": "'"${CMD}"'", "jsonrpc": "2.0", "id": 1, "params": '"${PARAMS}"'}' ${KAM_API_URL}
}
export -f sendKamCmd

# TODO: input validation
# TODO: swap with bash native version?
function hashCreds() {
	local CREDS SALT DK_LEN
	local PYTHON=${PYTHON_CMD:-python3}

	# grab credentials from stdin if provided
	if [[ ! -t 0 ]]; then
		CREDS=$(</dev/stdin)
	fi

    while (( $# > 0 )); do
    	# last arg is credentials
        if (( $# == 1 )) && [[ -z "$CREDS" ]]; then
			CREDS="$1"
			shift
            break
        fi

        case "$1" in
        	# user defined salt
            -s)
                shift
                SALT="$1"
                shift
                ;;
        	# user defined derived key length
            -l)
                shift
                DK_LEN="$1"
                shift
                ;;
			# not valid option skip
            *)
                shift
                ;;
        esac
    done

    # defaults if not set by args
    SALT=${SALT:-$(urandomChars -f 'a-fA-F0-9' $SALT_LEN)}
    DK_LEN=${DK_LEN:-$DK_LEN_DEFAULT}

	# python native version
	# no external dependencies other than vanilla python3
	${PYTHON} -c "import hashlib,binascii; print(binascii.hexlify(hashlib.pbkdf2_hmac('sha512', '$CREDS'.encode('utf-8'), '$SALT'.encode('utf-8'), iterations=$HASH_ITERATIONS, dklen=$DK_LEN)).decode('utf-8'));"
	# bash native version
	# currently too slow for production usage
	#${DSIP_PROJECT_DIR}/dsiprouter/pbkdf2.sh 'sha512' "$CREDS" "$SALT" "$HASH_ITERATIONS" 4
}
export -f hashCreds
