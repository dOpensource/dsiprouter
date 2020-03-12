DROP TABLE IF EXISTS `dsip_cdrinfo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_cdrinfo` (
  `gwgroupid` int(11) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `send_date` int(2) DEFAULT NULL,
  `last_sent` datetime DEFAULT NULL,
  PRIMARY KEY (`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
