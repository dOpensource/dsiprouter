#!/usr/bin/env bash

export BOOTSTRAPPING_UPGRADE=1
export BOOTSTRAP_DIR='/tmp/dsiprouter'
TAG_NAME='v0.73-rel'
REPO_URL='https://github.com/dOpensource/dsiprouter.git'
[[ -e "$BOOTSTRAP_DIR" ]] && rm -rf "$BOOTSTRAP_DIR"
git clone --depth 1 -c advice.detachedHead=false -b "$TAG_NAME" "$REPO_URL" "$BOOTSTRAP_DIR"
${BOOTSTRAP_DIR}/dsiprouter.sh upgrade -rel v0.73
RET=$?
rm -rf ${BOOTSTRAP_DIR}
exit $RET
