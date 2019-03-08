#!/usr/bin/env bash

BUILD_VERSION="feature-ami"
BUILD_DIR="/opt/dsiprouter"

cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

if cmdExists "yum"; then
    yum install -y git curl
elif cmdExists "apt"; then
    apt-get install -y git curl
    if [ $? -ne 0 ]; then
        if ! grep -q -E '(ftp|deb)\.debian.org/debian' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
            # add debian main repo
            [ -e /etc/debian_version ] && CODENAME=$(cat /etc/os-release | grep '^VERSION=' | cut -d '(' -f 2 | cut -d ')' -f 1)
            echo "deb http://ftp.debian.org/debian ${CODENAME:-stable} main contrib non-free" >>/etc/apt/sources.list
            apt-get update -y
            apt-get install -y debian-keyring debian-archive-keyring
        fi
        apt-get install -y git curl
    fi
fi

git clone --depth 1 https://github.com/dOpensource/dsiprouter.git -b ${BUILD_VERSION} ${BUILD_DIR}
cd ${BUILD_DIR}
./dsiprouter.sh install -rtpengine -servernat

exit $?