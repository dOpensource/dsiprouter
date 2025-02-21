-- dr_ruleid refers to owning inbound rule
DROP TABLE IF EXISTS dsip_hardfwd;
/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE dsip_hardfwd (
  dr_ruleid varchar(64) NOT NULL,
  did varchar(64) NOT NULL,
  dr_groupid varchar(64) NOT NULL,
  key_type varchar(64) NOT NULL DEFAULT '0',
  value_type varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (dr_ruleid)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

-- dr_ruleid refers to owning inbound rule
DROP TABLE IF EXISTS dsip_failfwd;
/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE dsip_failfwd (
  dr_ruleid varchar(64) NOT NULL,
  did varchar(64) NOT NULL,
  dr_groupid varchar(64) NOT NULL,
  key_type varchar(64) NOT NULL DEFAULT '0',
  value_type varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (dr_ruleid)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

DROP TABLE IF EXISTS dsip_prefix_mapping;
DROP VIEW IF EXISTS dsip_prefix_mapping;
/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE VIEW dsip_prefix_mapping AS
  SELECT prefix, CAST(ruleid AS char(64)) AS ruleid, CAST(priority AS char(64)) AS priority, '0' AS key_type, '0' AS value_type
  FROM dr_rules
  WHERE groupid = FLT_INBOUND_REPLACE;
/*!40101 SET character_set_client = @saved_cs_client */;
