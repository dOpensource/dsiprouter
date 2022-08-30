DROP TABLE IF EXISTS `dsip_endpoint_lease`;
CREATE TABLE `dsip_endpoint_lease` (
	  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	  `gwid` int(10) unsigned NOT NULL,
	  `sid` int(10) unsigned NOT NULL,
	  `expiration` datetime NOT NULL,
	  PRIMARY KEY (`id`)
);



DROP TABLE IF EXISTS `dsip_user`;
CREATE TABLE `dsip_user` (
  `id` INT NOT NULL auto_increment unique,
  `firstname` VARCHAR(255) NOT NULL,
  `lastname` VARCHAR(255) NULL,
  `username` VARCHAR(255) NOT NULL unique,
  `password` VARCHAR(255) NOT NULL,
  `roles` VARCHAR(255) NULL,
  `domains` VARCHAR(255) NULL,
  `token` VARCHAR(255) NULL,
  `token_expiration` DATETIME NULL,
  PRIMARY KEY (`id`));
