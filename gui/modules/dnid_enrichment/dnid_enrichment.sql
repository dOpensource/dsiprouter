DROP TABLE IF EXISTS dsip_dnid_enrich_lnp;
/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE dsip_dnid_enrich_lnp (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  dnid varchar(64) NOT NULL,
  country_code varchar(64) NOT NULL DEFAULT '',
  routing_number varchar(64) NOT NULL DEFAULT '',
  description varchar(255) NOT NULL DEFAULT '{}',
  PRIMARY KEY (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

DROP TABLE IF EXISTS dsip_dnid_lnp_mapping;
DROP VIEW IF EXISTS dsip_dnid_lnp_mapping;
/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE VIEW dsip_dnid_lnp_mapping AS
  SELECT dnid, CONCAT(country_code, routing_number) AS prefix, '0' AS key_type, '0' AS value_type
  FROM dsip_dnid_enrich_lnp;
/*!40101 SET character_set_client = @saved_cs_client */;
