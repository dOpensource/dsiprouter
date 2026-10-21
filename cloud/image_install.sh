#!/usr/bin/env bash
#
# Summary:  Install dsiprouter as an VM/VPS Deployable Image
# Usage:    ./cloud/image_install.sh [INSTALL_OPTIONS]
#

export DSIP_PROJECT_DIR=$(realpath -m "${BASH_SOURCE[0]}/../..")
INSTALL_OPTIONS=("-all")
export IMAGE_BUILD=1

# parse args if given
if (( $# > 0 )); then
    INSTALL_OPTIONS=("$@")
fi

# Wait for cloud-init boot tasks (e.g., unattended-upgrades, apt-daily) to finish
if command -v cloud-init &>/dev/null; then
    cloud-init status --wait >/dev/null || true
fi

# dsiprouter install
${DSIP_PROJECT_DIR}/dsiprouter.sh install "${INSTALL_OPTIONS[@]}" || exit 1
# cleanup environment for image
${DSIP_PROJECT_DIR}/cloud/pre-snapshot.sh || exit 1

exit 0
