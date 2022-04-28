-- update dr_gateways schema to fit our storage requirements
ALTER TABLE dr_gateways
  MODIFY COLUMN pri_prefix varchar(64) NOT NULL DEFAULT '',
  MODIFY COLUMN attrs varchar(255) NOT NULL DEFAULT '',
  MODIFY COLUMN description varchar(255) NOT NULL DEFAULT '{}',
  ADD CONSTRAINT CHECK (JSON_VALID(description));

-- update dr_gateways attrs column when entry created
DROP TRIGGER IF EXISTS insert_dr_gateways;
DELIMITER //
CREATE TRIGGER insert_dr_gateways
  BEFORE INSERT
  ON dr_gateways
  FOR EACH ROW
BEGIN

  -- set explicit defaults
  IF (NEW.gwid = 0) THEN
    SET NEW.gwid = NULL;
  END IF;
  IF (NEW.attrs IS NULL) THEN
    SET NEW.attrs = '';
  END IF;

  SET @new_gwid := COALESCE(NEW.gwid, @new_gwid, (
    SELECT auto_increment
    FROM information_schema.tables
    WHERE table_name = 'dr_gateways' AND table_schema = DATABASE()));

  -- only rewrite gwid,type part of attrs
  SET NEW.attrs = CONCAT(CAST(@new_gwid AS char), ',', CAST(NEW.type AS char),
                         SUBSTRING(NEW.attrs, LENGTH(SUBSTRING_INDEX(NEW.attrs, ',', 2)) + 1));
  SET @new_gwid = @new_gwid + 1;

END;//
DELIMITER ;

-- update dr_gateways attrs column when entry updated
DROP TRIGGER IF EXISTS update_dr_gateways;
DELIMITER //
CREATE TRIGGER update_dr_gateways
  BEFORE UPDATE
  ON dr_gateways
  FOR EACH ROW
BEGIN

  -- only rewrite gwid,type part of attrs
  SET NEW.attrs = CONCAT(CAST(NEW.gwid AS char), ',', CAST(NEW.type AS char),
                         SUBSTRING(NEW.attrs, LENGTH(SUBSTRING_INDEX(NEW.attrs, ',', 2)) + 1));

END;//
DELIMITER ;
