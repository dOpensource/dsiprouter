DROP TABLE IF EXISTS dsip_gwgroup2lb;
CREATE TABLE dsip_gwgroup2lb (
  gwgroupid varchar(64) NOT NULL,
  setid varchar(64) NOT NULL,
  enabled char(1) NOT NULL DEFAULT '0',
  key_type varchar(64) NOT NULL DEFAULT '0',
  value_type varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (gwgroupid)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

-- create dsip_gwgroup2lb entry when dr_gw_lists entry created with lb or lb_ext fields in description
DROP TRIGGER IF EXISTS insert_gwgroup2lb;
DELIMITER //
CREATE TRIGGER insert_gwgroup2lb
  AFTER INSERT
  ON dr_gw_lists
  FOR EACH ROW
BEGIN
  DECLARE v_setid varchar(64);

  SET @new_gwgroupid := COALESCE(NEW.id, @new_gwgroupid, (
    SELECT auto_increment
    FROM information_schema.tables
    WHERE table_name = 'dr_gw_lists' AND table_schema = DATABASE()));

  IF NEW.description REGEXP '(?:lb:|lb_ext:)([0-9]+)' THEN
    SET v_setid = REGEXP_REPLACE(NEW.description, '.*(?:lb:|lb_ext:)([0-9]+).*', '\\1');
    REPLACE INTO dsip_gwgroup2lb
      VALUES (CAST(@new_gwgroupid AS char), CAST(v_setid AS char), DEFAULT, DEFAULT, DEFAULT);
  END IF;

  SET @new_gwgroupid = @new_gwgroupid + 1;
END; //
DELIMITER ;

-- update dsip_gwgroup2lb entry when dr_gw_lists entry description is updated
DROP TRIGGER IF EXISTS update_gwgroup2lb;
DELIMITER //
CREATE TRIGGER update_gwgroup2lb
  AFTER UPDATE
  ON dr_gw_lists
  FOR EACH ROW
BEGIN
  DECLARE v_gwgroupid varchar(64) DEFAULT NULL;
  DECLARE v_setid varchar(64) DEFAULT NULL;

  -- always update description changed
  IF NOT (NEW.description <=> OLD.description) THEN
    -- in case the gwgroupid changed
    SET v_gwgroupid = CAST(COALESCE(NEW.id, OLD.id) AS char);

    -- make sure we have a setid
    IF NEW.description REGEXP '(?:lb:|lb_ext:)([0-9]+)' THEN
      SET v_setid = REGEXP_REPLACE(NEW.description, '.*(?:lb:|lb_ext:)([0-9]+).*', '\\1');
      INSERT INTO dsip_gwgroup2lb VALUES(v_gwgroupid, v_setid, DEFAULT, DEFAULT, DEFAULT)
                                  ON DUPLICATE KEY UPDATE setid=v_setid;
    END IF;
  END IF;
END; //
DELIMITER ;

-- delete dsip_gwgroup2lb entry when dr_gw_lists entry deleted
DROP TRIGGER IF EXISTS delete_gwgroup2lb;
DELIMITER //
CREATE TRIGGER delete_gwgroup2lb
  AFTER DELETE
  ON dr_gw_lists
  FOR EACH ROW
BEGIN
  DELETE FROM dsip_gwgroup2lb WHERE gwgroupid = cast(OLD.id AS char);
END; //
DELIMITER ;

-- update dsip_gwgroup2lb when dr_rules are created
DROP TRIGGER IF EXISTS insert_rule_gwgroup2lb;
DELIMITER //
CREATE TRIGGER insert_rule_gwgroup2lb
  AFTER INSERT
  ON dr_rules
  FOR EACH ROW
BEGIN
  -- only inbound routes can have load balancing associated with it
  IF (NEW.groupid = 9000) THEN
    IF (NEW.description REGEXP 'lb_enabled:1(,|$)') THEN
      UPDATE dsip_gwgroup2lb SET enabled = '1' WHERE gwgroupid = REPLACE(NEW.gwlist, '#', '');
    ELSE
      UPDATE dsip_gwgroup2lb SET enabled = '0' WHERE gwgroupid = REPLACE(NEW.gwlist, '#', '');
    END IF;
  END IF;
END; //
DELIMITER ;

-- update dsip_gwgroup2lb when dr_rules are updated
DROP TRIGGER IF EXISTS update_rule_gwgroup2lb;
DELIMITER //
CREATE TRIGGER update_rule_gwgroup2lb
  AFTER UPDATE
  ON dr_rules
  FOR EACH ROW
BEGIN
  DECLARE v_gwgroupid varchar(64) DEFAULT NULL;
  DECLARE v_description varchar(255) DEFAULT '';
  DECLARE v_groupid varchar(255) DEFAULT '';

  SET v_gwgroupid = REPLACE(COALESCE(NEW.gwlist, OLD.gwlist), '#', '');
  SET v_description = COALESCE(NEW.description, OLD.description);
  SET v_groupid = CAST(COALESCE(NEW.groupid, OLD.groupid) AS int);

  -- only inbound routes can have load balancing associated with it
  IF (v_groupid = 9000) THEN
    IF (v_description REGEXP 'lb_enabled:1(,|$)') THEN
      UPDATE dsip_gwgroup2lb SET enabled = '1' WHERE gwgroupid = v_gwgroupid;
    ELSE
      UPDATE dsip_gwgroup2lb SET enabled = '0' WHERE gwgroupid = v_gwgroupid;
    END IF;
  END IF;
END; //
DELIMITER ;

-- update dsip_gwgroup2lb when dr_rules are deleted
DROP TRIGGER IF EXISTS delete_rule_gwgroup2lb;
DELIMITER //
CREATE TRIGGER delete_rule_gwgroup2lb
  AFTER DELETE
  ON dr_rules
  FOR EACH ROW
BEGIN
  -- only inbound routes can have load balancing associated with it
  IF (OLD.groupid = 9000) THEN
    -- if it is the last rule for the gwgroup then delete load balancing entry
    IF ((SELECT COUNT(ruleid) FROM dr_rules WHERE gwlist=OLD.gwlist AND groupid=OLD.groupid AND ruleid!=OLD.ruleid) = 0) THEN
      DELETE FROM dsip_gwgroup2lb WHERE gwgroupid=REPLACE(OLD.gwlist, '#', '');
    END IF;
  END IF;
END; //
DELIMITER ;

