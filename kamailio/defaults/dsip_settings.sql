--
-- TODO: add support for the rest of the settings
-- TODO: create functions for synchronizing with settings.py, such as:
-- FILE MODE -> settings.py saved to db settings or
-- DB MODE -> db settings saved to settings.py
--
DROP TABLE IF EXISTS dsip_settings;
/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE dsip_settings (
  DSIP_ID int unsigned NOT NULL DEFAULT 1,
  FLT_CARRIER int NOT NULL DEFAULT 8,
  FLT_PBX int NOT NULL DEFAULT 9,
  FLT_OUTBOUND int NOT NULL DEFAULT 8000,
  FLT_INBOUND int NOT NULL DEFAULT 9000,
  FLT_LCR_MIN int NOT NULL DEFAULT 10000,
  FLT_FWD_MIN int NOT NULL DEFAULT 20000,
  PRIMARY KEY (DSIP_ID)
) ENGINE = InnoDB
  DEFAULT CHARSET = latin1
  MAX_ROWS = 1
  MIN_ROWS = 1;
/*!40101 SET character_set_client = @saved_cs_client */;
