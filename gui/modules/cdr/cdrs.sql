-- MySQL dump 10.14  Distrib 5.5.52-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: kamailio
-- ------------------------------------------------------
-- Server version	5.5.52-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT = @@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS = @@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION = @@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE = @@TIME_ZONE */;
/*!40103 SET TIME_ZONE = '+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS = @@UNIQUE_CHECKS, UNIQUE_CHECKS = 0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS = 0 */;
/*!40101 SET @OLD_SQL_MODE = @@SQL_MODE, SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES = @@SQL_NOTES, SQL_NOTES = 0 */;

--
-- Table structure for table `acc`
--

DROP TABLE IF EXISTS `acc`;
/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acc` (
  `id`            int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `method`        varchar(16)      NOT NULL DEFAULT '',
  `from_tag`      varchar(64)      NOT NULL DEFAULT '',
  `to_tag`        varchar(64)      NOT NULL DEFAULT '',
  `callid`        varchar(128)     NOT NULL DEFAULT '',
  `sip_code`      char(3)          NOT NULL DEFAULT '',
  `sip_reason`    varchar(32)      NOT NULL DEFAULT '',
  `time`          datetime         NOT NULL DEFAULT '2000-01-01 00:00:00',
  `src_ip`        varchar(64)      NOT NULL DEFAULT '',
  `dst_ouser`     varchar(64)      NOT NULL DEFAULT '',
  `dst_user`      varchar(64)      NOT NULL DEFAULT '',
  `dst_domain`    varchar(128)     NOT NULL DEFAULT '',
  `src_user`      varchar(64)      NOT NULL DEFAULT '',
  `src_domain`    varchar(128)     NOT NULL DEFAULT '',
  `cdr_id`        int(10) UNSIGNED NOT NULL DEFAULT '0',
  `calltype`      varchar(20)               DEFAULT NULL,
  `src_gwgroupid` int(10) UNSIGNED NOT NULL DEFAULT '0',
  `dst_gwgroupid` int(10) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `acc_callid` (`callid`)
  );
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cdrs`
--

DROP TABLE IF EXISTS `cdrs`;
/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cdrs` (
  `cdr_id`          bigint(20)       NOT NULL AUTO_INCREMENT,
  `src_username`    varchar(64)      NOT NULL DEFAULT '',
  `src_domain`      varchar(128)     NOT NULL DEFAULT '',
  `dst_username`    varchar(64)      NOT NULL DEFAULT '',
  `dst_domain`      varchar(128)     NOT NULL DEFAULT '',
  `dst_ousername`   varchar(64)      NOT NULL DEFAULT '',
  `call_start_time` datetime         NOT NULL DEFAULT '2000-01-01 00:00:00',
  `duration`        int(10) UNSIGNED NOT NULL DEFAULT '0',
  `sip_call_id`     varchar(128)     NOT NULL DEFAULT '',
  `sip_from_tag`    varchar(128)     NOT NULL DEFAULT '',
  `sip_to_tag`      varchar(128)     NOT NULL DEFAULT '',
  `src_ip`          varchar(64)      NOT NULL DEFAULT '',
  `cost`            int(11)          NOT NULL DEFAULT '0',
  `rated`           int(11)          NOT NULL DEFAULT '0',
  `created`         datetime         NOT NULL,
  `calltype`        varchar(20)               DEFAULT NULL,
  `fraud`           bool             NOT NULL DEFAULT '0',
  `src_gwgroupid`   int(10) UNSIGNED NOT NULL DEFAULT '0',
  `dst_gwgroupid`   int(10) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`cdr_id`)
  );
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'kamailio'
--
/*!50003 DROP PROCEDURE IF EXISTS `kamailio_cdrs` */;
/*!50003 SET @saved_cs_client = @@character_set_client */;
/*!50003 SET @saved_cs_results = @@character_set_results */;
/*!50003 SET @saved_col_connection = @@collation_connection */;
/*!50003 SET character_set_client = utf8 */;
/*!50003 SET character_set_results = utf8 */;
/*!50003 SET collation_connection = utf8_general_ci */;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = '' */;
DELIMITER ;;
CREATE PROCEDURE `kamailio_cdrs`()
BEGIN
  DECLARE done int DEFAULT 0;
  DECLARE bye_record int DEFAULT 0;
  DECLARE v_src_user,v_src_domain,v_dst_user,v_dst_domain,v_callid,v_from_tag,
    v_to_tag,v_src_ip,v_calltype varchar(64);
  DECLARE v_src_gwgroupid, v_dst_gwgroupid int(11);
  DECLARE v_inv_time, v_bye_time datetime;
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
        SET cdr_id=last_insert_id()
        WHERE callid = v_callid
          AND from_tag = v_from_tag
          AND to_tag = v_to_tag;
      END IF;
      SET done = 0;
    END IF;
  UNTIL done END REPEAT;
END ;;
DELIMITER ;

/*!50003 SET sql_mode = @saved_sql_mode */;
/*!50003 SET character_set_client = @saved_cs_client */;
/*!50003 SET character_set_results = @saved_cs_results */;
/*!50003 SET collation_connection = @saved_col_connection */;
/*!50003 DROP PROCEDURE IF EXISTS `kamailio_rating` */;
/*!50003 SET @saved_cs_client = @@character_set_client */;
/*!50003 SET @saved_cs_results = @@character_set_results */;
/*!50003 SET @saved_col_connection = @@collation_connection */;
/*!50003 SET character_set_client = utf8 */;
/*!50003 SET character_set_results = utf8 */;
/*!50003 SET collation_connection = utf8_general_ci */;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = '' */;
DELIMITER ;;
CREATE PROCEDURE `kamailio_rating`(`rgroup` varchar(64))
BEGIN
  DECLARE done, rate_record, vx_cost int DEFAULT 0;
  DECLARE v_cdr_id bigint DEFAULT 0;
  DECLARE v_duration, v_rate_unit, v_time_unit int DEFAULT 0;
  DECLARE v_dst_username varchar(64);
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
        AND v_dst_username LIKE concat(prefix, '%')
      ORDER BY prefix DESC
      LIMIT 1;
      IF rate_record = 1 THEN
        SET vx_cost = v_rate_unit * CEIL(v_duration / v_time_unit);
        UPDATE cdrs SET rated=1, cost=vx_cost WHERE cdr_id = v_cdr_id;
      END IF;
      SET done = 0;
    END IF;
  UNTIL done END REPEAT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;
/*!50003 SET character_set_client = @saved_cs_client */;
/*!50003 SET character_set_results = @saved_cs_results */;
/*!50003 SET collation_connection = @saved_col_connection */;
/*!40103 SET TIME_ZONE = @OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE = @OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS = @OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT = @OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS = @OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION = @OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES = @OLD_SQL_NOTES */;

-- Dump completed on 2017-10-07 11:57:33
