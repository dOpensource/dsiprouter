DROP TABLE IF EXISTS `dsip_certificates`; 
CREATE TABLE IF NOT EXISTS `dsip_certificates` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `domain` VARCHAR(128) NULL,
  `type` VARCHAR(45) NULL,
  `email` VARCHAR(128) NULL,
  `cert` BLOB NULL,
  `key` BLOB NULL,
  PRIMARY KEY (`id`)
);
