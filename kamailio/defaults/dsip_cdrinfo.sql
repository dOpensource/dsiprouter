DROP TABLE IF EXISTS `dsip_cdrinfo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_cdrinfo` (
  `gwgroupid` int(11) NOT NULL,
  `email` varchar(255) NOT NULL DEFAULT '',
  `send_interval` varchar(255) NOT NULL DEFAULT '* * 1 * *',
  `last_sent` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`gwgroupid`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
