DROP TABLE IF EXISTS `dsip_maintmode`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_maintmode` (
    `ipaddr` varchar(64) NOT NULL DEFAULT '',
    `key_type` varchar(64) NOT NULL DEFAULT '0',
    `gwid` varchar(64) NOT NULL DEFAULT '',
    `value_type` varchar(64) NOT NULL DEFAULT '0',
    `status` TINYINT NOT NULL DEFAULT '1',
    PRIMARY KEY (`ipaddr`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
