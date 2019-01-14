#!/usr/bin/env bash

BUILD_VERSION="feature-ami"

cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

if cmdExists "yum"; then
    yum update -y
    yum install -y git curl
elif cmdExists "apt"; then
    apt-get update -y
    apt-get install -y git curl
fi

cd /opt
git clone --depth 1 https://github.com/dOpensource/dsiprouter.git -b ${BUILD_VERSION}
cd dsiprouter
./dsiprouter.sh install -rtpengine -servernat

exit $?