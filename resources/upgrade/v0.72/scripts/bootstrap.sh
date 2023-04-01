#!/usr/bin/env bash

export BOOTSTRAPPING_UPGRADE=1
export SALT_LEN='16'
export DK_LEN_DEFAULT='48'
export CREDS_MAX_LEN='64'
export HASH_ITERATIONS='10000'
export HASHED_CREDS_ENCODED_MAX_LEN='128'
export AESCTR_CREDS_ENCODED_MAX_LEN='160'
rm -f /etc/dsiprouter/.requirementsinstalled
rm -rf /tmp/dsiprouter 2>/dev/null
git clone --depth 1 -b v0.72 https://github.com/dOpensource/dsiprouter.git /tmp/dsiprouter
ln -sf /tmp/dsiprouter/resources/upgrade /opt/dsiprouter/resources/upgrade
. /tmp/dsiprouter/dsiprouter/dsip_lib.sh
. /tmp/dsiprouter/dsiprouter.sh upgrade -rel v0.72
