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
export DSIP_INIT_FILE="/etc/systemd/system/dsip-init.service"
DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(dirname $(dirname $(readlink -f "$BASH_SOURCE")))}

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
        ${PYTHON} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); import sys; sys.path.insert(0, '/etc/dsiprouter/gui'); import settings; from util.security import AES_CTR; print(AES_CTR.decrypt(settings.${NAME}).decode('utf-8'), end='')"
    fi
}
export -f decryptConfigAttrib

# $1 == feature name
# $2 == kamailio config file
function enableKamailioConfigFeature() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s~#+(!(define|trydef|redefine)[[:space:]]? $NAME)~#\1~g" ${CONFIG_FILE}
}
export -f enableKamailioConfigFeature

# $1 == feature name
# $2 == kamailio config file
function disableKamailioConfigFeature() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s~#+(!(define|trydef|redefine)[[:space:]]? $NAME)~##\1~g" ${CONFIG_FILE}
}
export -f disableKamailioConfigFeature

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

# $1 == name of define to change
# $2 ==
# $3 == kamailio config file
# $4 == -q (quote as string)
function setKamailioConfigDef() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    if [[ "$4" == "-q" ]]; then
        VALUE='"'"${VALUE}"'"'
    fi

    perl -e "\$name='${NAME}'; \$value='${VALUE}';" \
        -i -pe 's%(#+\!)(define|trydef|redefine)([ \t]+${name}[ \t]+).*%\1\2\3${value}%g' ${CONFIG_FILE}
}
export -f setKamailioConfigDef

# $1 == name of substdef to change
# $2 == value to change substdef to
# $3 == kamailio config file
function setKamailioConfigSubstdef() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    sed -i -r -e "s~(#!substdef.*!$NAME!).*(!.*)~\1$VALUE\2~g" ${CONFIG_FILE}
}
export -f setKamailioConfigSubstdef

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
# $2 == value of attribute
# $3 == rtpengine config file
function setRtpengineConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    sed -i -r -e "s|(${NAME}\s?=\s?.*)|$NAME = $VALUE|g" ${CONFIG_FILE}
}
export -f setRtpengineConfigAttrib

# output: Linux Distro name
function getDisto() {
    cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d '=' -f 2 | cut -d '"' -f 2
}
export -f getDisto

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
export -f isInstanceVULTR

# output: instance ID || blank string
# notes: we try checking for exported instance variable avoid querying again
function getInstanceID() {
    if (( ${AWS_ENABLED:-0} == 1)); then
        curl -s -f http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null ||
        ec2-metadata -i 2>/dev/null
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
            ec2-metadata -i 2>/dev/null
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
    crontab -l | { cat; echo "$ENTRY"; } | crontab -
}
export -f cronAppend

# $1 == crontab entry to remove
function cronRemove() {
    local ENTRY="$1"
    crontab -l | grep -v -F -w "$ENTRY" | crontab -
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

# output: the internal IP for this system
# notes: prints internal ip, or empty string if not available
# notes: tries ipv4 first then ipv6
function getInternalIP() {
    local IPV6_ENABLED=${IPV6_ENABLED:-0}

    local IP=$(ip -4 route get $GOOGLE_DNS_IPV4 2>/dev/null | head -1 | grep -oP 'src \K([^\s]+)')
    if (( ${IPV6_ENABLED} == 1 )) && [[ -z "$IP" ]]; then
        IP=$(ip -6 route get $GOOGLE_DNS_IPV6 2>/dev/null | head -1 | grep -oP 'src \K([^\s]+)')
    fi
    printf '%s' "$IP"
}
export -f getInternalIP

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
    local IPV6_ENABLED=${IPV6_ENABLED:-0}
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

    for URL in ${IPV4_URLS[@]}; do
        EXTERNAL_IP=$(curl -4 -s --connect-timeout $TIMEOUT $URL 2>/dev/null)
        ipv4Test "$EXTERNAL_IP" && break || EXTERNAL_IP=""
    done

    if (( ${IPV6_ENABLED} == 1 )) && [[ -z "$EXTERNAL_IP" ]]; then
        for URL in ${IPV6_URLS[@]}; do
            EXTERNAL_IP=$(curl -6 -s --connect-timeout $TIMEOUT $URL 2>/dev/null)
            ipv6Test "$EXTERNAL_IP" && break || EXTERNAL_IP=""
        done
    fi

    printf '%s' "$EXTERNAL_IP"
}
export -f getExternalIP

# output: the internal FQDN for this system
# notes: prints internal FQDN, or empty string if not available
function getInternalFQDN() {
    printf '%s' "$(hostname -f 2>/dev/null || hostname)"
}
export -f getInternalFQDN

# output: the external FQDN for this system
# notes: prints external FQDN, or empty string if not available
# notes: will use EXTERNAL_IP if available or look it up dynamically
# notes: tries ipv4 first then ipv6
function getExternalFQDN() {
    local IPV6_ENABLED=${IPV6_ENABLED:-0}

    local EXTERNAL_IP=${EXTERNAL_IP:-$(getExternalIP)}
    local EXTERNAL_FQDN=$(dig @${GOOGLE_DNS_IPV4} +short -x ${EXTERNAL_IP} 2>/dev/null | head -1 | sed 's/\.$//')
    if (( ${IPV6_ENABLED} == 1 )) && [[ -z "$EXTERNAL_FQDN" ]]; then
          EXTERNAL_FQDN=$(dig @${GOOGLE_DNS_IPV6} +short -x ${EXTERNAL_IP} 2>/dev/null | head -1 | sed 's/\.$//')
    fi

    printf '%s' "$EXTERNAL_FQDN"
}
export -f getExternalFQDN

# output: the internal IP CIDR for this system
# notes: prints internal CIDR address, or empty string if not available
# notes: tries ipv4 first then ipv6
function getInternalCIDR() {
    local IPV6_ENABLED=${IPV6_ENABLED:-0}
    local PREFIX_LEN="" DEF_IFACE=""
    local IP=$(ip -4 route get $GOOGLE_DNS_IPV4 2>/dev/null | head -1 | grep -oP 'src \K([^\s]+)')

    # if ipv4 stack returned good result use it, otherwise try ipv6
    if [[ -n "$IP" ]]; then
        DEF_IFACE=$(ip -4 route list scope global 2>/dev/null | perl -e 'while (<>) { if (s%^(?:0\.0\.0\.0|default).*dev (\w+).*$%\1%) { print; exit; } }')
        PREFIX_LEN=$(ip -4 route list | grep "dev $DEF_IFACE" | perl -e 'while (<>) { if (s%^(?!0\.0\.0\.0|default).*/(\d+) .*src [\w/.]*.*$%\1%) { print; exit; } }')
    elif (( ${IPV6_ENABLED} == 1 )); then
        IP=$(ip -6 route get $GOOGLE_DNS_IPV6 2>/dev/null | head -1 | grep -oP 'src \K([^\s]+)')
        DEF_IFACE=$(ip -6 route list scope global 2>/dev/null | perl -e 'while (<>) { if (s%^(?:::/0|default).*dev (\w+).*$%\1%) { print; exit; } }')
        PREFIX_LEN=$(ip -6 route list 2>/dev/null | grep "dev $DEF_IFACE" | perl -e 'while (<>) { if (s%^(?!::/0|default).*/(\d+) .*via [\w:/.]*.*$%\1%) { print; exit; } }')
    fi

    # make sure output is empty if error occurred
    if [[ -z "$IP" || -z "$PREFIX_LEN" ]]; then
        echo -n ''
    else
        printf '%s/%s' "$IP" "$PREFIX_LEN"
    fi
}
export -f getInternalCIDR

# $1 == host to resolve
# $2 == -a (return all resolved IPs)
# output: IP address(es) of host
function hostToIP() {
    local IPV6_ENABLED=${IPV6_ENABLED:-0}
    local HOST="$1"

    local IP_ADDR=$(dig @${GOOGLE_DNS_IPV4} +short A ${HOST} 2>/dev/null)
    if (( ${IPV6_ENABLED} == 1 )) && [[ -z "$EXTERNAL_FQDN" ]]; then
        IP_ADDR=$(dig @${GOOGLE_DNS_IPV6} +short AAAA ${HOST} 2>/dev/null | head -1 | sed 's/\.$//')
    fi

    if [[ "$2" == "-a" ]]; then
        echo -n "$IP_ADDR"
    else
        echo -n "$IP_ADDR" | head -1
    fi
}
export -f hostToIP

# $1 == cmd as executed in systemd (by ExecStart=)
# notes: take precaution when adding long running functions as they will block startup in boot order
# notes: adding init commands on an AMI instance must not be long running processes, otherwise they will fail
function addInitCmd() {
    local CMD=$(printf '%s' "$1" | sed -e 's|[\/&]|\\&|g') # escape string
    local TMP_FILE="${DSIP_INIT_FILE}.tmp"

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
    local TMP_FILE="${DSIP_INIT_FILE}.tmp"

    tac ${DSIP_INIT_FILE} | sed -r "0,\|^Before\=.*|{s|^Before\=.*|Before=${SERVICE}\n&|}" | tac > ${TMP_FILE}
    mv -f ${TMP_FILE} ${DSIP_INIT_FILE}
    systemctl daemon-reload
}
export -f addDependsOnInit

# $1 == service name (full name with target) to remove dependency on dsip-init service
function removeDependsOnInit() {
    local SERVICE="$1"

    sed -i "\|^Before=${SERVICE}|d" ${DSIP_INIT_FILE}
    systemctl daemon-reload
}
export -f removeDependsOnInit

# $1 == ip or hostname
# $2 == port
# returns: 0 == connection good, 1 == connection bad
# note: timeout is set to 3 sec
function checkConn() {
    if cmdExists 'nc'; then
        nc -w 3 "$1" "$2" < /dev/null &>/dev/null; return $?
    else
        timeout 3 bash -c "< /dev/tcp/$1/$2" &>/dev/null; return $?
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
    local MYSQL_DBNAME=""
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
    local LEN="$1"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w ${LEN} 2>/dev/null | head -n 1
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
