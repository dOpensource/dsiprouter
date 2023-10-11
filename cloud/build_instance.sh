#!/usr/bin/env bash
#
# Summary:  build dsiprouter as an VM/VPS Instance
# Usage:    ./build_instance.sh [--ver='<dsiprouter version>'] [--dir='<dsiprouter project directory>'] [--repo='<dsiprouter repo url>'] [--opts='<dsiprouter build options>']
#

# parse args if given
while (( $# > 0 )); do
    ARG="$1"
    case "$ARG" in
        --ver=*)
            DSIP_VERSION=$(echo "$1" | cut -d '=' -f 2)
            shift
            ;;
        --dir=*)
            DSIP_DIR=$(echo "$1" | cut -d '=' -f 2)
            shift
            ;;
        --repo=*)
            DSIP_REPO=$(echo "$1" | cut -d '=' -f 2)
            shift
            ;;
        --opts=*)
            BUILD_OPTIONS=$(echo "$1" | cut -d '=' -f 2)
            shift
            ;;
        *)
            echo "[ERROR] argument $ARG is not valid"
            exit 1
            ;;
    esac
done

# set defaults if needed, exports will be passed to dsiprouter.sh
export DSIP_VERSION=${DSIP_VERSION:-"master"}
DSIP_DIR=${DSIP_DIR:-"/opt/dsiprouter"}
DSIP_REPO=${DSIP_REPO:-"https://github.com/dOpensource/dsiprouter.git"}
BUILD_OPTIONS=${BUILD_OPTIONS:-"install -all"}

function cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# wait for any other programs using package manager to complete
if cmdExists "apt-get"; then
    while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        sleep 1
    done

    # make package manager quieter
    export DEBIAN_FRONTEND="noninteractive"
    export DEBIAN_PRIORITY="critical"

    apt-get update -qq -y >/dev/null
    apt-get install -qq -y git perl >/dev/null

    # TODO: move to installScriptRequirements()
    # make sure english UTF-8 locale is installed
    if ! locale -a 2>/dev/null | grep -q 'en_US.UTF-8'; then
          perl -i -pe 's%# (en_US\.UTF-8 UTF-8)%\1%' /etc/locale.gen
          locale-gen
    fi
elif cmdExists "yum"; then
    while [ -f /var/run/yum.pid ]; do
        sleep 1
    done

    yum makecache -y -q -e 0 >/dev/null
    yum install -y -q -e 0 git >/dev/null
fi

# clone and install
git clone --depth 1 -c advice.detachedHead=false ${DSIP_REPO} -b ${DSIP_VERSION} ${DSIP_DIR} || exit 1
${DSIP_DIR}/dsiprouter.sh ${BUILD_OPTIONS} || exit 1

exit 0
