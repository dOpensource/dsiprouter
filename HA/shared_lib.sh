#!/usr/bin/env bash
#
# NOTES:
# contains utility functions and shared variables
# should be sourced by an external script
#
# TODO: section library scripts into more manageable files (grouping related funcs)
# we should also put them in a central location such as: <project dir>/bashlibs
#

###################
# Color constants #
###################

# Ansi Colors
ESC_SEQ="\033["
ANSI_NONE="${ESC_SEQ}39;49;00m" # Reset colors
ANSI_RED="${ESC_SEQ}1;31m"
ANSI_GREEN="${ESC_SEQ}1;32m"
ANSI_YELLOW="${ESC_SEQ}1;33m"
ANSI_CYAN="${ESC_SEQ}1;36m"

##############################################
# Printing functions and String Manipulation #
##############################################

printerr() {
    printf "%b%s%b\n" "${ANSI_RED}" "$*" "${ANSI_NONE}"
}

printwarn() {
    printf "%b%s%b\n" "${ANSI_YELLOW}" "$*" "${ANSI_NONE}"
}

printdbg() {
    printf "%b%s%b\n" "${ANSI_GREEN}" "$*" "${ANSI_NONE}"
}

pprint() {
    printf "%b%s%b\n" "${ANSI_CYAN}" "$*" "${ANSI_NONE}"
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

# $1 == crontab entry to append
cronAppend() {
    crontab -l | { cat; echo "$1"; } | crontab -
}

# $1 == crontab entry to remove
cronRemove() {
    crontab -l | grep -v -F -w "$1" | crontab -
}

# $1 == delimeter to join args with
# $* == strings to join
# usage: STR=$(join ',' ${ARR[@]})
join() {
    local IFS="$1"; shift; echo "$*"
}

# $1 == delimeter to join args with
# $@ == string(s) to split
# usage: ARR=( $(split ',' '1,2,3,4') )
split() {
    local IFS="$1"; shift; read -r -a ARR <<< "$@"; echo "${ARR[@]}"; unset ARR;
}

# returns: 0 == root user, else not root user
isRoot() {
    return $(id -u 2>/dev/null)
}

# sets DISTRO and DISTRO_VER variables in current shell
setOSInfo() {
    DISTRO=$(cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d '=' -f 2 | cut -d '"' -f 2)

    if [[ "$DISTRO" == "linuxmint" ]]; then
        export DISTRO="linuxmint"
        export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
    elif [[ "$DISTRO" == "ubuntu" ]]; then
        export DISTRO="ubuntu"
        export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
    elif [[ "$DISTRO" == "debian" ]]; then
        export DISTRO="debian"
        export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
    elif [[ "$DISTRO" == "amzn" ]]; then
        export DISTRO="amazon"
        export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
    elif [[ "$DISTRO" == "centos" ]]; then
        export DISTRO="centos"
        export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
    elif [[ -f /etc/redhat-release ]] && [[ "$(cat /etc/redhat-release | awk '{ print tolower($1) }')" == "red" ]]; then
        export DISTRO="redhat"
        export DISTRO_VER=$(cat /etc/redhat-release | sed 's/.* \(7\).[0-9] .*/\1/')
    else
        export DISTRO=""
        export DISTRO_VER=""
    fi
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

# Notes: prints generated password
createPass() {
    tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1
}

# usage: getPkgVer [--opt] <arg>
# opt == what version(s) to show (default --installed)
#       -i|--installed:    get installed package version
#       -l|--latest:       get latest version available
#       -a|--all:          get all available versions
# arg == the package to search for in repos
# returns: 0 == success, else == failure
# note: does not handle same versions from different repos
# bug: if search is on a glob expr xargs will error out silently
getPkgVer() {
    local OPT=""
    local ARG=""
    local KEY=""

    while (( $# > 0 )); do
        OPT="$1"
        case $OPT in
            -i|--installed)
                KEY="installed"
                shift
                ;;
            -l|--latest)
                KEY="latest"
                shift
                ;;
            -a|--all)
                KEY="all"
                shift
                ;;
            *)  # only one arg is valid
                ARG="$OPT"
                shift
                ;;
        esac
    done

    case ${KEY:-installed} in
            installed)
                ( apt-cache policy "$ARG" \
                    | grep -oP 'Installed:\h*([0-9]+:)?\K([0-9]+\.)([0-9\.]+)' \
                    | sed 's/\./%/; s/\.//g; s/%/\./';
                    exit ${PIPESTATUS[0]}; ) 2>/dev/null && return $? ||
                ( yum --cacheonly list installed "$ARG" 2>/dev/null \
                    | xargs -d '\r\n' -n 3 \
                    | grep -oP '\h*([0-9]+:)?\K([0-9]+\.)([0-9\.]+)' \
                    | sed 's/\./%/; s/\.//g; s/%/\./';
                    exit ${PIPESTATUS[0]}; ) 2>/dev/null && return $? ||
                    return 1
                ;;
            latest)
                ( apt-cache policy "$ARG" \
                    | grep -oP 'Candidate:\h*([0-9]+:)?\K([0-9]+\.)([0-9\.]+)' \
                    | sed 's/\./%/; s/\.//g; s/%/\./';
                    exit ${PIPESTATUS[0]}; ) 2>/dev/null ||
                ( yum --cacheonly --showduplicates list available "$ARG" 2>/dev/null \
                    | xargs -d '\r\n' -n 3 \
                    | grep -oP '\h*([0-9]+:)?\K([0-9]+\.)([0-9\.]+)' \
                    | sed 's/\./%/; s/\.//g; s/%/\./' \
                    | head -1;
                    exit ${PIPESTATUS[0]}; ) 2>/dev/null && return $? ||
                    return 1
                ;;
            all)
                ( apt-cache policy "$ARG" \
                    | grep -oP '((?<![a-zA-Z:])[\*\h])+([0-9]+:)?\K([0-9]+\.)([0-9\.]+)' \
                    | sed 's/\./%/; s/\.//g; s/%/\./' \
                    | uniq;
                    exit ${PIPESTATUS[0]}; ) 2>/dev/null ||
                ( yum --cacheonly --showduplicates list "$ARG" 2>/dev/null \
                    | xargs -d '\r\n' -n 3 \
                    | grep -oP '\h*([0-9]+:)?\K([0-9]+\.)([0-9\.]+)' \
                    | sed 's/\./%/; s/\.//g; s/%/\./' \
                    | uniq;
                    exit ${PIPESTATUS[0]}; ) 2>/dev/null && return $? ||
                    return 1
                ;;
    esac
}

# usage: dumpMysqlDatabases [options]
# options:  -a|--all
#           -f|--full
#           -m|--merge
#           -g|--grants
#           --user=<mysql user>
#           --pass=<mysql password>
#           --host=<mysql host>
#           --port=<mysql port>
# notes: redirect output sql as needed (in shell)
dumpMysqlDatabases() {
    local OPT=""
    local KEY=""
    local MYSQL_USER=${MYSQL_USER:-root}
    local MYSQL_PASS=${MYSQL_PASS:-}
    local MYSQL_HOST=${MYSQL_HOST:-localhost}
    local MYSQL_PORT=${MYSQL_PORT:-3306}

    while (( $# > 0 )); do
        OPT="$1"
        case $OPT in
            -a|--all)
                KEY="all"
                shift
                ;;
            -f|--full)
                KEY="full"
                shift
                ;;
            -m|--merge)
                KEY="merge"
                shift
                ;;
            -g|--grants)
                KEY="grants"
                shift
                ;;
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
            *)  # no valid args skip
                shift
                ;;
        esac
    done

    # for all databases
    if [[ "$KEY" == "all" ]] || [[ "$KEY" == "full" ]]; then
        mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges --hex-blob \
            --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" 2>/dev/null \
            | sed -r -e 's|DEFINER=[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']@[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']||g' -e 's|ENGINE=MyISAM|ENGINE=InnoDB|g'
    fi
    # for merging non system databases
    if [[ "$KEY" == "all" ]] || [[ "$KEY" == "merge" ]]; then
        local NON_SYSTEM_DB=$(mysql -sN --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" \
            -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('mysql','information_schema','performance_schema')" 2>/dev/null)
        mysqldump --single-transaction --opt --routines --triggers --skip-add-drop-table --insert-ignore --hex-blob \
            --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" --databases ${NON_SYSTEM_DB} 2>/dev/null \
            | perl -0777 -p -e 's/CREATE TABLE (`(.+?)`.+?;)/CREATE TABLE IF NOT EXISTS \1\n\nTRUNCATE TABLE `\2`;\n/gs' \
            | sed -r -e 's|DEFINER=[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']@[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']||g' -e 's|ENGINE=MyISAM|ENGINE=InnoDB|g'
    fi
    # for copying privileges
    if [[ "$KEY" == "all" ]] || [[ "$KEY" == "grants" ]]; then
        mysql -sN -A --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" \
            -e "SELECT DISTINCT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>''" 2>/dev/null \
            | mysql -sN -A --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" 2>/dev/null \
            | sed 's/$/;/g' \
            | awk '!x[$0]++' &&
            printf '%s\n' 'FLUSH PRIVILEGES;'
    fi
}

detectServiceMan() {
    INIT_PROC=$(readlink -f $(readlink -f /proc/1/exe))

    case "$INIT_PROC" in
        *systemd)
            SERVICE_MANAGER="systemd"
            ;;
        *upstart)
            SERVICE_MANAGER="upstart"
            ;;
        *runit-init)
            SERVICE_MANAGER="runit"
            ;;
        *openrc-init)
            SERVICE_MANAGER="openrc"
            ;;
        /sbin/init)
            INIT_PROC_INFO=$(/sbin/init --version 2>/dev/null | head -1)
            case "$INIT_PROC_INFO" in
                *systemd*)
                    SERVICE_MANAGER="systemd"
                    ;;
                *upstart*)
                    SERVICE_MANAGER="upstart"
                    ;;
                *runit-init*)
                    SERVICE_MANAGER="runit"
                    ;;
                *openrc-init*)
                    SERVICE_MANAGER="openrc"
                    ;;
            esac
            ;;
        *)
            SERVICE_MANAGER="sysv"
            ;;
    esac

    export SERVICE_MANAGER
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

# notes:    prints internal ip addr
getInternalIP() {
    ip route get 8.8.8.8 | awk 'NR == 1 {print $7}'
}