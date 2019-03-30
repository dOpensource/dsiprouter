#!/usr/bin/env bash
#set -x

# NOTES:
# contains utility functions and shared variables
# should be sourced by an external script

######################
# Imported Constants #
######################

# Ansi Colors
ESC_SEQ="\033["
ANSI_NONE="${ESC_SEQ}39;49;00m" # Reset colors
ANSI_RED="${ESC_SEQ}1;31m"
ANSI_GREEN="${ESC_SEQ}1;32m"
ANSI_YELLOW="${ESC_SEQ}1;33m"
ANSI_CYAN="${ESC_SEQ}1;36m"

# Constants for imported functions
DSIP_INIT_FILE="/etc/systemd/system/dsip-init.service"

##############################################
# Printing functions and String Manipulation #
##############################################

printerr() {
    if [[ "$1" == "-n" ]]; then
        shift; printf "%b%s%b" "${ANSI_RED}" "$*" "${ANSI_NONE}"
    else
        printf "%b%s%b\n" "${ANSI_RED}" "$*" "${ANSI_NONE}"
    fi
}

printwarn() {
    if [[ "$1" == "-n" ]]; then
        shift; printf "%b%s%b" "${ANSI_YELLOW}" "$*" "${ANSI_NONE}"
    else
        printf "%b%s%b\n" "${ANSI_YELLOW}" "$*" "${ANSI_NONE}"
    fi
}

printdbg() {
    if [[ "$1" == "-n" ]]; then
        shift; printf "%b%s%b" "${ANSI_GREEN}" "$*" "${ANSI_NONE}"
    else
        printf "%b%s%b\n" "${ANSI_GREEN}" "$*" "${ANSI_NONE}"
    fi
}

pprint() {
    if [[ "$1" == "-n" ]]; then
        shift; printf "%b%s%b" "${ANSI_CYAN}" "$*" "${ANSI_NONE}"
    else
        printf "%b%s%b\n" "${ANSI_CYAN}" "$*" "${ANSI_NONE}"
    fi
}

######################################
# Traceback / Debug helper functions #
######################################

backtrace() {
    local DEPTN=${#FUNCNAME[@]}

    for ((i=1; i < ${DEPTN}; i++)); do
        local FUNC="${FUNCNAME[$i]}"
        local LINE="${BASH_LINENO[$((i-1))]}"
        local SRC="${BASH_SOURCE[$((i-1))]}"
        printf '%*s' $i '' # indent
        printerr "[ERROR]: ${FUNC}(), ${SRC}, line: ${LINE}"
    done
}

setErrorTracing() {
    set -o errtrace
    trap 'backtrace' ERR
}

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
# $4 == whether to 'quote' value (use for strings)
setConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    if (( $# >= 4 )); then
        VALUE="'${VALUE}'"
    fi
    sed -i -r -e "s|($NAME[[:space:]]?=[[:space:]]?.*)|$NAME = $VALUE|g" ${CONFIG_FILE}
}

# $1 == attribute name
# $2 == python config file
# returns: attribute value
getConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    local VALUE=$(grep -oP '^(?!#)(?:'${NAME}')[ \t]*=[ \t]*\K(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|""".*"""[ \t]*$|'"'''.*'''"'[ \v]*$|".*"[ \t]*$|'"'.*'"')' ${CONFIG_FILE})
    printf "$VALUE" | sed -r 's|^["'"'"']+(.+?)["'"'"']+$|\1|g'
}

# $1 == attribute name
# $2 == kamailio config file
enableKamailioConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s/#+(!(define|trydef|redefine)[[:space:]]? $NAME)/#\1/g" ${CONFIG_FILE}
}

# $1 == attribute name
# $2 == kamailio config file
disableKamailioConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s/#+(!(define|trydef|redefine)[[:space:]]? $NAME)/##\1/g" ${CONFIG_FILE}
}

# $1 == name of ip to change
# $2 == value to change ip to
# $3 == kamailio config file
setKamailioConfigIP() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    sed -i -r -e "s|(#!substdef.*!$NAME!).*(!.*)|\1$VALUE\2|g" ${CONFIG_FILE}
}

# $1 == attribute name
# $2 == value of attribute
# $3 == rtpengine config file
setRtpengineConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    sed -i -r -e "s|($NAME[[:space:]]?=[[:space:]]?.*)|$NAME = $VALUE|g" ${CONFIG_FILE}
}

# notes: prints out Linux Distro name
getDisto() {
    cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d '=' -f 2 | cut -d '"' -f 2
}

# $1 == command to test
# returns: 0 == true, 1 == false
cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# $1 == directory to check for in PATH
# returns: 0 == found, 1 == not found
pathCheck() {
    case ":${PATH-}:" in
        *:"$1":*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# returns: AMI instance ID || blank string
getInstanceID() {
    curl http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null ||
    ec2-metadata -i 2>/dev/null
}

# $1 == crontab entry to append
cronAppend() {
    local ENTRY="$1"
    crontab -l | { cat; echo "$ENTRY"; } | crontab -
}

# $1 == crontab entry to remove
cronRemove() {
    local ENTRY="$1"
    crontab -l | grep -v -F -w "$ENTRY" | crontab -
}

# $1 == ip to test
# returns: 0 == success, 1 == failure
ipv4Test() {
    local IP="$1"

    if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        IP=($IP)
        if (( ${IP[0]} <= 255 && ${IP[1]} <= 255 && ${IP[2]} <= 255 && ${IP[3]} <= 255 )); then
            return 0
        fi
    fi
    return 1
}

# notes: prints external ip, or empty string if not available
getExternalIP() {
    local EXTERNAL_IP=""
    local URLS=(
        "https://ipv4.icanhazip.com"
        "https://api.ipify.org"
        "https://myexternalip.com/raw"
        "https://ipecho.net/plain"
        "https://bot.whatismyipaddress.com"
    )

    for URL in ${URLS[@]}; do
        EXTERNAL_IP=$(curl -s --connect-timeout 2 $URL 2>/dev/null)
        ipv4Test "$EXTERNAL_IP" && break
    done

    printf '%s' "$EXTERNAL_IP"
}

# $1 == cmd as executed in systemd (by ExecStart=)
# notes: take precaution when adding long running functions as they will block startup in boot order
# notes: adding init commands on an AMI instance must not be long running processes, otherwise they will fail
addInitCmd() {
    local CMD=$(printf '%s' "$1" | sed -e 's|[\/&]|\\&|g') # escape string
    local TMP_FILE="${DSIP_INIT_FILE}.tmp"

    tac ${DSIP_INIT_FILE} | sed -r "0,\|^ExecStart\=.*|{s|^ExecStart\=.*|ExecStart=${CMD}\n&|}" | tac > ${TMP_FILE}
    mv -f ${TMP_FILE} ${DSIP_INIT_FILE}

    systemctl daemon-reload
}

# $1 == string to match for removal (after ExecStart=)
removeInitCmd() {
    local STR=$(printf '%s' "$1" | sed -e 's|[\/&]|\\&|g') # escape string

    sed -i -r "\|^ExecStart\=.*${STR}.*|d" ${DSIP_INIT_FILE}
    systemctl daemon-reload
}

# $1 == service name (full name with target) to add dependency on dsip-init service
# notes: only adds startup ordering dependency (service continues if init fails)
# notes: the Before= section of init will link to an After= dependency on daemon-reload
addDependsOnInit() {
    local SERVICE="$1"
    local TMP_FILE="${DSIP_INIT_FILE}.tmp"

    tac ${DSIP_INIT_FILE} | sed -r "0,\|^Before\=.*|{s|^Before\=.*|Before=${SERVICE}\n&|}" | tac > ${TMP_FILE}
    mv -f ${TMP_FILE} ${DSIP_INIT_FILE}
    systemctl daemon-reload
}

# $1 == service name (full name with target) to remove dependency on dsip-init service
removeDependsOnInit() {
    local SERVICE="$1"

    sed -i "\|^Before=${SERVICE}|d" ${DSIP_INIT_FILE}
    systemctl daemon-reload
}