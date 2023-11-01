#!/usr/bin/env bash

export BOOTSTRAPPING_UPGRADE=1
export DSIP_PROJECT_DIR='/tmp/dsiprouter'
TAG_NAME='v0.721-rel'
REPO_URL='https://github.com/dOpensource/dsiprouter.git'
rm -f /etc/dsiprouter/.requirementsinstalled
rm -rf "$DSIP_PROJECT_DIR" 2>/dev/null
git clone --depth 1 -c advice.detachedHead=false -b "$TAG_NAME" "$REPO_URL" "$DSIP_PROJECT_DIR"
${DSIP_PROJECT_DIR}/dsiprouter.sh upgrade -rel v0.721
