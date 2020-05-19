#!/usr/bin/env bash
#
# Summary: build dsiprouter as an VM/VPS Deployable Image
#

BUILD_VERSION="v0.62"
BUILD_DIR="/opt/dsiprouter"
REPO_URL="https://github.com/dOpensource/dsiprouter.git"
export IMAGE_BUILD=1 # will be passed to dsiprouter.sh

cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# wait for cloud vps boot processes to finish before starting
if cmdExists "apt-get"; then
    while [ ! -f /var/lib/cloud/instance/boot-finished ] || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        sleep 1
    done

    DEBIAN_FRONTEND=noninteractive apt-get update -qq -y >/dev/null
    DEBIAN_FRONTEND=noninteractive apt-get install -qq -y git >/dev/null
elif cmdExists "yum"; then
    while [ ! -f /var/lib/cloud/instance/boot-finished ] || [ -f /var/run/yum.pid ]; do
        sleep 1
    done

    yum update -y -q -e 0 >/dev/null
    yum install -y -q -e 0 git >/dev/null
fi

# clone and install
git clone --depth 1 ${REPO_URL} -b ${BUILD_VERSION} ${BUILD_DIR} || exit 1
${BUILD_DIR}/dsiprouter.sh install -all -servernat || exit 1
# cleanup environment for image
${BUILD_DIR}/cloud/pre-snapshot.sh || exit 1

exit 0
