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
export ANSI_WHITE="${ESC_SEQ}1;37m"

# public IP's us for testing / DNS lookups in scripts
export GOOGLE_DNS_IPV4="8.8.8.8"
export GOOGLE_DNS_IPV6="2001:4860:4860::8888"

# Constants for imported functions
export DSIP_INIT_FILE=${DSIP_INIT_FILE:-"/lib/systemd/system/dsip-init.service"}
export DSIP_SYSTEM_CONFIG_DIR=${DSIP_SYSTEM_CONFIG_DIR:-"/etc/dsiprouter"}
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(dirname $(dirname $(readlink -f "$BASH_SOURCE")))}

# reuse credential settings from python files (exported for later usage)
export SALT_LEN=${SALT_LEN:-$(grep -m 1 -oP 'SALT_LEN[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)}
export DK_LEN_DEFAULT=${DK_LEN_DEFAULT:-$(grep -m 1 -oP 'DK_LEN_DEFAULT[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)}
export CREDS_MAX_LEN=${CREDS_MAX_LEN:-$(grep -m 1 -oP 'CREDS_MAX_LEN[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)}
export HASH_ITERATIONS=${HASH_ITERATIONS:-$(grep -m 1 -oP 'HASH_ITERATIONS[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)}
export HASHED_CREDS_ENCODED_MAX_LEN=${HASHED_CREDS_ENCODED_MAX_LEN:-$(grep -m 1 -oP 'HASHED_CREDS_ENCODED_MAX_LEN[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)}
export AESCTR_CREDS_ENCODED_MAX_LEN=${AESCTR_CREDS_ENCODED_MAX_LEN:-$(grep -m 1 -oP 'AESCTR_CREDS_ENCODED_MAX_LEN[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)}
export AES_CTR_NONCE_SIZE=${AES_CTR_NONCE_SIZE:-$(grep -m 1 -oP 'NONCE_SIZE[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)}
export AES_CTR_KEY_SIZE=${AES_CTR_KEY_SIZE:-$(grep -m 1 -oP 'KEY_SIZE[ \t]+=[ \t]+\K[0-9]+' ${DSIP_PROJECT_DIR}/gui/util/security.py)}

# Flag denoting that these functions have been imported (verifiable in sub-processes)
export DSIP_LIB_IMPORTED=1

##############################################
# Printing functions and String Manipulation #
##############################################

# checks if stdin is null and sets STDIN_FIRST_BYTE to first character of stdin
function isStdinNull() {
    local c
    read -r -d '' c
}

function printbold() {
    if [[ "$1" == "-n" ]]; then
        shift; printf "%b%s%b" "${ANSI_WHITE}" "$*" "${ANSI_NONE}"
    else
        printf "%b%s%b\n" "${ANSI_WHITE}" "$*" "${ANSI_NONE}"
    fi
}
export -f printbold

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
    [[ -p /dev/stdin ]] &&
    (
        read -r -d '' INPUT
        [[ -z "$INPUT" ]] && exit 1
        tr '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]' '[abcdefghijklmnopqrstuvwxyz]' <<<"$INPUT"
        exit 0
    ) ||
    {
        printf '%s' "$1" | tr '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]' '[abcdefghijklmnopqrstuvwxyz]'
    }
}
export -f tolower

function toupper() {
    [[ -p /dev/stdin ]] &&
    (
        read -r -d '' INPUT
        [[ -z "$INPUT" ]] && exit 1
        tr '[abcdefghijklmnopqrstuvwxyz]' '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]' <<<"$INPUT"
        exit 0
    ) ||
    {
        printf '%s' "$1" | tr '[abcdefghijklmnopqrstuvwxyz]' '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]'
    }
}
export -f toupper

function hextoint() {
    [[ -p /dev/stdin ]] &&
    (
        read -r -d '' INPUT
        [[ -z "$INPUT" ]] && exit 1
        printf '%d' "0x$INPUT" 2>/dev/null
        exit 0
    ) ||
    {
        printf '%d' "0x$1" 2>/dev/null
    }
}
export -f hextoint

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

# $1 == credentials to encrypt
function encryptCreds() {
    local PT_CREDS="$1"
    # this is the file not the raw key
    local DSIP_PRIV_KEY=${DSIP_PRIV_KEY:-$(getConfigAttrib 'DSIP_PRIV_KEY' "$CONFIG_FILE")}
    local NONCE CT_HEX

    # openssl version - depends on openssl, xxd, and sed
    NONCE=$(openssl rand -hex $AES_CTR_NONCE_SIZE)
    CT_HEX=$(
        openssl enc -aes-256-ctr -e \
            -iv "$NONCE" \
            -K "$(xxd -p -l $AES_CTR_KEY_SIZE -c $AES_CTR_KEY_SIZE <"${DSIP_PRIV_KEY}")" \
            < <(echo -n "$PT_CREDS") \
            2>/dev/null | xxd -p -c $AESCTR_CREDS_ENCODED_MAX_LEN
    )
    echo -n "${NONCE}${CT_HEX}"
}
export -f encryptCreds

# $1 == attribute name
# $2 == attribute value
# $3 == python config file
function encryptConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"
    local CT_CREDS

    # openssl version - depends on openssl, xxd, and sed
    CT_CREDS=$(encryptCreds "$VALUE")
    setConfigAttrib "$NAME" "$CT_CREDS" "$CONFIG_FILE" -qb
    # python version - depends on dsiprouter's python3 venv and pycryptodome
#    ${PYTHON_CMD} <<EOPY
#import os, sys
#os.chdir('${DSIP_PROJECT_DIR}/gui')
#sys.path.insert(0, '${DSIP_SYSTEM_CONFIG_DIR}/gui')
#import settings
#from shared import updateConfig
#from util.security import AES_CTR
#updateConfig(settings, {'$NAME': AES_CTR.encrypt('$VALUE')})
#EOPY
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
    # this is the file not the raw key
    local DSIP_PRIV_KEY=${DSIP_PRIV_KEY:-$(getConfigAttrib 'DSIP_PRIV_KEY' "$CONFIG_FILE")}
    local NONCE NONCE_OFFSET

    local VALUE=$(grep -oP '^(?!#)(?:'${NAME}')[ \t]*=[ \t]*\K(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|b?""".*"""[ \t]*$|'"b?'''.*'''"'[ \v]*$|b?".*"[ \t]*$|'"b?'.*'"')' ${CONFIG_FILE})
    # if value is not a byte literal it isn't encrypted
    if ! printf '%s' "${VALUE}" | grep -q -oP '(b""".*"""|'"b'''.*'''"'|b".*"|'"b'.*')"; then
        printf '%s' "${VALUE}" | perl -0777 -pe 's~^b?["'"'"']+(.*?)["'"'"']+$|(.*)~\1\2~g'
    else
        VALUE=$(perl -pe 's%b"""(.*)"""|'"b'''(.*)'''"'|b"(.*)"|'"b'(.*)'"'%\1\2\3\4%' <<<"$VALUE")
        # openssl version - depends on openssl and xxd
        NONCE_OFFSET=$((AES_CTR_NONCE_SIZE * 2))
        NONCE=${VALUE:0:$NONCE_OFFSET}
        openssl enc -aes-256-ctr -d \
            -iv "$NONCE" \
            -K "$(xxd -p -l $AES_CTR_KEY_SIZE -c $AES_CTR_KEY_SIZE <"${DSIP_PRIV_KEY}")" \
            < <(echo -n "${VALUE:$NONCE_OFFSET}" | xxd -r -p -c $AESCTR_CREDS_ENCODED_MAX_LEN) \
            2>/dev/null
        # python version - depends on dsiprouter's python3 venv and pycryptodome
#        ${PYTHON_CMD} <<EOPY
#import os, sys
#os.chdir('${DSIP_PROJECT_DIR}/gui')
#sys.path.insert(0, '${DSIP_SYSTEM_CONFIG_DIR}/gui')
#import settings
#from util.security import AES_CTR
#print(AES_CTR.decrypt(settings.${NAME}), end='')
#EOPY
    fi
}
export -f decryptConfigAttrib

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
    local RET TOKEN

    # handle IMDS version selection automatically
    # ref: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
    RET=$(curl -s -o /dev/null --connect-timeout 2 -w '%{http_code}' http://169.254.169.254/latest/meta-data/ami-id)
    if (( $RET == 200 )); then
        return 0
    elif (( $RET == 401 )); then
        TOKEN=$(curl -s -X PUT --connect-timeout 2 -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' http://169.254.169.254/latest/api/token)
        curl -s -f --connect-timeout 2 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/ami-id
        return $?
    else
        return 1
    fi
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
# notes: we try checking for exported instance variable to avoid querying again
function getInstanceID() {
    local RET TOKEN

    if (( ${AWS_ENABLED:-0} == 1)); then
        RET=$(curl -s -o /dev/null -w '%{http_code}' http://169.254.169.254/latest/meta-data/ami-id 2>/dev/null)
        if (( $RET == 200 )); then
            curl -s -f http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null
        elif (( $RET == 401 )); then
            TOKEN=$(curl -s -X PUT --connect-timeout 2 -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' http://169.254.169.254/latest/api/token 2>/dev/null)
            curl -s -f --connect-timeout 2 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null
        else
            return 1
        fi
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
            RET=$(curl -s -o /dev/null -w '%{http_code}' http://169.254.169.254/latest/meta-data/ami-id 2>/dev/null)
            if (( $RET == 200 )); then
                curl -s -f http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null
            elif (( $RET == 401 )); then
                TOKEN=$(curl -s -X PUT --connect-timeout 2 -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' http://169.254.169.254/latest/api/token 2>/dev/null)
                curl -s -f --connect-timeout 2 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null
            else
                return 1
            fi
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
		INTERFACE=$(ip -4 route show default | head -1 | awk '{print $5}')
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
# output: the IP for the given interface
# notes: prints ip, or empty string if not available
# notes: tries ipv4 first then ipv6
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
	    	INTERFACE=$(ip -4 route show default | head -1 | awk '{print $5}')
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
				DEF_IFACE=$(ip -4 route list scope global 2>/dev/null | perl -e 'while (<>) { if (s%^(?:0\.0\.0\.0|default).*dev (\w+).*$%\1%) { print; exit; } }')
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
    $@ -o ConnectTimeout=5 'exit 0' &>/dev/null
    return $?
}
export -f checkSSH

# bake in the connection details for kamailio user/database
# standardizes our usage and avoids various pitfalls with the client APIs
# usage:    withKamDB <mysql cmd> [mysql options/args]
function withKamDB() {
    local CONN_OPTS=()
    local CMD="$1"
    shift

    [[ -n "$KAM_DB_HOST" ]] && CONN_OPTS+=( "--host=${KAM_DB_HOST}" )
    [[ -n "$KAM_DB_PORT" ]] && CONN_OPTS+=( "--port=${KAM_DB_PORT}" )
    [[ -n "$KAM_DB_USER" ]] && CONN_OPTS+=( "--user=${KAM_DB_USER}" )
    [[ -n "$KAM_DB_PASS" ]] && CONN_OPTS+=( "--password=${KAM_DB_PASS}" )
    if [[ "$1" == "mysql" ]]; then
        [[ -n "$KAM_DB_NAME" ]] && CONN_OPTS+=( "--database=${KAM_DB_NAME}" )
    fi

    if [[ -p /dev/stdin ]]; then
        ${CMD} "${CONN_OPTS[@]}" "$@" </dev/stdin
    else
        ${CMD} "${CONN_OPTS[@]}" "$@"
    fi
    return $?
}
export -f withKamDB

# bake in the connection details for root user/database
# standardizes our usage and avoids various pitfalls with the client APIs
# usage:    withRootDBConn [options] <mysql cmd> [mysql options/args]
# options:  --db=<mysql db name>
function withRootDBConn() {
    local TMP CMD
    local CONN_OPTS=()

    case "$1" in
        --db=*)
            TMP=$(cut -d '=' -f 2- <<<"$1")
            [[ -n "$TMP" ]] && CONN_OPTS+=( "--database=${TMP}" )
            shift
            CMD="$1"
            shift
            ;;
        *)
            CMD="$1"
            shift
            if [[ "$CMD" == "mysql" ]]; then
                [[ -n "$ROOT_DB_NAME" ]] && CONN_OPTS+=( "--database=${ROOT_DB_NAME}" )
            fi
            ;;
    esac

    [[ -n "$ROOT_DB_HOST" ]] && CONN_OPTS+=( "--host=${ROOT_DB_HOST}" )
    [[ -n "$ROOT_DB_PORT" ]] && CONN_OPTS+=( "--port=${ROOT_DB_PORT}" )
    [[ -n "$ROOT_DB_USER" ]] && CONN_OPTS+=( "--user=${ROOT_DB_USER}" )
    [[ -n "$ROOT_DB_PASS" ]] && CONN_OPTS+=( "--password=${ROOT_DB_PASS}" )

    if [[ -p /dev/stdin ]]; then
        ${CMD} "${CONN_OPTS[@]}" "$@" </dev/stdin
    else
        ${CMD} "${CONN_OPTS[@]}" "$@"
    fi
    return $?
}
export -f withRootDBConn

# allow passing in connection details to bake into the command
# standardizes our usage and avoids various pitfalls with the client APIs
# usage:    withGivenDB [options] <mysql cmd> [mysql options/args]
# options:  --user=<mysql user>
#           --pass=<mysql password>
#           --host=<mysql host>
#           --port=<mysql port>
#           --db=<mysql db name>
function withGivenDB() {
    local TMP
    local ARGS=()
    local CONN_OPTS=()

    while (( $# > 0 )); do
        case "$1" in
            --user=*)
                TMP=$(cut -d '=' -f 2- <<<"$1")
                [[ -n "$TMP" ]] && CONN_OPTS+=( "--user=${TMP}" )
                shift
                ;;
            --pass=*)
                TMP=$(cut -d '=' -f 2- <<<"$1")
                [[ -n "$TMP" ]] && CONN_OPTS+=( "--password=${TMP}" )
                shift
                ;;
            --host=*)
                TMP=$(cut -d '=' -f 2- <<<"$1")
                [[ -n "$TMP" ]] && CONN_OPTS+=( "--host=${TMP}" )
                shift
                ;;
            --port=*)
                TMP=$(cut -d '=' -f 2- <<<"$1")
                [[ -n "$TMP" ]] && CONN_OPTS+=( "--port=${TMP}" )
                shift
                ;;
            --db=*)
                TMP=$(cut -d '=' -f 2- <<<"$1")
                [[ -n "$TMP" ]] && CONN_OPTS+=( "--database=${TMP}" )
                shift
                ;;
            *)
                ARGS+=( "$1" )
                shift
                ;;
        esac
    done

    if [[ -p /dev/stdin ]]; then
        ${ARGS[0]} "${CONN_OPTS[@]}" "${ARGS[@]:1}" </dev/stdin
    else
        ${ARGS[0]} "${CONN_OPTS[@]}" "${ARGS[@]:1}"
    fi
    return $?
}
export -f withGivenDB

# usage: checkDB <database>
# returns:  0 if DB exists, 1 otherwise
function checkDB() {
    local CHECK=$(
        withRootDBConn mysql -sN \
            -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$1';" \
            2>/dev/null
    )
    if [[ -n "$CHECK" ]]; then
        return 0
    fi
    return 1
}
export -f checkDB

# usage: checkDBUserExists <user>@<host>
# returns: 0 if user exists, 1 on DB connection failure, 2 if user does not exist
function checkDBUserExists() {
    local USER=$(cut -d '@' -f 1 <<<"$1")
    local HOST=$(cut -d '@' -f 2 <<<"$1")

    return $(
        withRootDBConn mysql -sN -A \
            -e "SELECT IF(EXISTS(SELECT 1 FROM mysql.user WHERE User='${USER}' AND Host='${HOST}'),0,2);" \
            2>/dev/null
    )
}
export -f checkDBUserExists

# usage: dumpDB <databases>
# output: dumped database as sql (redirect as needed)
# returns: 0 on success, non zero otherwise
function dumpDB() {
    withRootDBConn mysqldump --single-transaction --opt --routines --triggers --hex-blob --databases "$@" \
        2>/dev/null |
        sed -r \
            -e 's|DEFINER=[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']@[`"'"'"'][a-zA-Z0-9_%]*[`"'"'"']||g' \
            -e 's|ENGINE=MyISAM|ENGINE=InnoDB|g' \
            2>/dev/null
    return ${PIPESTATUS[0]}
}
export -f dumpDB

# usage: dumpDBUser <user>@<host>|<user>
# output: dumped database user as sql (redirect as needed)
# returns: 0 on success, non zero otherwise
function dumpDBUser() {
    USER=$(printf '%s' "$1" | cut -s -d '@' -f 1)
    if [[ -n "$USER" ]]; then
        shift
        USER="$1"
    fi

    (withRootDBConn mysql -sN -A \
        -e "SELECT DISTINCT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user='${USER}'" 2>/dev/null \
        | withRootDBConn mysql -sN -A 2>/dev/null \
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
    local TMP
    local DB_SET=0
    local MYSQL_USER='' MYSQL_PASS='' MYSQL_HOST='' MYSQL_PORT=''
    local OPTS=() SQL_STATEMENTS=()

    while (( $# > 0 )); do
        case "$1" in
            --user=*|--pass=*|--host=*|--port=*)
                OPTS+=( "$1" )
                shift
                ;;
            --db=*)
                OPTS+=( "$1" )
                shift
                DB_SET=1
                ;;
            *)  # all positional args are part of SQL query
                SQL_STATEMENTS+=( "$1" )
                shift
                ;;
        esac
    done

    # creating the procedure will fail if we don't select a database
    # TODO: do we need this now that we switched to prepared statements?
    (( $DB_SET == 0 )) && OPTS+=( "--db=mysql" )

    # if query was piped to stdin use that instead of positional args
    if [[ -p /dev/stdin ]]; then
        read -r -d '' TMP
        [[ -n "$TMP" ]] && SQL_STATEMENTS=( "$TMP" )
    fi

    cat <<EOF | withGivenDB "${OPTS[@]}" mysql -s
START TRANSACTION;
${SQL_STATEMENTS[@]}
SET @end_transaction = (SELECT IF(@@error_count > 0, "ROLLBACK;", "COMMIT;"));
PREPARE stmt FROM @end_transaction;
EXECUTE stmt;
EOF
    return $?
}
export -f sqlAsTransaction

# TODO: remove dependency on system python3
# usage: parseDBConnURI <field> <connection uri>
# field:    -user
#           -pass
#           -host
#           -port
#           -name
# output: the selected field of the connection uri
# returns:
#   0   == field set
#   1   == field not set
#   255 == error parsing
function parseDBConnURI() {
    local GROUP

    case "$1" in
        -user)
            shift
            GROUP=0
            ;;
        -pass)
            shift
            GROUP=1
            ;;
        -host)
            shift
            GROUP=2
            ;;
        -port)
            shift
            GROUP=3
            ;;
        -name)
            shift
            GROUP=4
            ;;
        *)  # not valid field
            return 1
            ;;
    esac

    # WARNING: we must use system python3 here (dsiprouter python venv may not exist)
    python3 <<EOPY
import re
matches = re.search(r'[\t\r\n\v\f]*(?:([^:]+)?(?::([^@]+)?)?@)?([^:]+)(?::([^/]+)?)?(?:/([^\t\r\n\v\f]+))?[\t\r\n\v\f]*', '$1')
if matches is None:
    exit(1)
if matches.groups()[$GROUP] is None:
    exit(1)
print(matches.groups()[$GROUP], end='')
EOPY
    return $?
}
export -f parseDBConnURI

# usage:    urandomChars [options] [args]
# options:  -f <filter> == characters to allow
# args:     $1 == number of characters to get
# output:   string of random printable characters
function urandomChars() {
	local LEN=32 FILTER="a-zA-Z0-9"

    while (( $# > 0 )); do
    	# last arg is length
        if (( $# == 1 )); then
            LEN="$1"
            shift
            break
        fi

        case "$1" in
        	# user defined filter
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

# TODO: improve performance of openssl native version and swap it out
function hashCreds() {
	local CREDS SALT DK_LEN

	# grab credentials from stdin if provided
	if [[ -p /dev/stdin ]]; then
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
	# WARNING: we must use system python3 here (dsiprouter python venv may not exist)
	python3 <<EOPYTHON
import hashlib,binascii
creds='$CREDS'.encode('utf-8')
salt='$SALT'.encode('utf-8')
hash=hashlib.pbkdf2_hmac('sha512', creds, salt, iterations=$HASH_ITERATIONS, dklen=$DK_LEN) + salt
print(binascii.hexlify(hash).decode('utf-8'))
EOPYTHON
	# bash native version
	# currently too slow for production usage
	#${DSIP_PROJECT_DIR}/dsiprouter/pbkdf2.sh 'sha512' "$CREDS" "$SALT" "$HASH_ITERATIONS" 4
}
export -f hashCreds

# args:
#   $1  ==  version 1 to compare from
#   $2  ==  compare operation
#   $3  ==  version 2 to compare against
# returns:
#   0   ==  version comparison is true
#   1   ==  version comparison is false
#   255 ==  comparison failed
function versionCompare() { (
    set -e
    trap 'exit 255' ERR

    if [[ ! "$1$2" =~ [\.0-9]+ ]]; then
        echo "${FUNCNAME}(): invalid version"
        exit 255
    fi

    local IFS=.
    local IDX LEN
    local VER1=( $1 ) VER2=( $3 )
    if (( ${#VER1[@]} >= ${#VER2[@]} )); then
        LEN=${#VER1[@]}
    else
        LEN=${#VER2[@]}
    fi
    for (( IDX=0; IDX<$LEN; IDX++)); do
        VER1[$IDX]=${VER1[$IDX]:-0}
        VER2[$IDX]=${VER2[$IDX]:-0}
    done

    case "$2" in
        lt)
            [[ "${VER1[@]}" == "${VER2[@]}" ]] && exit 1
            for (( IDX=0; IDX<$LEN; IDX++)); do
                (( ${VER1[$IDX]} > ${VER2[$IDX]} )) && exit 1
            done
            exit 0
            ;;
        lteq)
            for (( IDX=0; IDX<$LEN; IDX++)); do
                (( ${VER1[$IDX]} <= ${VER2[$IDX]} )) || exit 1
            done
            exit 0
            ;;
        eq)
            COMP='=='
            ;;
        gt)
            [[ "${VER1[@]}" == "${VER2[@]}" ]] && exit 1
            for (( IDX=0; IDX<$LEN; IDX++)); do
                (( ${VER1[$IDX]} < ${VER2[$IDX]} )) && exit 1
            done
            exit 0
            ;;
        gteq)
            for (( IDX=0; IDX<$LEN; IDX++)); do
                (( ${VER1[$IDX]} >= ${VER2[$IDX]} )) || exit 1
            done
            exit 0
            ;;
        *)
            echo "${FUNCNAME}(): invalid comparator"
            exit 255
            ;;
    esac
) }
export -f versionCompare

# $1 == repo path
function getGitTagFromShallowRepo() { (
    cd "$1" 2>/dev/null &&
    git config --get remote.origin.fetch | cut -d ':' -f 2- | rev | cut -d '/' -f 1 | rev
) }
export -f getGitTagFromShallowRepo
