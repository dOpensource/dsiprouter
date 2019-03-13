#!/usr/bin/env bash
#
# NOTES:
# contains utility functions and shared variables
# should be sourced by an external script
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
    if [ -f /etc/redhat-release ]; then
        DISTRO="centos"
        DISTRO_VER=$(cat /etc/redhat-release | cut -d ' ' -f 4 | cut -d '.' -f 1)
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
    elif [[ "$(cat /etc/os-release | grep '^ID=' 2>/dev/null | cut -d '=' -f 2 | cut -d '"' -f 2)" == "amzn" ]]; then
        DISTRO="amazon"
        DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
    else
        DISTRO=""
        DISTRO_VER=""
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
    date +%s | sha256sum | base64 | head -c 16
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
# notes: redirect output sql as needed
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

    # let calling shell redirect output
    case $KEY in
        all|full)
            # for all databases
            mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges \
                --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}"
                ####> ${MYSQL_BACKUP_DIR}/dumps/full.sql
            ;;
        all|merge)
            # for merging non system databases
            local NON_SYSTEM_DB=$(mysql -sN --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" \
                -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('mysql','information_schema','performance_schema')")
            mysqldump --single-transaction --skip-triggers --skip-add-drop-table --insert-ignore \
                --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" --databases ${NON_SYSTEM_DB} \
                | perl -0777 -p -e 's/CREATE TABLE (`(.+?)`.+?;)/CREATE TABLE IF NOT EXISTS \1\n\nTRUNCATE TABLE `\2`;\n/gs'
                ####> ${MYSQL_BACKUP_DIR}/dumps/merge.sql
            ;;
        all|grants)
            # for copying privileges
            mysql -sN -A --user="${MYSQL_USER}" --password="${MYSQL_PASS}" --port="${MYSQL_PORT}" --host="${MYSQL_HOST}" \
                -e "SELECT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>''" \
                | mysql -sN -A \
                | sed 's/$/;/g' \
                | awk '!x[$0]++'
                ####> ${MYSQL_BACKUP_DIR}/dumps/grants.sql
            ;;
    esac
}