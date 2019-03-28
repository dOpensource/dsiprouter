#!/usr/bin/env bash

BUILD_VERSION="feature-ami"
BUILD_DIR="/opt/dsiprouter"
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

# update caches and install dependencies for repo
if cmdExists "yum"; then
    yum update -y
    yum install -y git curl wget
elif cmdExists "apt"; then
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

git clone --depth 1 https://github.com/dOpensource/dsiprouter.git -b ${BUILD_VERSION} ${BUILD_DIR}
cd ${BUILD_DIR}
./dsiprouter.sh install -debug -all -servernat | tee -ia ${CLOUD_INSTALL_LOG}  2>&1

exit $?