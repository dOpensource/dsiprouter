#!/usr/bin/env bash

# set project dir (where src files are located)
export DSIP_PROJECT_DIR=${DSIP_PROJECT_DIR:-/opt/dsiprouter}
# import dsip_lib utility / shared functions
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

printdbg 'backing up configs just in case the upgrade fails'
BACKUP_DIR="/var/backups"
CURR_BACKUP_DIR="${BACKUP_DIR}/$(date '+%s')"
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
    python3 -c "from util.security import AES_CTR; print(AES_CTR.encrypt('$1').decode('utf-8'), end='');"
) }
DSIP_PASSWORD_HASH=$(hashCreds "$DSIP_PASSWORD")
DSIP_API_TOKEN_CIPHERTEXT=$(encryptCreds "$DSIP_API_TOKEN")
DSIP_IPC_PASS_CIPHERTEXT=$(encryptCreds "$DSIP_IPC_PASS")
KAM_DB_PASS_CIPHERTEXT=$(encryptCreds "$KAM_DB_PASS")
MAIL_PASSWORD_CIPHERTEXT=$(encryptCreds "$MAIL_PASSWORD")
ROOT_DB_PASS_CIPHERTEXT=$(encryptCreds "$ROOT_DB_PASS")

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

if (( ${BOOTSTRAPPING_UPGRADE:-0} == 1 )); then
    PROJECT_DSIP_DEFAULTS_DIR='/tmp/dsiprouter/kamailio/defaults'
else
    PROJECT_DSIP_DEFAULTS_DIR='/opt/dsiprouter/kamailio/defaults'
fi
perl -e "\$hlen='$HASHED_CREDS_ENCODED_MAX_LEN'; \$clen='$AESCTR_CREDS_ENCODED_MAX_LEN';" \
    -pe 's%\@HASHED_CREDS_ENCODED_MAX_LEN%$hlen%g; s%\@AESCTR_CREDS_ENCODED_MAX_LEN%$clen%g;' \
    ${PROJECT_DSIP_DEFAULTS_DIR}/dsip_settings.sql |
    mysql -s -N --user="$ROOT_DB_USER" --password="$ROOT_DB_PASS" --host="$KAM_DB_HOST" --port="$KAM_DB_PORT" "$KAM_DB_NAME"

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
    git clone --depth 1 -c advice.detachedHead=false -b v0.72-rel https://github.com/dOpensource/dsiprouter.git /opt/dsiprouter
fi
export DSIP_PROJECT_DIR=/opt/dsiprouter

printdbg 'installing python dependencies for the GUI'
python3 -m pip install -U Flask~=2.0 psycopg2_binary requests SQLAlchemy~=2.0 Werkzeug~=2.0

printdbg 'generating dynamic config files for the GUI'
dsiprouter configuredsip &&
setConfigAttrib 'DSIP_USERNAME' "$DSIP_USERNAME" /etc/dsiprouter/gui/settings.py -q &&
setConfigAttrib 'DSIP_PASSWORD' "$DSIP_PASSWORD_HASH" /etc/dsiprouter/gui/settings.py -qb &&
setConfigAttrib 'DSIP_API_TOKEN' "$DSIP_API_TOKEN_CIPHERTEXT" /etc/dsiprouter/gui/settings.py -qb &&
setConfigAttrib 'DSIP_IPC_PASS' "$DSIP_IPC_PASS_CIPHERTEXT" /etc/dsiprouter/gui/settings.py -qb &&
setConfigAttrib 'KAM_DB_USER' "$KAM_DB_USER" /etc/dsiprouter/gui/settings.py -q &&
setConfigAttrib 'KAM_DB_PASS' "$KAM_DB_PASS_CIPHERTEXT" /etc/dsiprouter/gui/settings.py -qb &&
setConfigAttrib 'KAM_DB_HOST' "$KAM_DB_HOST" /etc/dsiprouter/gui/settings.py -q &&
setConfigAttrib 'KAM_DB_PORT' "$KAM_DB_PORT" /etc/dsiprouter/gui/settings.py -q &&
setConfigAttrib 'KAM_DB_NAME' "$KAM_DB_NAME" /etc/dsiprouter/gui/settings.py -q &&
setConfigAttrib 'MAIL_USERNAME' "$MAIL_USERNAME" /etc/dsiprouter/gui/settings.py -q &&
setConfigAttrib 'MAIL_PASSWORD' "$MAIL_PASSWORD_CIPHERTEXT" /etc/dsiprouter/gui/settings.py -qb &&
setConfigAttrib 'ROOT_DB_USER' "$ROOT_DB_USER" /etc/dsiprouter/gui/settings.py -q &&
{
    if ! grep -q -oP '(b""".*"""|'"b'''.*'''"'|b".*"|'"b'.*')" <<<"$ROOT_DB_PASS"; then
        setConfigAttrib 'ROOT_DB_PASS' "$ROOT_DB_PASS" /etc/dsiprouter/gui/settings.py -q
    else
        setConfigAttrib 'ROOT_DB_PASS' "$ROOT_DB_PASS_CIPHERTEXT" /etc/dsiprouter/gui/settings.py -qb
    fi
} &&
setConfigAttrib 'ROOT_DB_NAME' "$ROOT_DB_NAME" /etc/dsiprouter/gui/settings.py -q &&
printdbg 'successfully generated new settings file' ||
{
    printerr 'failed generating new settings file'
    exit 1
}

if [[ "$LOAD_SETTINGS_FROM" == "db" ]]; then
    printdbg 'updating dsip_settings table, the GUI will be restarted multiple times...'
    setConfigAttrib 'LOAD_SETTINGS_FROM' 'file' /etc/dsiprouter/gui/settings.py &&
    systemctl restart dsiprouter &&
    setConfigAttrib 'LOAD_SETTINGS_FROM' 'db' /etc/dsiprouter/gui/settings.py &&
    systemctl restart dsiprouter ||
    {
        printerr 'failed updating dsip_settings DB table'
        exit 1
    }
else
    printdbg 'the dsip_settings table will be updated when the GUI service is restarted..'
fi

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
