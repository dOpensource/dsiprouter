-- update dr_gateways attrs column when entry created
DROP TRIGGER IF EXISTS insert_dr_gateways;
DELIMITER //
CREATE TRIGGER insert_dr_gateways
  BEFORE INSERT
  ON dr_gateways
  FOR EACH ROW
BEGIN

  SET @new_gwid := COALESCE(NEW.gwid, @new_gwid, (
    SELECT auto_increment
    FROM information_schema.tables
    WHERE table_name = 'dr_gateways' AND table_schema = DATABASE()));

  SET NEW.attrs = CONCAT(CAST(@new_gwid AS char), ',', CAST(NEW.type AS char));
  SET @new_gwid = @new_gwid + 1;

END;//
DELIMITER ;

-- update dr_gateways attrs column when gwid updated
DROP TRIGGER IF EXISTS update_dr_gateways;
DELIMITER //
CREATE TRIGGER update_dr_gateways
  BEFORE UPDATE
  ON dr_gateways
  FOR EACH ROW
BEGIN

  IF NOT (NEW.gwid <=> OLD.gwid AND OLD.type <=> NEW.type) THEN
    SET NEW.attrs = CONCAT(CAST(NEW.gwid AS char), ',', CAST(NEW.type AS char));
  END IF;

END;//
DELIMITER ;
