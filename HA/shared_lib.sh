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

# usage: dumpMysqlDatabases [options] [ <[user1[:pass]@]host1[:port]> <[user1[:pass]@]host2[:port]> ... ]
# options:  -a|--all
#           -f|--full
#           -m|--merge
#           -g|--grants
# notes: redirect output sql as needed (in shell)
dumpMysqlDatabases() {
    local KEY="full" #default
    local OPT NODE USER PASS HOST PORT NON_SYSTEM_DB
    local IDX=0 IDX_MAX=0 IDX_LAST=0
    local USERS=() PASSES=() HOSTS=() PORTS=()


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
            *)
                NODE="$1"
                USER=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -d ':' -f -1)
                PASS=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -s -d ':' -f 2-)
                HOST=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1)
                PORT=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -s -d ':' -f 2-)
                USERS+=("$USER")
                PASSES+=("$PASS")
                HOSTS+=("$HOST")
                PORTS+=("$PORT")
                IDX_MAX=$(( IDX_MAX + 1 ))
                shift
                ;;
        esac
    done

    IDX_LAST=$(( IDX_MAX - 1 ))

    # key is not handled
    case "$KEY" in
        all|full|merge|grants) ;;
        *) return 1;;
    esac

    # for all databases
    if [[ "$KEY" == "all" ]] || [[ "$KEY" == "full" ]]; then
        IDX=0
        while (( $IDX < $IDX_MAX )); do
            mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges --hex-blob \
                --user="${USERS[$IDX]}" --password="${PASSES[$IDX]}" --port="${PORTS[$IDX]}" --host="${HOSTS[$IDX]}" 2>/dev/null \
                | sed -r -e 's|DEFINER=[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']@[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']||g'
            IDX=$(( IDX + 1 ))
        done
    fi
    # for merging non system databases
    if [[ "$KEY" == "merge" ]]; then
        # TODO: handle nodes other than 1st have other non-system DBs
        NON_SYSTEM_DB=$(mysql -sN --user="${USERS[0]}" --password="${PASSES[0]}" --port="${PORTS[0]}" --host="${HOSTS[0]}" \
            -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('mysql','information_schema','performance_schema')" 2>/dev/null)

        while (( $IDX < $IDX_MAX )); do
            if (( $IDX == 0 )); then
                # recreate DB schema without triggers
                mysqldump --single-transaction --skip-opt --quick --skip-triggers --routines --create-options --disable-keys --set-charset --add-drop-database --no-data --skip-comments \
                     --user="${USERS[$IDX]}" --password="${PASSES[$IDX]}" --port="${PORTS[$IDX]}" --host="${HOSTS[$IDX]}" --databases ${NON_SYSTEM_DB} 2>/dev/null \
                     | sed -r -e 's|DEFINER=[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']@[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']||g'
            fi

            # fill data from each node
            mysqldump --single-transaction --skip-opt --skip-triggers --no-create-db --no-create-info --insert-ignore --hex-blob --skip-comments \
                --user="${USERS[$IDX]}" --password="${PASSES[$IDX]}" --port="${PORTS[$IDX]}" --host="${HOSTS[$IDX]}" --databases ${NON_SYSTEM_DB} 2>/dev/null

            if (( $IDX == $IDX_LAST )); then
                # recreate DB triggers now that data is processed
                mysqldump --single-transaction --skip-opt --quick --triggers --no-create-db --no-create-info --no-data --skip-comments \
                     --user="${USERS[$IDX]}" --password="${PASSES[$IDX]}" --port="${PORTS[$IDX]}" --host="${HOSTS[$IDX]}" --databases ${NON_SYSTEM_DB} 2>/dev/null \
                     | sed -r -e 's|DEFINER=[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']@[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']||g'
            fi

            IDX=$(( IDX + 1 ))
        done
    fi
    # for copying privileges
    if [[ "$KEY" == "all" ]] || [[ "$KEY" == "grants" ]]; then
        (
            IDX=0
            while (( $IDX < $IDX_MAX )); do
                mysql -sN -A --user="${USERS[$IDX]}" --password="${PASSES[$IDX]}" --port="${PORTS[$IDX]}" --host="${HOSTS[$IDX]}" \
                    -e "SELECT DISTINCT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>''" 2>/dev/null \
                    | mysql -sN -A --user="${USERS[$IDX]}" --password="${PASSES[$IDX]}" --port="${PORTS[$IDX]}" --host="${HOSTS[$IDX]}" 2>/dev/null \
                    | sed 's/$/;/g' \
                    | awk '!x[$0]++'
            IDX=$(( IDX + 1 ))
            done
        ) | sort -u
        echo 'FLUSH PRIVILEGES;'
    fi

    return 0
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

# prints internal ip address for the default route
getInternalIP() {
    INTERFACE=$(ip -4 route show default | awk '{print $5}')
    ip addr show $INTERFACE | awk '/^[ \t]+inet / {print $2}' | cut -f1 -d'/' | head -1
}

# automate mysql_secure_installation
# original: https://gist.github.com/kahidna/512b0d507ac90d1cbbf6b0230d38a502
# $1 == new root password
# $2 == old root password
mysqlSecureInstall() {
    local NEW_MYSQL_PASSWORD="$1"
    local CURRENT_MYSQL_PASSWORD="$2"

expect <<EOF
set timeout 3
spawn mysql_secure_installation
expect "Enter current password for root (enter for none):"
send "$CURRENT_MYSQL_PASSWORD\r"
expect "root password?"
send "y\r"
expect "New password:"
send "$NEW_MYSQL_PASSWORD\r"
expect "Re-enter new password:"
send "$NEW_MYSQL_PASSWORD\r"
expect "Remove anonymous users?"
send "y\r"
expect "Disallow root login remotely?"
send "n\r"
expect "Remove test database and access to it?"
send "y\r"
expect "Reload privilege tables now?"
send "y\r"
expect eof
EOF
}

getCloudPlatform() {
    # -- amazon web service check --
    if curl -s -f --connect-timeout 2 http://169.254.169.254/latest/dynamic/instance-identity/ &>/dev/null; then
        echo -n 'AWS'
    # -- digital ocean check --
    elif curl -s -f --connect-timeout 2 http://169.254.169.254/metadata/v1/id &>/dev/null; then
        echo -n 'DO'
    # -- google compute engine check --
    elif curl -s -f --connect-timeout 2 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/id &>/dev/null; then
        echo -n 'GCE'
    # -- microsoft azure check --
    elif curl -s -f --connect-timeout 2 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2018-10-01" &>/dev/null; then
        echo -n 'AZURE'
    # -- vultr cloud check --
    elif curl -s -f --connect-timeout 2 http://169.254.169.254/v1/instanceid &>/dev/null; then
        echo -n 'VULTR'
    # -- oracle cloud environment check --
    elif curl -s -f --connect-timeout 2 -H 'Authorization: Bearer Oracle' http://169.254.169.254/opc/v2/instance; then
        echo -n 'OCE'
    fi
    # -- bare metal or unsupported cloud platform --
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

# $1 == cmd as executed in systemd (by ExecStart=)
# $2 == service file to add command to
# notes: take precaution when adding long running functions as they will block startup in boot order
# notes: adding init commands on an AMI instance must not be long running processes, otherwise they will fail
addExcStartCmd() {
    local CMD=$(printf '%s' "$1" | sed -e 's|[\/&]|\\&|g') # escape string
    local SVC_FILE="$2"
    local TMP_FILE="${SVC_FILE}.tmp"

    # sanity check, does the entry already exist?
    grep -q -oP "^ExecStart\=.*${CMD}.*" 2>/dev/null ${SVC_FILE} && return 0

    tac ${SVC_FILE} | sed -r "0,\|^ExecStart\=.*|{s|^ExecStart\=.*|ExecStart=${CMD}\n&|}" | tac > ${TMP_FILE}
    mv -f ${TMP_FILE} ${SVC_FILE}

    systemctl daemon-reload
}

# $1 == string to match for removal (after ExecStart=)
# $2 == service file to remove command from
removeExecStartCmd() {
    local STR=$(printf '%s' "$1" | sed -e 's|[\/&]|\\&|g') # escape string
    local SVC_FILE="$2"

    sed -i -r "\|^ExecStart\=.*${STR}.*|d" ${SVC_FILE}
    systemctl daemon-reload
}

# $1 == service name (full name with target) to be dependent
# $2 == service file to add dependency to
# notes: only adds startup ordering dependency (service continues if dependency fails)
# notes: the Before= section of init will link to an After= dependency on daemon-reload
addDependsOnService() {
    local SERVICE="$1"
    local SVC_FILE="$2"

    # sanity check, does the entry already exist?
    grep -q -oP "^(Before\=|Wants\=).*${SERVICE}.*" 2>/dev/null ${SVC_FILE} && return 0

    perl -i -e "\$service='$SERVICE';" -pe 's%^(Before\=|Wants\=)(.*)%length($2)==0 ? "${1}${service}" : "${1}${2} ${service}"%ge;' ${SVC_FILE}
    systemctl daemon-reload
}

# $1 == service name (full name with target) to remove dependency on
# $2 == service file to remove dependency from
removeDependsOnService() {
    local SERVICE="$1"
    local SVC_FILE="$2"

    perl -i -e "\$service='$SERVICE';" -pe 's%^((?:Before\=|Wants\=).*?)( ${service}|${service} |${service})(.*)%\1\3%g;' ${SVC_FILE}
    systemctl daemon-reload
}
