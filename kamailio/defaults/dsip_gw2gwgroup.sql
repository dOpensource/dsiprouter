DROP TABLE IF EXISTS `dsip_gw2gwgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsip_gw2gwgroup` (
    `gwid` varchar(64) NOT NULL,
    `gwgroupid` varchar(64) NOT NULL,
    `key_type` varchar(64) NOT NULL DEFAULT '0',
    `value_type` varchar(64) NOT NULL DEFAULT '0',
    PRIMARY KEY (`gwid`,`gwgroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;