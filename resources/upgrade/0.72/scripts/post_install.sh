#!/usr/bin/env bash

# pull in dsiprouter dependencies
source /opt/dsiprouter/dsiprouter.sh

# generate docs
(
  cd ${DSIP_PROJECT_DIR}/docs
  make html >/dev/null 2>&1
)

# install documentation for the CLI
installManPage

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