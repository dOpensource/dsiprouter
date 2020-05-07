DROP TABLE IF EXISTS `dsip_maintmode`;
CREATE TABLE `dsip_maintmode` (
    `ipaddr` varchar(64) NOT NULL DEFAULT '',
    `key_type` varchar(64) NOT NULL DEFAULT '0',
    `gwid` varchar(64) NOT NULL DEFAULT '',
    `value_type` varchar(64) NOT NULL DEFAULT '0',
    `status` TINYINT NOT NULL DEFAULT '1',
    PRIMARY KEY (`ipaddr`)
);
