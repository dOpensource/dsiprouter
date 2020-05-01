DROP TABLE IF EXISTS `dsip_calllimit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_calllimit` (
    `gwgroupid` varchar(64) NOT NULL,
    `limit` varchar(64) NOT NULL DEFAULT '0',
    `status` tinyint(1) NOT NULL DEFAULT 1,
    `key_type` varchar(64) NOT NULL DEFAULT '0',
    `value_type` varchar(64) NOT NULL DEFAULT '0',
    PRIMARY KEY (`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;