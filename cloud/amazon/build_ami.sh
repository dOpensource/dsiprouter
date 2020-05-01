#!/usr/bin/env bash
#
# Summary: build dsiprouter for an AWS Deployable Image
#

BUILD_VERSION="v0.522"
BUILD_DIR="/opt/dsiprouter"
REPO_URL="https://github.com/dOpensource/dsiprouter.git"
CLOUD_INSTALL_LOG="/var/log/dsip-cloud-install.log"

cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
getDisto() {
    cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d '=' -f 2 | cut -d '"' -f 2
}

# wait for cloud vps boot processes to finish before starting
if cmdExists "yum"; then
    while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ||
    [ ! -f /var/lib/cloud/instance/boot-finished ]; do
        sleep 1
    done
elif cmdExists "apt-get"; then
    while [ ! -f /var/lib/cloud/instance/boot-finished ] ||
    [ -f /var/run/yum.pid ]; do
        sleep 1
    done
fi

# update caches and install dependencies for repo
if cmdExists "yum"; then
    yum update -y
    yum install -y git curl wget
elif cmdExists "apt-get"; then
    apt-get update -y
    apt-get install -y --fix-missing git curl wget

    if [ "$(getDisto)" = "debian" ]; then
        # will grab missing GPG keys for us
        apt-get install -y --fix-missing debian-keyring debian-archive-keyring

        CODENAME=$(cat /etc/os-release 2>/dev/null | grep '^VERSION=' | cut -d '(' -f 2 | cut -d ')' -f 1)
        CODENAME=${CODENAME:-stable}

        # add official debian repo's, AWS default repo's tend to be unreliable
        (cat << EOF
#=================== OFFICIAL DEBIAN REPOS ===================#
deb http://deb.debian.org/debian/ ${CODENAME} main contrib
deb-src http://deb.debian.org/debian/ ${CODENAME} main contrib

deb http://deb.debian.org/debian/ ${CODENAME}-updates main contrib
deb-src http://deb.debian.org/debian/ ${CODENAME}-updates main contrib

deb http://deb.debian.org/debian-security ${CODENAME}/updates main
deb-src http://deb.debian.org/debian-security ${CODENAME}/updates main

deb http://ftp.debian.org/debian ${CODENAME}-backports main
deb-src http://ftp.debian.org/debian ${CODENAME}-backports main
EOF
        ) > /etc/apt/sources.list.d/official.list

        apt-get update -y
    fi
fi

git clone --depth 1 ${REPO_URL} -b ${BUILD_VERSION} ${BUILD_DIR}
${BUILD_DIR}/dsiprouter.sh install -debug -all -servernat | tee -i ${CLOUD_INSTALL_LOG}  2>&1
res=$?

${BUILD_DIR}/cloud/pre-snapshot.sh
((res+=$?))

exit $res