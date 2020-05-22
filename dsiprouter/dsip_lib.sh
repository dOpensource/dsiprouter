#!/usr/bin/env bash

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
DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}

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
# $4 == -q (quote string) | -qb (quote byte string)
setConfigAttrib() {
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

# $1 == attribute name
# $2 == python config file
# output: attribute value
getConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    local VALUE=$(grep -oP '^(?!#)(?:'${NAME}')[ \t]*=[ \t]*\K(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|b?""".*"""[ \t]*$|'"b?'''.*'''"'[ \v]*$|b?".*"[ \t]*$|'"b?'.*'"')' ${CONFIG_FILE})
    printf '%s' "${VALUE}" | perl -0777 -pe 's~^b?["'"'"']+(.*?)["'"'"']+$|(.*)~\1\2~g'
}

# $1 == attribute name
# $2 == python config file
# output: attribute value decrypted
# notes: if value is not encrypted the value is output instead
decryptConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"
    local PYTHON=${PYTHON_CMD:-python3}

    local VALUE=$(grep -oP '^(?!#)(?:'${NAME}')[ \t]*=[ \t]*\K(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|b?""".*"""[ \t]*$|'"b?'''.*'''"'[ \v]*$|b?".*"[ \t]*$|'"b?'.*'"')' ${CONFIG_FILE})
    # if value is not a byte literal it isn't encrypted
    if ! printf '%s' "${VALUE}" | grep -q -oP '(b""".*"""|'"b'''.*'''"'|b".*"|'"b'.*')"; then
        printf '%s' "${VALUE}" | perl -0777 -pe 's~^b?["'"'"']+(.*?)["'"'"']+$|(.*)~\1\2~g'
    else
        ${PYTHON} -c "import os; os.chdir('${DSIP_PROJECT_DIR}/gui'); import settings; from util.security import AES_CTR; print(AES_CTR.decrypt(settings.${NAME}).decode('utf-8'), end='')"
    fi
}

# $1 == attribute name
# $2 == kamailio config file
enableKamailioConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s~#+(!(define|trydef|redefine)[[:space:]]? $NAME)~#\1~g" ${CONFIG_FILE}
}

# $1 == attribute name
# $2 == kamailio config file
disableKamailioConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s~#+(!(define|trydef|redefine)[[:space:]]? $NAME)~##\1~g" ${CONFIG_FILE}
}

# $1 == name of defined url to change
# $2 == value to change url to
# $3 == kamailio config file
# notes: will skip any cluster url attributes
setKamailioConfigDburl() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    perl -e "\$dburl='${VALUE}';" \
        -0777 -i -pe 's~(#!(define|trydef|redefine)\s+?'"${NAME}"'\s+)['"'"'"](?!cluster\:).*['"'"'"]~\1"${dburl}"~g' ${CONFIG_FILE}
}

# $1 == name of substdef to change
# $2 == value to change substdef to
# $3 == kamailio config file
setKamailioConfigSubstdef() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    sed -i -r -e "s~(#!substdef.*!$NAME!).*(!.*)~\1$VALUE\2~g" ${CONFIG_FILE}
}

# $1 == name of global variable to change
# $2 == value to change variable to
# $3 == kamailio config file
setKamailioConfigGlobal() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"
    local REPLACE_TOKEN='__ABCDEFGHIJKLMNOPQRSTUVWXYZ__'

    perl -pi -e "s~^(${NAME}\s?=\s?)(?:(\"|')(.*?)(\"|')|\d+)(\sdesc\s(?:\"|').*?(?:\"|'))?~\1\2${REPLACE_TOKEN}\4\5~g" ${CONFIG_FILE}
    sed -i -e "s%${REPLACE_TOKEN}%${VALUE}%g" ${CONFIG_FILE}
}

# $1 == attribute name
# $2 == value of attribute
# $3 == rtpengine config file
setRtpengineConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    sed -i -r -e "s|(${NAME}\s?=\s?.*)|$NAME = $VALUE|g" ${CONFIG_FILE}
}

# output: Linux Distro name
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

# returns: 0 == success, otherwise failure
# notes: try to access the AWS metadata URL to determine if this is an AMI instance
isInstanceAMI() {
    curl -s -f --connect-timeout 2 http://169.254.169.254/latest/dynamic/instance-identity/ &>/dev/null
    return $?
}

# returns: 0 == success, otherwise failure
# notes: try to access the DO metadata URL to determine if this is an Digital Ocean instance
isInstanceDO() {
    curl -s -f --connect-timeout 2 http://169.254.169.254/metadata/v1/ &>/dev/null
    return $?
}

# returns: 0 == success, otherwise failure
# notes: try to access the GCE metadata URL to determine if this is an Google instance
isInstanceGCE() {
    curl -s -f --connect-timeout 2 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/ &>/dev/null
    return $?
}

# returns: 0 == success, otherwise failure
# notes: try to access the MS Azure metadata URL to determine if this is an Azure instance
isInstanceAZURE() {
    curl -s -f --connect-timeout 2 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2018-10-01" &>/dev/null
    return $?
}

# output: instance ID || blank string
# notes: we try checking for exported instance variable avoid querying again
getInstanceID() {
    if (( ${AWS_ENABLED:-0} == 1)); then
        curl http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null ||
        ec2-metadata -i 2>/dev/null
    elif (( ${DO_ENABLED:-0} == 1 )); then
        curl http://169.254.169.254/metadata/v1/id 2>/dev/null
    elif (( ${GCE_ENABLED:-0} == 1 )); then
        curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id 2>/dev/null
    elif (( ${AZURE_ENABLED:-0} == 1 )); then
        curl -H "Metadata: true" "http://169.254.169.254/metadata/instance/compute/vmId?api-version=2018-10-01" 2>/dev/null
    else
        if isInstanceAMI; then
            curl http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null ||
            ec2-metadata -i 2>/dev/null
        elif isInstanceDO; then
            curl http://169.254.169.254/metadata/v1/id 2>/dev/null
        elif isInstanceGCE; then
            curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id 2>/dev/null
        elif isInstanceAZURE; then
            curl -H "Metadata: true" "http://169.254.169.254/metadata/instance/compute/vmId?api-version=2018-10-01" 2>/dev/null
        fi
    fi
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
# notes: regex credit to <https://helloacm.com>
ipv4Test() {
    local IP="$1"

    if [[ $IP =~ ^([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
        return 0
    fi
    return 1
}

# $1 == ip to test
# returns: 0 == success, 1 == failure
# notes: regex credit to <https://helloacm.com>
ipv6Test() {
    local IP="$1"

    if [[ $IP =~ ^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$ ]]; then
        return 0
    fi
    return 1
}

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
getExternalIP() {
    local IPV6_ENABLED=${IPV6_ENABLED:-0}
    local EXTERNAL_IP=""
    local URLS=() CURL_CMD="curl"

    if (( ${IPV6_ENABLED} == 1 )); then
        URLS=(
            "https://icanhazip.com"
            "https://bot.whatismyipaddress.com"
            "https://ifconfig.co"
            "https://ident.me"
            "https://api6.ipify.org"
        )
        CURL_CMD="curl -6"
        IP_TEST="ipv6Test"
    else
        URLS=(
            "https://icanhazip.com"
            "https://ipecho.net/plain"
            "https://myexternalip.com/raw"
            "https://api.ipify.org"
            "https://bot.whatismyipaddress.com"
        )
        CURL_CMD="curl -4"
        IP_TEST="ipv4Test"
    fi

    for URL in ${URLS[@]}; do
        EXTERNAL_IP=$(${CURL_CMD} -s --connect-timeout 2 $URL 2>/dev/null)
        ${IP_TEST} "$EXTERNAL_IP" && break
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

# $1 == ip or hostname
# $2 == port
# returns: 0 == connection good, 1 == connection bad
# note: timeout is set to 3 sec
checkConn() {
    if cmdExists 'nc'; then
        nc -w 3 "$1" "$2" < /dev/null 2>&1 > /dev/null; return $?
    else
        timeout 3 bash -c "< /dev/tcp/$1/$2" 2> /dev/null; return $?
    fi
}

# $@ == ssh command to test
# returns: 0 == ssh connected, 1 == ssh could not connect
checkSSH() {
    local SSH_CMD="$@ -o ConnectTimeout=5 -q 'exit 0'"
    bash -c "${SSH_CMD}" 2>&1 > /dev/null; return $?
}

# usage: checkDB [options] <database>
# options:  --user=<mysql user>
#           --pass=<mysql password>
#           --host=<mysql host>
#           --port=<mysql port>
# returns:  0 if DB exists, 1 otherwise
checkDB() {
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
        -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$MYSQL_DBNAME';")
    if [[ -n "$CHECK" ]] && [[ "$CHECK" == "$MYSQL_DB" ]]; then
        return 0
    fi
    return 1
}

# usage: dumpDB [options] <database>
# options:  --user=<mysql user>
#           --pass=<mysql password>
#           --host=<mysql host>
#           --port=<mysql port>
# output: dumped database as sql (redirect as needed)
# returns: 0 on success, non zero otherwise
dumpDB() {
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

# $1 == number of characters to get
# output: string of random printable characters
urandomChars() {
    local LEN="$1"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w ${LEN} 2>/dev/null | head -n 1
}
