DROP TABLE IF EXISTS `dsip_hardfwd`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_hardfwd` (
    `gwgroupid` varchar(64) NOT NULL,
    `did` varchar(64) NOT NULL DEFAULT '',
    `dr_groupid` varchar(64) NOT NULL,
    `key_type` varchar(64) NOT NULL DEFAULT '0',
    `value_type` varchar(64) NOT NULL DEFAULT '0',
    PRIMARY KEY (`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

DROP TABLE IF EXISTS `dsip_failfwd`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_failfwd` (
    `gwgroupid` varchar(64) NOT NULL,
    `did` varchar(64) NOT NULL DEFAULT '',
    `dr_groupid` varchar(64) NOT NULL,
    `key_type` varchar(64) NOT NULL DEFAULT '0',
    `value_type` varchar(64) NOT NULL DEFAULT '0',
    PRIMARY KEY (`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
