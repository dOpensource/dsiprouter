-- update uacreg schema
ALTER TABLE uacreg
  MODIFY COLUMN `l_domain` VARCHAR(253) NOT NULL DEFAULT '',
  MODIFY COLUMN `r_domain` VARCHAR(253) NOT NULL DEFAULT '',
  MODIFY COLUMN `realm` varchar(253) NOT NULL DEFAULT '',
  MODIFY COLUMN `auth_proxy` varchar(16000) NOT NULL DEFAULT '';