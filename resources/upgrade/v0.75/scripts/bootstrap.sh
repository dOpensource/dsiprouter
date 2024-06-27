#!/usr/bin/env bash

cd /opt/dsiprouter
. dsiprouter/dsip_lib.sh
LC_CHECK=$(decryptConfigAttrib 'DSIP_CORE_LICENSE' /etc/dsiprouter/gui/settings.py | dd if=/dev/stdin of=/dev/stdout bs=1 count=32 2>/dev/null)
(( ${#LC_CHECK} == 32 )) || {
echo "a core licene is required to use the auto upgrade feature"
echo "without a license the upgrade will fail"
echo "you can purchase a license here: https://dopensource.com/product/dsiprouter-core/"
exit 1
}

export BOOTSTRAPPING_UPGRADE=1
export BOOTSTRAP_DIR='/tmp/dsiprouter'
TAG_NAME='v0.75-rel'
REPO_URL='https://github.com/dOpensource/dsiprouter.git'
[[ -e "$BOOTSTRAP_DIR" ]] && rm -rf "$BOOTSTRAP_DIR"

git clone --depth 1 -c advice.detachedHead=false -b "$TAG_NAME" "$REPO_URL" "$BOOTSTRAP_DIR" &&
mkdir -p /opt/dsiprouter/resources/upgrade/v0.75/ &&
cp -rf /tmp/dsiprouter/resources/upgrade/v0.75/. /opt/dsiprouter/resources/upgrade/v0.75/ &&
dsiprouter upgrade -rel v0.75