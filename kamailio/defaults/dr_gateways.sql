-- update dr_gateways attrs column when entry created
DROP TRIGGER IF EXISTS insert_dr_gateways;
DELIMITER //
CREATE TRIGGER insert_dr_gateways
  BEFORE INSERT
  ON dr_gateways
  FOR EACH ROW
BEGIN

  DECLARE new_gwid int;
  SET new_gwid := IF(ISNULL(NEW.gwid),
    (SELECT auto_increment
    FROM information_schema.tables
    WHERE table_name = 'dr_gateways' AND table_schema = DATABASE()),
    NEW.gwid);

  SET NEW.attrs = CONCAT(CAST(new_gwid AS char), ',', CAST(NEW.type AS char));

END;//
DELIMITER ;
