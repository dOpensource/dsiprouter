DROP TABLE IF EXISTS dsip_gw2gwgroup;
/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE dsip_gw2gwgroup (
  gwid varchar(64) NOT NULL,
  gwgroupid varchar(64) NOT NULL,
  key_type varchar(64) NOT NULL DEFAULT '0',
  value_type varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (gwid, gwgroupid)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;
/*!40101 SET character_set_client = @saved_cs_client */;


-- create gw2gwgroup entries when dr_gw_lists entry created
DROP TRIGGER IF EXISTS insert_gw2gwgroup;
DELIMITER //
CREATE TRIGGER insert_gw2gwgroup
  AFTER INSERT
  ON dr_gw_lists
  FOR EACH ROW
BEGIN

  DECLARE num_gws int DEFAULT 0;
  DECLARE gw_index int DEFAULT 1;

  IF CHAR_LENGTH(NEW.gwlist) > 0 THEN
    SET num_gws := (CHAR_LENGTH(NEW.gwlist) - CHAR_LENGTH(REPLACE(NEW.gwlist, ',', '')) + 1);

    -- loop through gwlist (1-based index)
    WHILE gw_index <= num_gws
      DO
        INSERT IGNORE INTO dsip_gw2gwgroup
        VALUES (SUBSTRING_INDEX(SUBSTRING_INDEX(NEW.gwlist, ',', gw_index), ',', -1), cast(NEW.id AS char(64)), DEFAULT,
                DEFAULT);
        SET gw_index := gw_index + 1;
      END WHILE;
  END IF;

END;//
DELIMITER ;

-- update gw2gwgroup entries when dr_gw_lists entry updated
DROP TRIGGER IF EXISTS update_gw2gwgroup;
DELIMITER //
CREATE TRIGGER update_gw2gwgroup
  AFTER UPDATE
  ON dr_gw_lists
  FOR EACH ROW
BEGIN

  DECLARE num_gws int DEFAULT 0;
  DECLARE gw_index int DEFAULT 1;

  -- best approach is to delete OLD rows and create NEW ones
  IF NOT (NEW.gwlist <=> OLD.gwlist) THEN
    DELETE FROM dsip_gw2gwgroup WHERE gwgroupid = cast(OLD.id AS char(64));

    IF CHAR_LENGTH(NEW.gwlist) > 0 THEN
      SET num_gws := (CHAR_LENGTH(NEW.gwlist) - CHAR_LENGTH(REPLACE(NEW.gwlist, ',', '')) + 1);

      -- loop through gwlist (1-based index)
      WHILE gw_index <= num_gws
        DO
          INSERT IGNORE INTO dsip_gw2gwgroup
          VALUES (SUBSTRING_INDEX(SUBSTRING_INDEX(NEW.gwlist, ',', gw_index), ',', -1), cast(NEW.id AS char(64)),
                  DEFAULT,
                  DEFAULT);
          SET gw_index := gw_index + 1;
        END WHILE;
    END IF;

    -- only need to update gwid here
  ELSEIF NOT (NEW.id <=> OLD.id) THEN
    UPDATE dsip_gw2gwgroup SET gwgroupid = cast(NEW.id AS char(64)) WHERE gwgroupid = cast(OLD.id AS char(64));
  END IF;

END;//
DELIMITER ;

-- delete gw2gwgroup entries when dr_gw_lists entry deleted
DROP TRIGGER IF EXISTS delete_gw2gwgroup;
DELIMITER //
CREATE TRIGGER delete_gw2gwgroup
  AFTER DELETE
  ON dr_gw_lists
  FOR EACH ROW
BEGIN

  DELETE FROM dsip_gw2gwgroup WHERE gwgroupid = cast(OLD.id AS char(64));

END;//
DELIMITER ;
