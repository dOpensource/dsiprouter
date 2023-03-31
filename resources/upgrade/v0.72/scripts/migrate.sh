#!/usr/bin/env bash

# set project dir (where src files are located)
DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-$(dirname $(readlink -f "$0"))}
# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

# generate docs for the GUI
(
    cd ${DSIP_PROJECT_DIR}/docs
    make html >/dev/null 2>&1
)

# install documentation for the CLI
cp -f ${DSIP_PROJECT_DIR}/resources/man/dsiprouter.1 ${MAN_PROGS_DIR}/
gzip -f ${MAN_PROGS_DIR}/dsiprouter.1
mandb
cp -f ${DSIP_PROJECT_DIR}/dsiprouter/dsip_completion.sh /etc/bash_completion.d/dsiprouter

# configure dsiprouter GUI
export DSIP_ID=$(cat /etc/machine-id | hashCreds)
export DSIP_CLUSTER_ID=$(getConfigAttrib "DSIP_CLUSTER_ID" "/etc/dsiprouter/gui/settings.py")
export DSIP_CLUSTER_SYNC=$(getConfigAttrib "DSIP_CLUSTER_SYNC" "/etc/dsiprouter/gui/settings.py")
export DSIP_PROTO=$(getConfigAttrib "DSIP_PROTO" "/etc/dsiprouter/gui/settings.py")
export DSIP_PORT=$(getConfigAttrib "DSIP_PORT" "/etc/dsiprouter/gui/settings.py")
export DSIP_USERNAME=$(getConfigAttrib "DSIP_USERNAME" "/etc/dsiprouter/gui/settings.py")
export DSIP_PASSWORD=$(decryptConfigAttrib "DSIP_PASSWORD" "/etc/dsiprouter/gui/settings.py")
export DSIP_API_TOKEN=$(decryptConfigAttrib "DSIP_API_TOKEN" "/etc/dsiprouter/gui/settings.py")
export DSIP_API_PROTO=$(getConfigAttrib "DSIP_API_PROTO" "/etc/dsiprouter/gui/settings.py")
export DSIP_API_PORT=$(getConfigAttrib "DSIP_API_PORT" "/etc/dsiprouter/gui/settings.py")
export DSIP_PRIV_KEY=$(getConfigAttrib "DSIP_PRIV_KEY" "/etc/dsiprouter/gui/settings.py")
export DSIP_PID_FILE=$(getConfigAttrib "DSIP_PID_FILE" "/etc/dsiprouter/gui/settings.py")
export DSIP_UNIX_SOCK=$(getConfigAttrib "DSIP_UNIX_SOCK" "/etc/dsiprouter/gui/settings.py")
export DSIP_IPC_SOCK=$(getConfigAttrib "DSIP_IPC_SOCK" "/etc/dsiprouter/gui/settings.py")
export DSIP_IPC_PASS=$(decryptConfigAttrib "DSIP_IPC_PASS" "/etc/dsiprouter/gui/settings.py")
export DSIP_LOG_LEVEL=$(getConfigAttrib "DSIP_LOG_LEVEL" "/etc/dsiprouter/gui/settings.py")
export DSIP_LOG_FACILITY=$(getConfigAttrib "DSIP_LOG_FACILITY" "/etc/dsiprouter/gui/settings.py")
export DSIP_SSL_KEY=$(getConfigAttrib "DSIP_SSL_KEY" "/etc/dsiprouter/gui/settings.py")
export DSIP_SSL_CERT=$(getConfigAttrib "DSIP_SSL_CERT" "/etc/dsiprouter/gui/settings.py")
export DSIP_SSL_CA=$(getConfigAttrib "DSIP_SSL_CA" "/etc/dsiprouter/gui/settings.py")
export DSIP_SSL_EMAIL=$(getConfigAttrib "DSIP_SSL_EMAIL" "/etc/dsiprouter/gui/settings.py")
export DSIP_CERTS_DIR=$(getConfigAttrib "DSIP_CERTS_DIR" "/etc/dsiprouter/gui/settings.py")
export ROLE=$(getConfigAttrib "ROLE" "/etc/dsiprouter/gui/settings.py")
export GUI_INACTIVE_TIMEOUT=$(getConfigAttrib "GUI_INACTIVE_TIMEOUT" "/etc/dsiprouter/gui/settings.py")
export KAM_DB_HOST=$(getConfigAttrib "KAM_DB_HOST" "/etc/dsiprouter/gui/settings.py")
export KAM_DB_DRIVER=$(getConfigAttrib "KAM_DB_DRIVER" "/etc/dsiprouter/gui/settings.py")
export KAM_DB_TYPE=$(getConfigAttrib "KAM_DB_TYPE" "/etc/dsiprouter/gui/settings.py")
export KAM_DB_PORT=$(getConfigAttrib "KAM_DB_PORT" "/etc/dsiprouter/gui/settings.py")
export KAM_DB_NAME=$(getConfigAttrib "KAM_DB_NAME" "/etc/dsiprouter/gui/settings.py")
export KAM_DB_USER=$(getConfigAttrib "KAM_DB_USER" "/etc/dsiprouter/gui/settings.py")
export KAM_DB_PASS=$(decryptConfigAttrib "KAM_DB_PASS" "/etc/dsiprouter/gui/settings.py")
export KAM_KAMCMD_PATH=$(getConfigAttrib "KAM_KAMCMD_PATH" "/etc/dsiprouter/gui/settings.py")
export KAM_CFG_PATH=$(getConfigAttrib "KAM_CFG_PATH" "/etc/dsiprouter/gui/settings.py")
export KAM_TLSCFG_PATH=$(getConfigAttrib "KAM_TLSCFG_PATH" "/etc/dsiprouter/gui/settings.py")
export RTP_CFG_PATH=$(getConfigAttrib "RTP_CFG_PATH" "/etc/dsiprouter/gui/settings.py")
export FLT_CARRIER=$(getConfigAttrib "FLT_CARRIER" "/etc/dsiprouter/gui/settings.py")
export FLT_PBX=$(getConfigAttrib "FLT_PBX" "/etc/dsiprouter/gui/settings.py")
export FLT_MSTEAMS=$(getConfigAttrib "FLT_MSTEAMS" "/etc/dsiprouter/gui/settings.py")
export FLT_OUTBOUND=$(getConfigAttrib "FLT_OUTBOUND" "/etc/dsiprouter/gui/settings.py")
export FLT_INBOUND=$(getConfigAttrib "FLT_INBOUND" "/etc/dsiprouter/gui/settings.py")
export FLT_LCR_MIN=$(getConfigAttrib "FLT_LCR_MIN" "/etc/dsiprouter/gui/settings.py")
export FLT_FWD_MIN=$(getConfigAttrib "FLT_FWD_MIN" "/etc/dsiprouter/gui/settings.py")
export DEFAULT_AUTH_DOMAIN=$(getConfigAttrib "DEFAULT_AUTH_DOMAIN" "/etc/dsiprouter/gui/settings.py")
export TELEBLOCK_GW_ENABLED=$(getConfigAttrib "TELEBLOCK_GW_ENABLED" "/etc/dsiprouter/gui/settings.py")
export TELEBLOCK_GW_IP=$(getConfigAttrib "TELEBLOCK_GW_IP" "/etc/dsiprouter/gui/settings.py")
export TELEBLOCK_GW_PORT=$(getConfigAttrib "TELEBLOCK_GW_PORT" "/etc/dsiprouter/gui/settings.py")
export TELEBLOCK_MEDIA_IP=$(getConfigAttrib "TELEBLOCK_MEDIA_IP" "/etc/dsiprouter/gui/settings.py")
export TELEBLOCK_MEDIA_PORT=$(getConfigAttrib "TELEBLOCK_MEDIA_PORT" "/etc/dsiprouter/gui/settings.py")
export FLOWROUTE_ACCESS_KEY=$(decryptConfigAttrib "FLOWROUTE_ACCESS_KEY" "/etc/dsiprouter/gui/settings.py")
export FLOWROUTE_SECRET_KEY=$(decryptConfigAttrib "FLOWROUTE_SECRET_KEY" "/etc/dsiprouter/gui/settings.py")
export FLOWROUTE_API_ROOT_URL=$(getConfigAttrib "FLOWROUTE_API_ROOT_URL" "/etc/dsiprouter/gui/settings.py")
export HOMER_ID=$(cat /etc/machine-id | hashCreds -l 4 | dd if=/dev/stdin of=/dev/stdout bs=1 count=8 2>/dev/null | hextoint)
export HOMER_HEP_HOST=$(getConfigAttrib "HOMER_HEP_HOST" "/etc/dsiprouter/gui/settings.py")
export HOMER_HEP_PORT=$(getConfigAttrib "HOMER_HEP_PORT" "/etc/dsiprouter/gui/settings.py")
export NETWORK_MODE='0'
export UPLOAD_FOLDER=$(getConfigAttrib "UPLOAD_FOLDER" "/etc/dsiprouter/gui/settings.py")
export MAIL_SERVER=$(getConfigAttrib "MAIL_SERVER" "/etc/dsiprouter/gui/settings.py")
export MAIL_PORT=$(getConfigAttrib "MAIL_PORT" "/etc/dsiprouter/gui/settings.py")
export MAIL_USE_TLS=$(getConfigAttrib "MAIL_USE_TLS" "/etc/dsiprouter/gui/settings.py")
export MAIL_USERNAME=$(getConfigAttrib "MAIL_USERNAME" "/etc/dsiprouter/gui/settings.py")
export MAIL_PASSWORD=$(decryptConfigAttrib "MAIL_PASSWORD" "/etc/dsiprouter/gui/settings.py")
export MAIL_ASCII_ATTACHMENTS=$(getConfigAttrib "MAIL_ASCII_ATTACHMENTS" "/etc/dsiprouter/gui/settings.py")
export MAIL_DEFAULT_SENDER=$(getConfigAttrib "MAIL_DEFAULT_SENDER" "/etc/dsiprouter/gui/settings.py")
export MAIL_DEFAULT_SUBJECT=$(getConfigAttrib "MAIL_DEFAULT_SUBJECT" "/etc/dsiprouter/gui/settings.py")
export BACKUP_FOLDER=$(getConfigAttrib "BACKUP_FOLDER" "/etc/dsiprouter/gui/settings.py")
export TRANSNEXUS_AUTHSERVICE_HOST=$(getConfigAttrib "TRANSNEXUS_AUTHSERVICE_HOST" "/etc/dsiprouter/gui/settings.py")
export TRANSNEXUS_VERIFYSERVICE_HOST=$(getConfigAttrib "TRANSNEXUS_VERIFYSERVICE_HOST" "/etc/dsiprouter/gui/settings.py")
export STIR_SHAKEN_PREFIX_A=$(getConfigAttrib "STIR_SHAKEN_PREFIX_A" "/etc/dsiprouter/gui/settings.py")
export STIR_SHAKEN_PREFIX_B=$(getConfigAttrib "STIR_SHAKEN_PREFIX_B" "/etc/dsiprouter/gui/settings.py")
export STIR_SHAKEN_PREFIX_C=$(getConfigAttrib "STIR_SHAKEN_PREFIX_C" "/etc/dsiprouter/gui/settings.py")
export STIR_SHAKEN_PREFIX_INVALID=$(getConfigAttrib "STIR_SHAKEN_PREFIX_INVALID" "/etc/dsiprouter/gui/settings.py")
export STIR_SHAKEN_BLOCK_INVALID=$(getConfigAttrib "STIR_SHAKEN_BLOCK_INVALID" "/etc/dsiprouter/gui/settings.py")
export STIR_SHAKEN_CERT_URL=$(getConfigAttrib "STIR_SHAKEN_CERT_URL" "/etc/dsiprouter/gui/settings.py")
export STIR_SHAKEN_KEY_PATH=$(getConfigAttrib "STIR_SHAKEN_KEY_PATH" "/etc/dsiprouter/gui/settings.py")
export DSIP_DOCS_DIR="${DSIP_PROJECT_DIR}/docs"
export ROOT_DB_USER=$(getConfigAttrib "ROOT_DB_USER" "/etc/dsiprouter/gui/settings.py")
export ROOT_DB_PASS=$(getConfigAttrib "ROOT_DB_PASS" "/etc/dsiprouter/gui/settings.py")
export ROOT_DB_NAME=$(getConfigAttrib "ROOT_DB_NAME" "/etc/dsiprouter/gui/settings.py")
export LOAD_SETTINGS_FROM=$(getConfigAttrib "LOAD_SETTINGS_FROM" "/etc/dsiprouter/gui/settings.py")

# TODO: currently no way of easily transferring the license keys to the upgraded platform
#TRANSNEXUS_LICENSE_KEY -> DSIP_TRANSNEXUS_LICENSE

dsiprouter configuredsip

# re-generate systemd services we changed
export DISTRO=$(getDistroName)
export DISTRO_VER=$(getDistroVer)
export DISTRO_MAJOR_VER=$(cut -d '.' -f 1 <<<"$DISTRO_VER")
export DISTRO_MINOR_VER=$(cut -s -d '.' -f 2 <<<"$DISTRO_VER")

export INTERNAL_IP_ADDR=$(getInternalIP -4)
export INTERNAL_IP_NET=$(getInternalCIDR -4)
export INTERNAL_IP6_ADDR=$(getInternalIP -6)
export INTERNAL_IP_NET6=$(getInternalCIDR -6)
EXTERNAL_IP_ADDR=$(getExternalIP -4)
export EXTERNAL_IP_ADDR=${EXTERNAL_IP_ADDR:-$INTERNAL_IP_ADDR}
EXTERNAL_IP6_ADDR=$(getExternalIP -6)
export EXTERNAL_IP6_ADDR=${EXTERNAL_IP6_ADDR:-$INTERNAL_IP6_ADDR}
export INTERNAL_FQDN=$(getInternalFQDN)
export EXTERNAL_FQDN=$(getExternalFQDN)
if [[ -z "$EXTERNAL_FQDN" ]] || ! checkConn "$EXTERNAL_FQDN"; then
    export EXTERNAL_FQDN="$INTERNAL_FQDN"
fi

    case "$DISTRO" in
        debian|ubuntu)
            cat << 'EOF' >/etc/systemd/system/dnsmasq.service
[Unit]
Description=dnsmasq - A lightweight DHCP and caching DNS server
Requires=basic.target network.target
After=network.target network-online.target basic.target
Wants=nss-lookup.target
Before=nss-lookup.target
DefaultDependencies=no

[Service]
Type=forking
PIDFile=/run/dnsmasq/dnsmasq.pid
Environment='RUN_DIR=/run/dnsmasq'
# make sure everything is setup correctly before starting
ExecStartPre=!-/usr/bin/dsiprouter chown -dnsmasq
ExecStartPre=/usr/sbin/dnsmasq --test
# We run dnsmasq via the /etc/init.d/dnsmasq script which acts as a
# wrapper picking up extra configuration files and then execs dnsmasq
# itself, when called with the "systemd-exec" function.
ExecStart=/etc/init.d/dnsmasq systemd-exec
# The systemd-*-resolvconf functions configure (and deconfigure)
# resolvconf to work with the dnsmasq DNS server. They're called like
# this to get correct error handling (ie don't start-resolvconf if the
# dnsmasq daemon fails to start.
ExecStartPost=/etc/init.d/dnsmasq systemd-start-resolvconf
ExecStop=/etc/init.d/dnsmasq systemd-stop-resolvconf
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
            ;;
        almalinux|rocky)
            cat << 'EOF' >/etc/systemd/system/dnsmasq.service
[Unit]
Description=dnsmasq - A lightweight DHCP and caching DNS server
Requires=basic.target network.target
After=network.target network-online.target basic.target
Before=multi-user.target
DefaultDependencies=no

[Service]
Type=simple
PIDFile=/run/dnsmasq/dnsmasq.pid
Environment='RUN_DIR=/run/dnsmasq'
# make sure everything is setup correctly before starting
ExecStartPre=!-/usr/bin/dsiprouter chown -dnsmasq
ExecStartPre=/usr/sbin/dnsmasq --test
ExecStart=/usr/sbin/dnsmasq -k
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
            ;;
        amzn|rhel)
            cat << 'EOF' >/etc/systemd/system/dnsmasq.service
[Unit]
Description=dnsmasq - A lightweight DHCP and caching DNS server
Requires=basic.target network.target
After=network.target network-online.target basic.target
Before=multi-user.target
DefaultDependencies=no

[Service]
Type=simple
PermissionsStartOnly=true
PIDFile=/run/dnsmasq/dnsmasq.pid
Environment='RUN_DIR=/run/dnsmasq'
# make sure everything is setup correctly before starting
ExecStartPre=/usr/bin/dsiprouter chown -dnsmasq
ExecStartPre=/usr/sbin/dnsmasq --test
ExecStart=/usr/sbin/dnsmasq -k
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
            ;;
    esac

for SERVICE in kamailio nginx dsiprouter rtpengine; do
    if [[ ! -f "${DSIP_SYSTEM_CONFIG_DIR}/.${SERVICE}installed" ]]; then
    SVC_FILE=$(grep -oP "$SERVICE-v[0-9]+\.service" ${DSIP_PROJECT_DIR}/$SERVICE/${DISTRO}/${DISTRO_MAJOR_VER}.sh)
    cp -f ${DSIP_PROJECT_DIR}/$SERVICE/systemd/$SVC_FILE /etc/systemd/system/$SERVICE.service
done

export DSIP_SYSTEM_CONFIG_DIR="/etc/dsiprouter"
export DSIP_CERTS_DIR="${DSIP_SYSTEM_CONFIG_DIR}/certs"
cp -f ${DSIP_PROJECT_DIR}/nginx/systemd/nginx-watcher.service /etc/systemd/system/nginx-watcher.service
perl -p \
    -e "s%PathChanged\=.*%PathChanged=${DSIP_CERTS_DIR}/%;" \
    ${DSIP_PROJECT_DIR}/nginx/systemd/nginx-watcher.path >/etc/systemd/system/nginx-watcher.path
chmod 644 /etc/systemd/system/nginx-watcher.service
chmod 644 /etc/systemd/system/nginx-watcher.path

systemctl daemon-reload

# install GUI requirements
python3 -m pip install -r ${DSIP_PROJECT_DIR}/gui/requirements.txt

# generate kamailio config
dsiprouter configurekam

# generate mysql systemd
reconfigureMysqlSystemdService

# update rtpengine configs
dsiprouter updatertpconfig

# update dnsmasq configs
dsiprouter updatednsconfig

# update permissions
dsiprouter chown
