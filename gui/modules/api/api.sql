DROP TABLE IF EXISTS `dsip_endpoint_lease`;
CREATE TABLE `dsip_endpoint_lease` (
	  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	  `gwid` int(10) unsigned NOT NULL,
	  `sid` int(10) unsigned NOT NULL,
	  `expiration` datetime NOT NULL,
	  PRIMARY KEY (`id`)
);

-- Legacy table kept for backward compat during deprecation period
-- New code should use dsip_users / dsip_groups / dsip_user_groups
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

-- Multi-user support tables
DROP TABLE IF EXISTS `dsip_user_groups`;
DROP TABLE IF EXISTS `dsip_groups`;
DROP TABLE IF EXISTS `dsip_users`;
CREATE TABLE `dsip_users` (
  `username` VARCHAR(255) NOT NULL,
  `password` VARBINARY(256) COLLATE 'binary' NULL,
  `api_token` VARCHAR(255) NOT NULL,
  `auth_type` ENUM('local','ldap') NOT NULL DEFAULT 'local',
  PRIMARY KEY (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `dsip_groups` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `description` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `dsip_user_groups` (
  `username` VARCHAR(255) NOT NULL,
  `group_id` INT NOT NULL,
  PRIMARY KEY (`username`, `group_id`),
  FOREIGN KEY (`username`) REFERENCES `dsip_users`(`username`) ON DELETE CASCADE,
  FOREIGN KEY (`group_id`) REFERENCES `dsip_groups`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Seed default groups
INSERT IGNORE INTO `dsip_groups` (`name`, `description`) VALUES
  ('dsip_admin', 'Full read/write access to all resources'),
  ('dsip_engineer', 'Read on Dashboard/Settings; read/write on CGs/EGs/Domains/Inbound/Outbound'),
  ('dsip_guest', 'Read-only access to Dashboard/CGs/EGs/Domains/Inbound/Outbound');
