#!/usr/bin/env bash

# set project dir (where src files are located)
DSIP_PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(dirname $(readlink -f "$0"))}
# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh




# generate docs
(
    cd ${DSIP_PROJECT_DIR}/docs
    make html >/dev/null 2>&1
)

# install documentation for the CLI
cp -f ${DSIP_PROJECT_DIR}/resources/man/dsiprouter.1 ${MAN_PROGS_DIR}/
gzip -f ${MAN_PROGS_DIR}/dsiprouter.1
mandb

# generate settings.py


# generate systemd services
createInitService

# generate nginx config
installNginx

# generate nginx service file

# generate command like completion

# generate db changes


# generate requirements


# generate kamailio config
generateKamailioConfig
updateKamailioConfig
updateKamailioStartup

# generate mysql systemd
reconfigureMysqlSystemdService

# generate rtpengine
updateRtpengineConfig

# generate update dnsmask
updateDnsConfig

# generate updatednsconfig

# generate updatePermissions
updatePermissions