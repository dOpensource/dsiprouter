#!/usr/bin/env bash

# set project dir (where src files are located)
export DSIP_PROJECT_DIR=/opt/dsiprouter
# import dsip_lib utility / shared functions
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    if (( ${BOOTSTRAPPING_UPGRADE:-0} == 1 )); then
        . /tmp/dsiprouter/dsiprouter/dsip_lib.sh
    else
        . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
    fi
fi

printdbg 'backing up configs just in case the upgrade fails'
BACKUP_DIR="/var/backups"
CURR_BACKUP_DIR="${BACKUP_DIR}/$(date '+%Y-%m-%d')"
mkdir -p ${CURR_BACKUP_DIR}/{opt/dsiprouter,var/lib/mysql,${HOME},etc/dsiprouter,etc/kamailio,etc/rtpengine}
cp -rf /opt/dsiprouter/. ${CURR_BACKUP_DIR}/opt/dsiprouter/
cp -rf /etc/kamailio/. ${CURR_BACKUP_DIR}/etc/kamailio/
cp -rf /var/lib/mysql/. ${CURR_BACKUP_DIR}/var/lib/mysql/
cp -f /etc/my.cnf ${CURR_BACKUP_DIR}/etc/ 2>/dev/null
cp -rf /etc/mysql/. ${CURR_BACKUP_DIR}/etc/mysql/
cp -f ${HOME}/.my.cnf ${CURR_BACKUP_DIR}/${HOME}/ 2>/dev/null
# TODO: backup current systemd service files

printdbg 'retrieving current settings'
export DSIP_ID=$(cat /etc/machine-id | hashCreds)
export DSIP_CLUSTER_ID=$(getConfigAttrib "DSIP_CLUSTER_ID" "/etc/dsiprouter/gui/settings.py")
export DSIP_CLUSTER_SYNC=$(getConfigAttrib "DSIP_CLUSTER_SYNC" "/etc/dsiprouter/gui/settings.py")
export DSIP_PROTO=$(getConfigAttrib "DSIP_PROTO" "/etc/dsiprouter/gui/settings.py")
export DSIP_PORT=$(getConfigAttrib "DSIP_PORT" "/etc/dsiprouter/gui/settings.py")
export DSIP_USERNAME=$(getConfigAttrib "DSIP_USERNAME" "/etc/dsiprouter/gui/settings.py")
export DSIP_API_PROTO=$(getConfigAttrib "DSIP_API_PROTO" "/etc/dsiprouter/gui/settings.py")
export DSIP_API_PORT=$(getConfigAttrib "DSIP_API_PORT" "/etc/dsiprouter/gui/settings.py")
export DSIP_PRIV_KEY=$(getConfigAttrib "DSIP_PRIV_KEY" "/etc/dsiprouter/gui/settings.py")
export DSIP_PID_FILE=$(getConfigAttrib "DSIP_PID_FILE" "/etc/dsiprouter/gui/settings.py")
export DSIP_UNIX_SOCK=$(getConfigAttrib "DSIP_UNIX_SOCK" "/etc/dsiprouter/gui/settings.py")
export DSIP_IPC_SOCK=$(getConfigAttrib "DSIP_IPC_SOCK" "/etc/dsiprouter/gui/settings.py")
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
export FLOWROUTE_ACCESS_KEY=$(getConfigAttrib "FLOWROUTE_ACCESS_KEY" "/etc/dsiprouter/gui/settings.py")
export FLOWROUTE_SECRET_KEY=$(getConfigAttrib "FLOWROUTE_SECRET_KEY" "/etc/dsiprouter/gui/settings.py")
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
export ROOT_DB_NAME=$(getConfigAttrib "ROOT_DB_NAME" "/etc/dsiprouter/gui/settings.py")
export LOAD_SETTINGS_FROM=$(getConfigAttrib "LOAD_SETTINGS_FROM" "/etc/dsiprouter/gui/settings.py")

# TODO: currently no way of easily transferring the license keys to the upgraded platform
#TRANSNEXUS_LICENSE_KEY -> DSIP_TRANSNEXUS_LICENSE

getCredentials() {
    local SALT_LEN='64'
    local DK_LEN_DEFAULT='64'
    local CREDS_MAX_LEN='64'
    local HASH_ITERATIONS='10000'
    local HASHED_CREDS_ENCODED_MAX_LEN='256'
    local AESCTR_CREDS_ENCODED_MAX_LEN='160'

    printwarn 'dSIPRouter admin password hash can not be undone, generating new one'
    export DSIP_PASSWORD=$(urandomChars 64)
    printdbg "temporary password: $DSIP_PASSWORD"
    export DSIP_API_TOKEN=$(decryptConfigAttrib "DSIP_API_TOKEN" "/etc/dsiprouter/gui/settings.py")
    export DSIP_IPC_PASS=$(decryptConfigAttrib "DSIP_IPC_PASS" "/etc/dsiprouter/gui/settings.py")
    export KAM_DB_PASS=$(decryptConfigAttrib "KAM_DB_PASS" "/etc/dsiprouter/gui/settings.py")
    export MAIL_PASSWORD=$(decryptConfigAttrib "MAIL_PASSWORD" "/etc/dsiprouter/gui/settings.py")
    export ROOT_DB_PASS=$(decryptConfigAttrib "ROOT_DB_PASS" "/etc/dsiprouter/gui/settings.py")
}
getCredentials

encryptCreds() { (
    if (( ${BOOTSTRAPPING_UPGRADE:-0} == 1 )); then
        cd /tmp/dsiprouter/gui
    else
        cd ${DSIP_PROJECT_DIR}/gui
    fi
    python3 -c "from util.security import AES_CTR; print(AES_CTR.encrypt('$1'));"
) }

# TODO: does not support multiple rows in dsip_settings table (cluster upgrade not supported yet)
printdbg 'migrating database schema'
(
cat <<'EOF'
ALTER TABLE address
  MODIFY tag VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE dispatcher
  MODIFY description VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE dr_gateways
  MODIFY pri_prefix VARCHAR(64) NOT NULL DEFAULT '',
  MODIFY attrs VARCHAR(255) NOT NULL DEFAULT '',
  MODIFY description VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE dr_gw_lists
  MODIFY description VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE dr_rules
  MODIFY description VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE dsip_cdrinfo
  MODIFY email VARCHAR(255) NOT NULL DEFAULT '';

UPDATE dsip_settings
  SET DSIP_ID='',
  SET DSIP_PASSWORD='',
  SET DSIP_IPC_PASS='',
  SET DSIP_API_TOKEN='',
  SET KAM_DB_PASS='',
  SET MAIL_PASSWORD='';

ALTER TABLE dsip_settings
  MODIFY DSIP_ID VARBINARY(128) COLLATE 'binary' NOT NULL,
  MODIFY DSIP_PASSWORD VARBINARY(128) COLLATE 'binary' NOT NULL,
  MODIFY DSIP_IPC_PASS VARBINARY(160) COLLATE 'binary' NOT NULL,
  MODIFY DSIP_API_TOKEN VARBINARY(160) COLLATE 'binary' NOT NULL,
  DROP IF EXISTS SQLALCHEMY_TRACK_MODIFICATIONS,
  DROP IF EXISTS SQLALCHEMY_SQL_DEBUG,
  MODIFY VERSION VARCHAR(32) NOT NULL,
  MODIFY KAM_DB_PASS VARBINARY(160) COLLATE 'binary' NOT NULL,
  MODIFY MAIL_PASSWORD VARBINARY (160) COLLATE 'binary' NOT NULL,
  ADD IF NOT EXISTS HOMER_ID INT NOT NULL AFTER FLOWROUTE_API_ROOT_URL,
  ADD IF NOT EXISTS NETWORK_MODE INT NOT NULL DEFAULT 0 AFTER HOMER_HEP_PORT,
  ADD IF NOT EXISTS INTERNAL_FQDN VARCHAR (255) NOT NULL DEFAULT '' AFTER INTERNAL_IP6_NET,
  ADD IF NOT EXISTS PUBLIC_IFACE VARCHAR (255) NOT NULL DEFAULT '' AFTER EXTERNAL_FQDN,
  ADD IF NOT EXISTS PRIVATE_IFACE VARCHAR (255) NOT NULL DEFAULT '' AFTER PUBLIC_IFACE,
  ADD IF NOT EXISTS DSIP_CORE_LICENSE VARBINARY (160) COLLATE 'binary' NOT NULL,
  ADD IF NOT EXISTS DSIP_STIRSHAKEN_LICENSE VARBINARY (160) COLLATE 'binary' NOT NULL,
  ADD IF NOT EXISTS DSIP_TRANSNEXUS_LICENSE VARBINARY (160) COLLATE 'binary' NOT NULL,
  ADD IF NOT EXISTS DSIP_MSTEAMS_LICENSE VARBINARY (160) COLLATE 'binary' NOT NULL;
EOF

cat <<EOF
UPDATE dsip_settings
  SET DSIP_ID='$DSIP_ID',
  SET DSIP_PASSWORD='$(encryptCreds $DSIP_PASSWORD)',
  SET DSIP_IPC_PASS='$(encryptCreds $DSIP_IPC_PASS)',
  SET DSIP_API_TOKEN='$(encryptCreds $DSIP_API_TOKEN)',
  SET KAM_DB_PASS='$(encryptCreds $KAM_DB_PASS)',
  SET MAIL_PASSWORD='$(encryptCreds $MAIL_PASSWORD)';
EOF

cat <<'EOF'
DROP PROCEDURE IF EXISTS update_dsip_settings;
DELIMITER //
CREATE PROCEDURE update_dsip_settings(
  IN NEW_DSIP_ID VARBINARY(128),
  IN NEW_DSIP_CLUSTER_ID INT UNSIGNED,
  IN NEW_DSIP_CLUSTER_SYNC TINYINT(1),
  IN NEW_DSIP_PROTO VARCHAR(16),
  IN NEW_DSIP_PORT INT, IN NEW_DSIP_USERNAME VARCHAR(255),
  IN NEW_DSIP_PASSWORD VARBINARY(128),
  IN NEW_DSIP_IPC_PASS VARBINARY(160),
  IN NEW_DSIP_API_PROTO VARCHAR(16),
  IN NEW_DSIP_API_PORT INT,
  IN NEW_DSIP_PRIV_KEY VARCHAR(255),
  IN NEW_DSIP_PID_FILE VARCHAR(255),
  IN NEW_DSIP_UNIX_SOCK VARCHAR(255),
  IN NEW_DSIP_IPC_SOCK VARCHAR(255),
  IN NEW_DSIP_API_TOKEN VARBINARY(160),
  IN NEW_DSIP_LOG_LEVEL INT,
  IN NEW_DSIP_LOG_FACILITY INT,
  IN NEW_DSIP_SSL_KEY VARCHAR(255),
  IN NEW_DSIP_SSL_CERT VARCHAR(255),
  IN NEW_DSIP_SSL_CA VARCHAR(255),
  IN NEW_DSIP_SSL_EMAIL VARCHAR(255),
  IN NEW_DSIP_CERTS_DIR VARCHAR(255),
  IN NEW_VERSION VARCHAR(32),
  IN NEW_DEBUG TINYINT(1),
  IN NEW_ROLE VARCHAR(32),
  IN NEW_GUI_INACTIVE_TIMEOUT INT UNSIGNED,
  IN NEW_KAM_DB_HOST VARCHAR(255),
  IN NEW_KAM_DB_DRIVER VARCHAR(255),
  IN NEW_KAM_DB_TYPE VARCHAR(255),
  IN NEW_KAM_DB_PORT VARCHAR(255),
  IN NEW_KAM_DB_NAME VARCHAR(255),
  IN NEW_KAM_DB_USER VARCHAR(255),
  IN NEW_KAM_DB_PASS VARBINARY(160),
  IN NEW_KAM_KAMCMD_PATH VARCHAR(255),
  IN NEW_KAM_CFG_PATH VARCHAR(255),
  IN NEW_KAM_TLSCFG_PATH VARCHAR(255),
  IN NEW_RTP_CFG_PATH VARCHAR(255),
  IN NEW_FLT_CARRIER INT,
  IN NEW_FLT_PBX INT,
  IN NEW_FLT_MSTEAMS INT,
  IN NEW_FLT_OUTBOUND INT,
  IN NEW_FLT_INBOUND INT,
  IN NEW_FLT_LCR_MIN INT,
  IN NEW_FLT_FWD_MIN INT,
  IN NEW_DEFAULT_AUTH_DOMAIN VARCHAR(255),
  IN NEW_TELEBLOCK_GW_ENABLED TINYINT(1),
  IN NEW_TELEBLOCK_GW_IP VARCHAR(255),
  IN NEW_TELEBLOCK_GW_PORT VARCHAR(255),
  IN NEW_TELEBLOCK_MEDIA_IP VARCHAR(255),
  IN NEW_TELEBLOCK_MEDIA_PORT VARCHAR(255),
  IN NEW_FLOWROUTE_ACCESS_KEY VARCHAR(255),
  IN NEW_FLOWROUTE_SECRET_KEY VARCHAR(255),
  IN NEW_FLOWROUTE_API_ROOT_URL VARCHAR(255),
  IN NEW_HOMER_ID INT,
  IN NEW_HOMER_HEP_HOST VARCHAR(255),
  IN NEW_HOMER_HEP_PORT INT,
  IN NEW_NETWORK_MODE INT,
  IN NEW_IPV6_ENABLED TINYINT(1),
  IN NEW_INTERNAL_IP_ADDR VARCHAR(255),
  IN NEW_INTERNAL_IP_NET VARCHAR(255),
  IN NEW_INTERNAL_IP6_ADDR VARCHAR(255),
  IN NEW_INTERNAL_IP6_NET VARCHAR(255),
  IN NEW_INTERNAL_FQDN VARCHAR(255),
  IN NEW_EXTERNAL_IP_ADDR VARCHAR(255),
  IN NEW_EXTERNAL_IP6_ADDR VARCHAR(255),
  IN NEW_EXTERNAL_FQDN VARCHAR(255),
  IN NEW_PUBLIC_IFACE VARCHAR(255),
  IN NEW_PRIVATE_IFACE VARCHAR(255),
  IN NEW_UPLOAD_FOLDER VARCHAR(255),
  IN NEW_MAIL_SERVER VARCHAR(255),
  IN NEW_MAIL_PORT INT,
  IN NEW_MAIL_USE_TLS TINYINT(1),
  IN NEW_MAIL_USERNAME VARCHAR(255),
  IN NEW_MAIL_PASSWORD VARBINARY(160),
  IN NEW_MAIL_ASCII_ATTACHMENTS TINYINT(1),
  IN NEW_MAIL_DEFAULT_SENDER VARCHAR(255),
  IN NEW_MAIL_DEFAULT_SUBJECT VARCHAR(255),
  IN NEW_DSIP_CORE_LICENSE VARBINARY(128),
  IN NEW_DSIP_STIRSHAKEN_LICENSE VARBINARY(128),
  IN NEW_DSIP_TRANSNEXUS_LICENSE VARBINARY(128),
  IN NEW_DSIP_MSTEAMS_LICENSE VARBINARY(128)
)
BEGIN
  START TRANSACTION;

  REPLACE INTO dsip_settings
  VALUES (NEW_DSIP_ID,
          NEW_DSIP_CLUSTER_ID,
          NEW_DSIP_CLUSTER_SYNC,
          NEW_DSIP_PROTO,
          NEW_DSIP_PORT,
          NEW_DSIP_USERNAME,
          NEW_DSIP_PASSWORD,
          NEW_DSIP_IPC_PASS,
          NEW_DSIP_API_PROTO,
          NEW_DSIP_API_PORT,
          NEW_DSIP_PRIV_KEY,
          NEW_DSIP_PID_FILE,
          NEW_DSIP_UNIX_SOCK,
          NEW_DSIP_IPC_SOCK,
          NEW_DSIP_API_TOKEN,
          NEW_DSIP_LOG_LEVEL,
          NEW_DSIP_LOG_FACILITY,
          NEW_DSIP_SSL_KEY,
          NEW_DSIP_SSL_CERT,
          NEW_DSIP_SSL_CA,
          NEW_DSIP_SSL_EMAIL,
          NEW_DSIP_CERTS_DIR,
          NEW_VERSION,
          NEW_DEBUG,
          NEW_ROLE,
          NEW_GUI_INACTIVE_TIMEOUT,
          NEW_KAM_DB_HOST,
          NEW_KAM_DB_DRIVER,
          NEW_KAM_DB_TYPE,
          NEW_KAM_DB_PORT,
          NEW_KAM_DB_NAME,
          NEW_KAM_DB_USER,
          NEW_KAM_DB_PASS,
          NEW_KAM_KAMCMD_PATH,
          NEW_KAM_CFG_PATH,
          NEW_KAM_TLSCFG_PATH,
          NEW_RTP_CFG_PATH,
          NEW_FLT_CARRIER,
          NEW_FLT_PBX,
          NEW_FLT_MSTEAMS,
          NEW_FLT_OUTBOUND,
          NEW_FLT_INBOUND,
          NEW_FLT_LCR_MIN,
          NEW_FLT_FWD_MIN,
          NEW_DEFAULT_AUTH_DOMAIN,
          NEW_TELEBLOCK_GW_ENABLED,
          NEW_TELEBLOCK_GW_IP,
          NEW_TELEBLOCK_GW_PORT,
          NEW_TELEBLOCK_MEDIA_IP,
          NEW_TELEBLOCK_MEDIA_PORT,
          NEW_FLOWROUTE_ACCESS_KEY,
          NEW_FLOWROUTE_SECRET_KEY,
          NEW_FLOWROUTE_API_ROOT_URL,
          NEW_HOMER_ID,
          NEW_HOMER_HEP_HOST,
          NEW_HOMER_HEP_PORT,
          NEW_NETWORK_MODE,
          NEW_IPV6_ENABLED,
          NEW_INTERNAL_IP_ADDR,
          NEW_INTERNAL_IP_NET,
          NEW_INTERNAL_IP6_ADDR,
          NEW_INTERNAL_IP6_NET,
          NEW_INTERNAL_FQDN,
          NEW_EXTERNAL_IP_ADDR,
          NEW_EXTERNAL_IP6_ADDR,
          NEW_EXTERNAL_FQDN,
          NEW_PUBLIC_IFACE,
          NEW_PRIVATE_IFACE,
          NEW_UPLOAD_FOLDER,
          NEW_MAIL_SERVER,
          NEW_MAIL_PORT,
          NEW_MAIL_USE_TLS,
          NEW_MAIL_USERNAME,
          NEW_MAIL_PASSWORD,
          NEW_MAIL_ASCII_ATTACHMENTS,
          NEW_MAIL_DEFAULT_SENDER,
          NEW_MAIL_DEFAULT_SUBJECT,
          NEW_DSIP_CORE_LICENSE,
          NEW_DSIP_STIRSHAKEN_LICENSE,
          NEW_DSIP_TRANSNEXUS_LICENSE,
          NEW_DSIP_MSTEAMS_LICENSE);

  IF NEW_DSIP_CLUSTER_SYNC = 1 THEN
    UPDATE dsip_settings
    SET DSIP_PROTO             = NEW_DSIP_PROTO,
        DSIP_PORT              = NEW_DSIP_PORT,
        DSIP_USERNAME          = NEW_DSIP_USERNAME,
        DSIP_PASSWORD          = NEW_DSIP_PASSWORD,
        DSIP_IPC_PASS          = NEW_DSIP_IPC_PASS,
        DSIP_API_PROTO         = NEW_DSIP_API_PROTO,
        DSIP_API_PORT          = NEW_DSIP_API_PORT,
        DSIP_PRIV_KEY          = NEW_DSIP_PRIV_KEY,
        DSIP_PID_FILE          = NEW_DSIP_PID_FILE,
        DSIP_UNIX_SOCK         = NEW_DSIP_UNIX_SOCK,
        DSIP_IPC_SOCK          = NEW_DSIP_IPC_SOCK,
        DSIP_API_TOKEN         = NEW_DSIP_API_TOKEN,
        DSIP_LOG_LEVEL         = NEW_DSIP_LOG_LEVEL,
        DSIP_LOG_FACILITY      = NEW_DSIP_LOG_FACILITY,
        DSIP_SSL_KEY           = NEW_DSIP_SSL_KEY,
        DSIP_SSL_CERT          = NEW_DSIP_SSL_CERT,
        DSIP_SSL_CA            = NEW_DSIP_SSL_CA,
        DSIP_SSL_EMAIL         = NEW_DSIP_SSL_EMAIL,
        DSIP_CERTS_DIR         = NEW_DSIP_CERTS_DIR,
        VERSION                = NEW_VERSION,
        DEBUG                  = NEW_DEBUG,
        `ROLE`                 = NEW_ROLE,
        GUI_INACTIVE_TIMEOUT   = NEW_GUI_INACTIVE_TIMEOUT,
        KAM_DB_HOST            = NEW_KAM_DB_HOST,
        KAM_DB_DRIVER          = NEW_KAM_DB_DRIVER,
        KAM_DB_TYPE            = NEW_KAM_DB_TYPE,
        KAM_DB_PORT            = NEW_KAM_DB_PORT,
        KAM_DB_NAME            = NEW_KAM_DB_NAME,
        KAM_DB_USER            = NEW_KAM_DB_USER,
        KAM_DB_PASS            = NEW_KAM_DB_PASS,
        KAM_KAMCMD_PATH        = NEW_KAM_KAMCMD_PATH,
        KAM_CFG_PATH           = NEW_KAM_CFG_PATH,
        KAM_TLSCFG_PATH        = NEW_KAM_TLSCFG_PATH,
        RTP_CFG_PATH           = NEW_RTP_CFG_PATH,
        FLT_CARRIER            = NEW_FLT_CARRIER,
        FLT_PBX                = NEW_FLT_PBX,
        FLT_MSTEAMS            = NEW_FLT_MSTEAMS,
        FLT_OUTBOUND           = NEW_FLT_OUTBOUND,
        FLT_INBOUND            = NEW_FLT_INBOUND,
        FLT_LCR_MIN            = NEW_FLT_LCR_MIN,
        FLT_FWD_MIN            = NEW_FLT_FWD_MIN,
        DEFAULT_AUTH_DOMAIN    = NEW_DEFAULT_AUTH_DOMAIN,
        TELEBLOCK_GW_ENABLED   = NEW_TELEBLOCK_GW_ENABLED,
        TELEBLOCK_GW_IP        = NEW_TELEBLOCK_GW_IP,
        TELEBLOCK_GW_PORT      = NEW_TELEBLOCK_GW_PORT,
        TELEBLOCK_MEDIA_IP     = NEW_TELEBLOCK_MEDIA_IP,
        TELEBLOCK_MEDIA_PORT   = NEW_TELEBLOCK_MEDIA_PORT,
        FLOWROUTE_ACCESS_KEY   = NEW_FLOWROUTE_ACCESS_KEY,
        FLOWROUTE_SECRET_KEY   = NEW_FLOWROUTE_SECRET_KEY,
        FLOWROUTE_API_ROOT_URL = NEW_FLOWROUTE_API_ROOT_URL,
        HOMER_HEP_HOST         = NEW_HOMER_HEP_HOST,
        HOMER_HEP_PORT         = NEW_HOMER_HEP_PORT,
        UPLOAD_FOLDER          = NEW_UPLOAD_FOLDER,
        MAIL_SERVER            = NEW_MAIL_SERVER,
        MAIL_PORT              = NEW_MAIL_PORT,
        MAIL_USE_TLS           = NEW_MAIL_USE_TLS,
        MAIL_USERNAME          = NEW_MAIL_USERNAME,
        MAIL_PASSWORD          = NEW_MAIL_PASSWORD,
        MAIL_ASCII_ATTACHMENTS = NEW_MAIL_ASCII_ATTACHMENTS,
        MAIL_DEFAULT_SENDER    = NEW_MAIL_DEFAULT_SENDER,
        MAIL_DEFAULT_SUBJECT   = NEW_MAIL_DEFAULT_SUBJECT
    WHERE DSIP_CLUSTER_ID = NEW_DSIP_CLUSTER_ID
      AND DSIP_CLUSTER_SYNC = 1
      AND DSIP_ID != NEW_DSIP_ID;
  END IF;
  COMMIT;
END //
DELIMITER ;

ALTER TABLE subscriber
  ADD IF NOT EXISTS  email_address VARCHAR(128) NOT NULL DEFAULT '',
  ADD IF NOT EXISTS  rpid          VARCHAR(128) NOT NULL DEFAULT '';

ALTER TABLE `acc`
  MODIFY `from_tag` VARCHAR (128) NOT NULL DEFAULT '',
  MODIFY `to_tag` VARCHAR (128) NOT NULL DEFAULT '',
  MODIFY `callid` VARCHAR (255) NOT NULL DEFAULT '',
  MODIFY `sip_reason` VARCHAR (255) NOT NULL DEFAULT '',
  MODIFY `time` DATETIME NOT NULL DEFAULT NOW(),
  MODIFY `dst_ouser` VARCHAR (128) NOT NULL DEFAULT '',
  MODIFY `dst_user` VARCHAR (128) NOT NULL DEFAULT '',
  MODIFY `dst_domain` VARCHAR (255) NOT NULL DEFAULT '',
  MODIFY `src_user` VARCHAR (128) NOT NULL DEFAULT '',
  MODIFY `src_domain` VARCHAR (255) NOT NULL DEFAULT '',
  MODIFY `src_gwgroupid` VARCHAR (10) NOT NULL DEFAULT '',
  MODIFY `dst_gwgroupid` VARCHAR (10) NOT NULL DEFAULT '';

ALTER TABLE `cdrs`
  MODIFY `cdr_id`          BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  MODIFY `src_username`    VARCHAR(128)        NOT NULL DEFAULT '',
  MODIFY `src_domain`      VARCHAR(255)        NOT NULL DEFAULT '',
  MODIFY `dst_username`    VARCHAR(128)        NOT NULL DEFAULT '',
  MODIFY `dst_domain`      VARCHAR(255)        NOT NULL DEFAULT '',
  MODIFY `dst_ousername`   VARCHAR(128)        NOT NULL DEFAULT '',
  MODIFY `call_start_time` DATETIME            NOT NULL,
  MODIFY `sip_call_id`     VARCHAR(255)        NOT NULL DEFAULT '',
  MODIFY `created`         DATETIME            NOT NULL DEFAULT NOW(),
  MODIFY `src_gwgroupid`   VARCHAR(10)         NOT NULL DEFAULT '',
  MODIFY `dst_gwgroupid`   VARCHAR(10)         NOT NULL DEFAULT '';

DROP PROCEDURE IF EXISTS `kamailio_cdrs`;
DELIMITER //
CREATE PROCEDURE `kamailio_cdrs`()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE bye_record INT DEFAULT 0;
  DECLARE v_src_user,v_src_domain,v_dst_user,v_dst_domain,v_callid,v_from_tag,
    v_to_tag,v_src_ip,v_calltype VARCHAR(255);
  DECLARE v_src_gwgroupid, v_dst_gwgroupid INT(11);
  DECLARE v_inv_time, v_bye_time DATETIME;
  DECLARE inv_cursor CURSOR FOR
    SELECT src_user,
           src_domain,
           dst_user,
           dst_domain,
           time,
           callid,
           from_tag,
           to_tag,
           src_ip,
           calltype,
           src_gwgroupid,
           dst_gwgroupid
    FROM acc
    WHERE method = 'INVITE'
      AND cdr_id = '0';
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
  OPEN inv_cursor;
  REPEAT
    FETCH inv_cursor INTO v_src_user, v_src_domain, v_dst_user, v_dst_domain,
      v_inv_time, v_callid, v_from_tag, v_to_tag, v_src_ip, v_calltype,
      v_src_gwgroupid, v_dst_gwgroupid;
    IF NOT done THEN
      SET bye_record = 0;
      SELECT 1, time
      INTO bye_record, v_bye_time
      FROM acc
      WHERE method = 'BYE'
        AND callid = v_callid
        AND ((from_tag = v_from_tag
        AND to_tag = v_to_tag)
        OR (from_tag = v_to_tag AND to_tag = v_from_tag))
      ORDER BY time ASC
      LIMIT 1;
      IF bye_record = 1 THEN
        INSERT INTO cdrs (src_username, src_domain, dst_username, dst_domain,
                          call_start_time, duration, sip_call_id, sip_from_tag,
                          sip_to_tag, src_ip, created, calltype, src_gwgroupid, dst_gwgroupid)
        VALUES (v_src_user, v_src_domain, v_dst_user, v_dst_domain, v_inv_time,
                UNIX_TIMESTAMP(v_bye_time) - UNIX_TIMESTAMP(v_inv_time),
                v_callid, v_from_tag, v_to_tag, v_src_ip, NOW(), v_calltype,
                v_src_gwgroupid, v_dst_gwgroupid);
        UPDATE acc
        SET cdr_id=LAST_INSERT_ID()
        WHERE callid = v_callid
          AND from_tag = v_from_tag
          AND to_tag = v_to_tag;
      END IF;
      SET done = 0;
    END IF;
  UNTIL done END REPEAT;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS `kamailio_rating`;
DELIMITER //
CREATE PROCEDURE `kamailio_rating`(`rgroup` VARCHAR(64))
BEGIN
  DECLARE done, rate_record, vx_cost INT DEFAULT 0;
  DECLARE v_cdr_id BIGINT DEFAULT 0;
  DECLARE v_duration, v_rate_unit, v_time_unit INT DEFAULT 0;
  DECLARE v_dst_username VARCHAR(255);
  DECLARE cdrs_cursor CURSOR FOR SELECT cdr_id, dst_username, duration
                                 FROM cdrs
                                 WHERE rated = 0;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
  OPEN cdrs_cursor;
  REPEAT
    FETCH cdrs_cursor INTO v_cdr_id, v_dst_username, v_duration;
    IF NOT done THEN
      SET rate_record = 0;
      SELECT 1, rate_unit, time_unit
      INTO rate_record, v_rate_unit, v_time_unit
      FROM billing_rates
      WHERE rate_group = rgroup
        AND v_dst_username LIKE CONCAT(prefix, '%')
      ORDER BY prefix DESC
      LIMIT 1;
      IF rate_record = 1 THEN
        SET vx_cost = v_rate_unit * CEIL(v_duration / v_time_unit);
        UPDATE cdrs SET rated=1, cost=vx_cost WHERE cdr_id = v_cdr_id;
      END IF;
      SET done = 0;
    END IF;
  UNTIL done END REPEAT;
END //
DELIMITER ;
EOF
) | sqlAsTransaction --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT"

if (( $? != 0 )); then
    printerr 'Failed merging DB schema'
    exit 1
fi

printdbg 'configuring dsiprouter GUI'
if (( ${BOOTSTRAPPING_UPGRADE:-0} == 1 )); then
    # a few stragglers that need copied over
    cp -f /opt/dsiprouter/gui/modules/fusionpbx/certs/cert.key /tmp/dsiprouter/gui/modules/fusionpbx/certs/cert.key
    cp -f /opt/dsiprouter/gui/modules/fusionpbx/certs/cert_combined.crt /tmp/dsiprouter/gui/modules/fusionpbx/certs/cert.key
    # use the bootstrap repo instead cloning again
    rm -rf /opt/dsiprouter
    mv -f /tmp/dsiprouter /opt/dsiprouter
else
    # fresh repo coming up
    rm -rf /opt/dsiprouter
    git clone --depth 1 -b v0.72 https://github.com/dOpensource/dsiprouter.git /opt/dsiprouter
fi

printdbg 'installing python dependencies for the GUI'
python3 -m pip install -r ${DSIP_PROJECT_DIR}/gui/requirements.txt
python3 -m pip install --force-reinstall Werkzeug

printdbg 'generating dynamic config files for the GUI'
dsiprouter configuredsip &&
setConfigAttrib 'DSIP_USERNAME' "$DSIP_USERNAME" ${DSIP_CONFIG_FILE} -q &&
setConfigAttrib 'DSIP_PASSWORD' "$DSIP_PASSWORD" ${DSIP_CONFIG_FILE} -qb &&
setConfigAttrib 'DSIP_API_TOKEN' "$DSIP_API_TOKEN" ${DSIP_CONFIG_FILE} -qb &&
setConfigAttrib 'KAM_DB_USER' "$KAM_DB_USER" ${DSIP_CONFIG_FILE} -q &&
setConfigAttrib 'KAM_DB_PASS' "$KAM_DB_PASS" ${DSIP_CONFIG_FILE} -qb &&
setConfigAttrib 'KAM_DB_HOST' "$KAM_DB_HOST" ${DSIP_CONFIG_FILE} -q &&
setConfigAttrib 'KAM_DB_PORT' "$KAM_DB_PORT" ${DSIP_CONFIG_FILE} -q &&
setConfigAttrib 'KAM_DB_NAME' "$KAM_DB_NAME" ${DSIP_CONFIG_FILE} -q &&
setConfigAttrib 'MAIL_USERNAME' "$MAIL_USERNAME" ${DSIP_CONFIG_FILE} -q &&
setConfigAttrib 'MAIL_PASSWORD' "$MAIL_PASSWORD" ${DSIP_CONFIG_FILE} -qb &&
setConfigAttrib 'ROOT_DB_USER' "$ROOT_DB_USER" ${DSIP_CONFIG_FILE} -q &&
{
    if ! grep -q -oP '(b""".*"""|'"b'''.*'''"'|b".*"|'"b'.*')" <<<"$ROOT_DB_PASS"; then
        setConfigAttrib 'ROOT_DB_PASS' "$ROOT_DB_PASS" ${DSIP_CONFIG_FILE} -q
    else
        setConfigAttrib 'ROOT_DB_PASS' "$ROOT_DB_PASS" ${DSIP_CONFIG_FILE} -qb
    fi
} &&
setConfigAttrib 'ROOT_DB_NAME' "$ROOT_DB_NAME" ${DSIP_CONFIG_FILE} -q &&
printdbg 'successfully generated new settings file' ||
{
    printerr 'failed generating new settings file'
    exit 1
}

printdbg 'generating documentation for the GUI'
(
    cd ${DSIP_PROJECT_DIR}/docs
    make html >/dev/null 2>&1
)

printdbg 'generating documentation for the CLI'
cp -f ${DSIP_PROJECT_DIR}/resources/man/dsiprouter.1 /usr/share/man/man1/
gzip -f /usr/share/man/man1/dsiprouter.1
mandb
cp -f ${DSIP_PROJECT_DIR}/dsiprouter/dsip_completion.sh /etc/bash_completion.d/dsiprouter

printdbg 'upgrading systemd service configurations'
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

for SERVICE in kamailio nginx dsiprouter; do
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.${SERVICE}installed" ]]; then
        SVC_FILE=$(grep -oP "$SERVICE-v[0-9]+\.service" ${DSIP_PROJECT_DIR}/$SERVICE/${DISTRO}/${DISTRO_MAJOR_VER}.sh)
        cp -f ${DSIP_PROJECT_DIR}/$SERVICE/systemd/$SVC_FILE /etc/systemd/system/$SERVICE.service
    fi
done

if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
    SVC_FILE=$(grep -m 1 -oP "rtpengine-v[0-9]+\.service" ${DSIP_PROJECT_DIR}/rtpengine/${DISTRO}/install.sh)
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/systemd/$SVC_FILE /etc/systemd/system/rtpengine.service
fi

DSIP_SYSTEM_CONFIG_DIR="/etc/dsiprouter"
DSIP_CERTS_DIR="${DSIP_SYSTEM_CONFIG_DIR}/certs"
cp -f ${DSIP_PROJECT_DIR}/nginx/systemd/nginx-watcher.service /etc/systemd/system/nginx-watcher.service
perl -p \
    -e "s%PathChanged\=.*%PathChanged=${DSIP_CERTS_DIR}/%;" \
    ${DSIP_PROJECT_DIR}/nginx/systemd/nginx-watcher.path >/etc/systemd/system/nginx-watcher.path
chmod 644 /etc/systemd/system/nginx-watcher.service
chmod 644 /etc/systemd/system/nginx-watcher.path

systemctl daemon-reload

# generate mysql service if needed
reconfigureMysqlSystemdService

printdbg 'upgrading kamailio configs'
dsiprouter configurekam

printdbg 'upgrading rtpengine configs'
dsiprouter updatertpconfig

printdbg 'upgrading dnsmasq configs'
dsiprouter updatednsconfig

printdbg 'updating file permissions'
dsiprouter chown

printdbg 'restarting services'
systemctl restart dnsmasq
systemctl restart kamailio
systemctl restart nginx
systemctl restart dsiprouter
systemctl restart rtpengine

exit 0
