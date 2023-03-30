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

ALTER TABLE dsip_settings
  MODIFY DSIP_ID VARBINARY(128) COLLATE 'binary' NOT NULL,
  MODIFY DSIP_PASSWORD VARBINARY(128) COLLATE 'binary' NOT NULL,
  MODIFY DSIP_IPC_PASS VARBINARY(160) COLLATE 'binary' NOT NULL,
  MODIFY DSIP_API_TOKEN VARBINARY(160) COLLATE 'binary' NOT NULL,
  DROP IF EXISTS SQLALCHEMY_TRACK_MODIFICATIONS,
  DROP IF EXISTS SQLALCHEMY_SQL_DEBUG,
  MODIFY VERSION VARCHAR(32) NOT NULL,
  MODIFY KAM_DB_PASS VARBINARY(160) COLLATE 'binary' NOT NULL,
  ADD IF NOT EXISTS  HOMER_ID                INT                             NOT NULL AFTER FLOWROUTE_API_ROOT_URL,
  ADD IF NOT EXISTS  NETWORK_MODE            INT                             NOT NULL DEFAULT 0 AFTER HOMER_HEP_PORT,
  ADD IF NOT EXISTS  INTERNAL_FQDN           VARCHAR(255)                    NOT NULL DEFAULT '' AFTER INTERNAL_IP6_NET,
  ADD IF NOT EXISTS  PUBLIC_IFACE            VARCHAR(255)                    NOT NULL DEFAULT '' AFTER EXTERNAL_FQDN,
  ADD IF NOT EXISTS  PRIVATE_IFACE           VARCHAR(255)                    NOT NULL DEFAULT '' AFTER PUBLIC_IFACE,
  ADD IF NOT EXISTS  DSIP_CORE_LICENSE       VARBINARY(160) COLLATE 'binary' NOT NULL,
  ADD IF NOT EXISTS  DSIP_STIRSHAKEN_LICENSE VARBINARY(160) COLLATE 'binary' NOT NULL,
  ADD IF NOT EXISTS  DSIP_TRANSNEXUS_LICENSE VARBINARY(160) COLLATE 'binary' NOT NULL,
  ADD IF NOT EXISTS  DSIP_MSTEAMS_LICENSE    VARBINARY(160) COLLATE 'binary' NOT NULL;

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
