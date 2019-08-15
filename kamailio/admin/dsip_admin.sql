DROP TABLE IF EXISTS `admin_users`;
CREATE TABLE `admin_users` (
    `admin_id` int NOT NULL AUTO_INCREMENT,
    `admin_username` varchar(32) NOT NULL,
    `admin_hash` varchar(32) NOT NULL,
    PRIMARY KEY (`admin_id`)
);