DROP TABLE IF EXISTS `dsip_call_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_call_settings` (
    `gwgroupid` INT UNSIGNED NOT NULL,
    `limit` INT UNSIGNED DEFAULT NULL,
    `timeout` INT UNSIGNED DEFAULT NULL,
    PRIMARY KEY (`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;