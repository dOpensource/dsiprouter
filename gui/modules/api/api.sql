DROP TABLE IF EXISTS `dsip_endpoint_lease`;
CREATE TABLE `dsip_endpoint_lease` (
	  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	  `gwid` int(10) unsigned NOT NULL,
	  `sid` int(10) unsigned NOT NULL,
	  `expiration` datetime NOT NULL,
	  PRIMARY KEY (`id`)
);
